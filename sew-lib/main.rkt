#lang parendown racket/base

; sew
;
; Sew's preprocessing directives.

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


(require #/for-syntax racket/base)
(require #/for-syntax #/only-in racket/match == match)
(require #/for-syntax #/only-in syntax/parse attribute syntax-parse)

(require #/for-syntax #/only-in sew/private sew-sentinel)


(provide 8<-plan-from-here)


(define-syntax (8<-plan-from-here stx)
  (define (error-used-outside-lang)
    (raise-syntax-error #f "use of a Sew directive outside of a `#lang sew` module" stx))
  (syntax-parse stx
    [
      (_ sentinel . rest)
      (match (syntax-e (attribute sentinel))
        [
          (== sew-sentinel)
          (syntax-parse #'rest #/ (rest-of-file preprocess rest ...)
            #'(begin
                (define-syntax (8<-plan-from-here-helper stx)
                  (with-syntax
                    ([(rest-of-file (... ...)) #'(rest ...)])
                    preprocess))
                (8<-plan-from-here-helper)))]
        [_ (error-used-outside-lang)])]
    [_ (error-used-outside-lang)]))
