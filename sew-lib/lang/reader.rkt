#lang parendown racket/base

; sew/lang/reader
;
; A Racket meta-language for assembling a file with custom
; preprocessing logic.

;   Copyright 2021 The Lathe Authors
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


(require #/for-syntax #/only-in syntax/parse expr)

(require #/only-in syntax/datum datum)
(require #/only-in syntax/module-reader
  make-meta-reader lang-reader-module-paths)
(require #/only-in syntax/parse
  ~not attribute define-syntax-class expr id pattern syntax-parse)
(require #/only-in syntax/parse/define define-syntax-parse-rule)

(require #/only-in sew/private sew-sentinel)


(provide #/rename-out
  [-read read]
  [-read-syntax read-syntax]
  [-get-info get-info])


(define-syntax-parse-rule (template is-syntax?:expr t)
  (if is-syntax? (syntax t) (datum t)))

(define-syntax-class directive
  (pattern (_:directive . _))
  (pattern d:id #:when
    (let ()
      (define value-d (attribute d))
      (define unwrapped-d
        (if (syntax? value-d) (syntax-e value-d) value-d))
      (and (symbol-interned? unwrapped-d)
        (regexp-match? #px"^8<.*$" (symbol->string unwrapped-d))))))

(define-syntax-class non-directive
  (pattern {~not _:directive}))

(define (wrap-reader reading-syntax? -read)
  (lambda args
    (define orig (apply -read args))
    (syntax-parse orig
      [
        (module modname modlang #/#%module-begin
          header:non-directive ...)
        orig]
      [
        (module modname modlang #/#%module-begin
          header:non-directive ... first:directive rest ...)
        (syntax-parse (template reading-syntax? first)
          [
            [8<-plan-from-here args ...]
            (syntax-parse (template reading-syntax? #/args ...) #/
              (rest-of-file:id preprocess:expr)
              #:with sentinel (datum->syntax #f sew-sentinel)
            #/syntax-parse (template reading-syntax? #/rest ...) #/
              (rest:non-directive ...)
            #/template reading-syntax?
              (module modname modlang #/#%module-begin
                header ...
                (8<-plan-from-here
                  #:private-interface:sew sentinel
                  rest-of-file
                  preprocess
                  rest ...)))])])))

(define-values (-read -read-syntax -get-info)
  (make-meta-reader
    'sew
    "language path"
    lang-reader-module-paths
    (lambda (-read) (wrap-reader #f -read))
    (lambda (-read-syntax) (wrap-reader #t -read-syntax))
    (lambda (-get-info) -get-info)))
