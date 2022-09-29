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
(require #/for-syntax #/only-in syntax/parse
  attribute expr id syntax-parse)

(require #/for-syntax #/only-in sew/private sew-sentinel)


(provide 8<-plan-from-here)


(define-syntax (8<-plan-from-here stx)
  (syntax-parse stx
    [
      (_ #:private-interface:sew sentinel rest-of-file-pattern
        preprocess
        rest ...)
      #:when (equal? sew-sentinel (syntax-e #/attribute sentinel))
      #'(begin
          (define-syntax (8<-plan-from-here-helper stx)
            (syntax-parse #'(rest ...) #/ rest-of-file-pattern
              preprocess))
          (8<-plan-from-here-helper))]
    [_
      (syntax-parse stx #/ (_ rest-of-file:id preprocess:expr)
      #/raise-syntax-error #f "use of a Sew directive outside of a `#lang sew` module" stx)]))
