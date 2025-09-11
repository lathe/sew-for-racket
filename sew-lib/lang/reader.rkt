#lang parendown racket/base

; sew/lang/reader
;
; A Racket meta-language for assembling a file with custom
; preprocessing logic.

;   Copyright 2021, 2022 2025 The Lathe Authors
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


(require #/for-syntax racket/base)
(require #/for-syntax #/only-in syntax/parse expr this-syntax)

(require #/for-syntax sew/private/autoptic)

(require #/only-in syntax/datum datum)
(require #/only-in syntax/module-reader
  make-meta-reader lang-reader-module-paths)
(require #/only-in syntax/parse
  ~literal ~not ~var attribute define-syntax-class expr id pattern syntax-parse this-syntax)
(require #/only-in syntax/parse/define define-syntax-parse-rule)

(require sew/private)
(require sew/private/autoptic)


(provide #/rename-out
  [-read read]
  [-read-syntax read-syntax]
  [-get-info get-info])


(define-syntax-parse-rule (template is-syntax?:expr t)
  #:when (autoptic-list-to? this-syntax this-syntax)
  (if is-syntax? (syntax t) (datum t)))

(define-syntax-class (directive surrounding-stx)
  (pattern ({~var _ (directive surrounding-stx)} . _)
    #:when (autoptic-to? surrounding-stx this-syntax))
  (pattern d:id #:when
    (let ()
      (define value-d (attribute d))
      (define unwrapped-d
        (if (syntax? value-d) (syntax-e value-d) value-d))
      (and (symbol-interned? unwrapped-d)
        (regexp-match? #px"^8<.*$" (symbol->string unwrapped-d))))))

(define-syntax-class (non-directive surrounding-stx)
  (pattern {~not #/~var _ (directive surrounding-stx)}))

(define (wrap-reader reading-syntax? -read)
  (lambda args
    (define orig (apply -read args))
    (syntax-parse orig
      [
        (module modname modlang #/#%module-begin
          {~var header (non-directive orig)}
          ...)
        orig]
      [
        (module modname modlang #/#%module-begin
          {~var header (non-directive orig)}
          ...
          {~var first (directive orig)}
          rest ...)
        (define (finish)
          (let ([first (template reading-syntax? first)])
          #/syntax-parse first #/
            [_ rest-of-file-pattern:expr preprocess:expr]
            #:when (autoptic-list-to? first first)
            #:with sentinel (datum->syntax #f sew-sentinel)
          #/syntax-parse (template reading-syntax? #/rest ...) #/
            ({~var rest (non-directive orig)} ...)
          #/template reading-syntax?
            (module modname modlang #/#%module-begin
              header ...
              [8<-plan-from-here #:private-interface:sew sentinel
                rest-of-file-pattern
                preprocess
                rest ...])))
        (if reading-syntax?
          (syntax-parse #'first
            #:track-literals
            [[{~literal 8<-plan-from-here} . _] (finish)])
          (syntax-parse (datum first)
            [[{~literal 8<-plan-from-here} . _] (finish)]))])))

(define-values (-read -read-syntax -get-info)
  (make-meta-reader
    'sew
    "language path"
    lang-reader-module-paths
    (lambda (-read) (wrap-reader #f -read))
    (lambda (-read-syntax) (wrap-reader #t -read-syntax))
    (lambda (-get-info) -get-info)))
