#lang parendown racket/base

; sew/ventriloquy/lang/reader
;
; A Racket meta-language for assembling a file that reports source
; locations in terms of another file in the codebase, so that people
; can set up build pipelines from a source format that omits `#lang`
; lines.

;   Copyright 2023 The Lathe Authors
;
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;
;       http://www.apache.org/licenses/LICENSE-2.0
;
;   Unless required by applicable law or agreed to in writing,
;   software distributed under the License is distributed on an
;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
;   either express or implied. See the License for the specific
;   language governing permissions and limitations under the License.


(require #/only-in racket/bool false?)
(require #/only-in racket/function conjoin disjoin)
(require #/only-in racket/match match)
(require #/only-in racket/promise delay/thread force)
(require #/only-in syntax/module-reader
  make-meta-reader lang-reader-module-paths)
(require #/only-in syntax/readerr
  raise-read-eof-error raise-read-error)


(provide #/rename-out
  [-read read]
  [-read-syntax read-syntax]
  [-get-info get-info])


(define (wrap-src-and-in who: src in use-replacements)
  (define (error-directive directive-stx message)
    (define augmented-message (string-append who: message))
    (if (eof-object? directive-stx)
      (let ()
        (define-values (line col pos) (port-next-location in))
        (raise-read-eof-error augmented-message src line col pos 0))
      (raise-read-error augmented-message
        (syntax-source directive-stx)
        (syntax-line directive-stx)
        (syntax-column directive-stx)
        (syntax-position directive-stx)
        (syntax-span directive-stx))))
  (define src-replacer-stx (read-syntax src in))
  (define src-replacer (syntax->datum src-replacer-stx))
  (define new-src
    (match src-replacer
      [ `[8<-authentic-source . ,args]
        (match args
          [ (list)
            src]
          [ _
            (error-directive src-replacer-stx
              "expected a 0-element argument list")])]
      [ `[8<-source . ,args]
        (match args
          [ (list new-src)
            new-src]
          [ _
            (error-directive src-replacer-stx
              "expected a 1-element argument list of a source value, usually a path string")])]
      [ `[8<-build-path . ,args]
        (match args
          [ (list (? (conjoin string? relative-path?) relative-path))
            (if (path? src)
              (simplify-path (build-path src relative-path))
              ; NOTE: If we ever find that the original source value
              ; isn't in the form of a path already, we just ignore
              ; its value and use the relative path as the source
              ; value directly.
              relative-path)]
          [ _
            (error-directive src-replacer-stx
              "expected a 1-element argument list of a relative path string")])]
      [ _
        (error-directive src-replacer-stx
          "expected the file to begin with a source replacement directive, usually in the format of (8<-build-path src) where src is a relative path string to another file for this one to pretend to be reading from")]))
  (define-values (new-in pipe)
    (make-pipe
      ; NOTE: We'd set the limit to 0 if we could.
      ; TODO: See if a higher limit is faster or something.
      #;limit
      1
      #;input-name
      (object-name in)
      #;output-name
      'pipe))
  (port-count-lines! new-in)
  (define use-replacements-promise
    (delay/thread (use-replacements new-src new-in)))
  (let loop ()
    (when
      (regexp-match-positions #px"#8<" in
        #;start-pos
        0
        #;end-pos
        #f
        pipe)
      (define command-stx (read-syntax src in))
      (define command (syntax->datum command-stx))
      (match command
        [ `[8<-set-port-next-location! . ,args]
          (match args
            [ (list
                (? (disjoin false? exact-positive-integer?) line)
                (? (disjoin false? exact-nonnegative-integer?) col)
                (? (disjoin false? exact-positive-integer?) pos))
              ; We wait for the pipe backing `new-in` to be empty.
              (let loop ()
                (unless (= 0 (pipe-content-length new-in))
                  (sync (port-progress-evt new-in))
                  (loop)))
              ; TODO: See if there are race conditions here. If
              ; `new-in` is peeked from on the
              ; `use-replacements-promise` thread, is it possible for
              ; the pipe to be empty but `new-in` still to be behind
              ; the position where we want to set the location?
              (set-port-next-location! new-in line col pos)
              (loop)]
            [ _
              (error-directive command-stx
                "expected a 3-element argument list of line, column, and position")])]
        [ `[8<-write-string . ,args]
          (match args
            [ (list (? string? s))
              (write-string s pipe)
              (loop)]
            [ _
              (error-directive command-stx
                "expected a 1-element argument list of a string to write")])]
        [ _
          (error-directive command-stx
            "expected a 8<-set-port-next-location! or 8<-write-string command")])))
  (close-output-port pipe)
  (force use-replacements-promise))

(define-values (-read -read-syntax -get-info)
  (make-meta-reader
    'sew/ventriloquy
    "language path"
    lang-reader-module-paths
    (lambda (-read)
      (lambda
        (
          in reader-module-path reader-form-line reader-form-column
          reader-form-location)
        (wrap-src-and-in "read: " (object-name in) in
          (lambda (src in)
            (-read in reader-module-path reader-form-line
              reader-form-column reader-form-location)))))
    (lambda (-read-syntax)
      (lambda
        (
          src in reader-module-path reader-form-line
          reader-form-column reader-form-location)
        (wrap-src-and-in "read-syntax: " src in
          (lambda (src in)
            (-read-syntax src in reader-module-path reader-form-line
              reader-form-column reader-form-location)))))
    (lambda (-get-info)
      
      ; TODO: Add a color lexer.
      ;
      ; TODO: See if we'll ever want to add a `configure-runtime`
      ; implementation so people can put `#8<` directives in to tweak
      ; the source locations of their REPL input. It seems like a
      ; pretty niche use case.
      ;
      -get-info)))
