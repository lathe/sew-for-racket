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
(require #/only-in racket/port
  copy-port eof-evt make-input-port/read-to-peek)
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
  (define in-name (object-name in))
  (define-values (piped-in main-pipe)
    (make-pipe
      #;limit
      #f
      #;input-name
      in-name
      #;output-name
      'main-pipe))
  (port-count-lines! piped-in)
  (define-values (start-line start-col start-pos)
    (port-next-location in))
  (set-port-next-location! piped-in start-line start-col start-pos)
  (thread
    (lambda ()
      (copy-port in main-pipe)
      (close-output-port main-pipe)))
  (define-values (written-in written-pipe)
    (make-pipe
      #;limit
      #f
      #;input-name
      in-name
      #;output-name
      'written-pipe))
  (define (process-command command-stx)
    (match (syntax->datum command-stx)
      [ `[8<-set-port-next-location! . ,args]
        (match args
          [ (list
              (? (disjoin false? exact-positive-integer?) line)
              (? (disjoin false? exact-nonnegative-integer?) col)
              (? (disjoin false? exact-positive-integer?) pos))
            (set-port-next-location! new-in line col pos)]
          [ _
            (error-directive command-stx
              "expected a 3-element argument list of line, column, and position")])]
      [ `[8<-write-string . ,args]
        (match args
          [(list (? string? s)) (write-string s written-pipe)]
          [ _
            (error-directive command-stx
              "expected a 1-element argument list of a string to write")])]
      [ _
        (error-directive command-stx
          "expected a 8<-set-port-next-location! or 8<-write-string command")]))
  (define new-in
    (make-input-port/read-to-peek in-name
      #;read-in
      (lambda (bstr)
        (define (zero)
          (wrap-evt (choice-evt (port-progress-evt in) (eof-evt in))
            (lambda (progress-evt)
              0)))
        (define read-written-result
          (read-bytes-avail!* bstr written-in))
        (if (not (zero? read-written-result))
          read-written-result
          
          ; TODO: We search for occurrences of `#8<` here, and when we
          ; do, we seem to have to process the whitespace before them
          ; ourselves, or else newlines occurring before them get
          ; added to the line numbers we set. This may be because
          ; we're partway through a single peeked(?) whitespace token
          ; when we set the location, and it may be that something
          ; about the internals of Racket's regexp processing or of
          ; `make-input-port/read-to-peek` is not in an
          ; invariant-preserving state at that time. We should test
          ; putting the directive at different places in a file and in
          ; the middle of non-whitespace tokens.
          ;
          ; NOTE: We use Racket's "\s" regexp notation here, which
          ; matches space, tab, carriage return, newline, and form
          ; feed.
          ;
          (match
            (regexp-match-peek-positions-immediate
              #px"\\s|#" piped-in 0 (bytes-length bstr))
            [ (list (cons 0 _))
              (match
                (regexp-match-peek-positions-immediate
                  #px"^(?:\\s*#8<()|(?!\\s*#8<))" piped-in)
                [#f (zero)]
                [(list _ #f) (read-bytes! bstr piped-in 0 1)]
                [ (list _ (cons _ n))
                  (port-commit-peeked
                    n
                    (port-progress-evt piped-in)
                    always-evt
                    piped-in)
                  (wrap-evt always-evt
                    (lambda (always-evt)
                      (define command (read-syntax src piped-in))
                      
                      ; We consume and discard any spaces or tabs
                      ; following the command, as well as an optional
                      ; newline. This way, if we preprocess a file to
                      ; add a boilerplate `#lang` header, we can let
                      ; the first line of the file begin at column
                      ; zero for easier reading. The line diffs will
                      ; be immaculate.
                      ;
                      ; TODO: Decide whether a form feed counts as a
                      ; newline. Decide what to do with Unicode.
                      ;
                      (match
                        (regexp-match-positions
                          #px"^[\x20\t]*(?:\r\n?|\n|(?=\f)()|)" piped-in)
                        [ (list _ (cons _ _))
                          (define-values (line col pos)
                            (port-next-location piped-in))
                          (raise-read-error "expected an optional newline, but behavior with respect to a form feed is currently undecided"
                            src line col pos 0)]
                        [_ (void)])
                      (sync always-evt)
                      (process-command command)
                      0))])]
            [(list (cons n _)) (read-bytes! bstr piped-in 0 n)]
            [ #f
              (match (read-bytes-avail!* bstr piped-in)
                [0 (zero)]
                [result result])])))
      #;fast-peek
      #f
      #;close
      (lambda ()
        (close-input-port in)
        (close-output-port written-pipe)
        (close-input-port written-in)
        (close-output-port main-pipe)
        (close-input-port piped-in))))
  (port-count-lines! new-in)
  ; TODO: For some reason, running this on a different thread is
  ; necessary for the `new-src` to be picked up by instances of
  ; `(quote-srcloc)` in the code. Figure out why.
  (force (delay/thread (use-replacements new-src new-in))))

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
