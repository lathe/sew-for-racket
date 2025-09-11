#lang parendown racket/base

; sew
;
; Sew's preprocessing directives.

;   Copyright 2021, 2022, 2025 The Lathe Authors
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
  ~and attribute expr id syntax-parse)

(require #/for-syntax sew/private)
(require #/for-syntax sew/private/autoptic)


(provide 8<-plan-from-here)


(define-syntax (8<-plan-from-here stx)
  (syntax-parse stx
    [
      (_ {~and kw #:private-interface:sew} sentinel
        rest-of-file-pattern
        preprocess:expr
        rest ...)
      
      #:when (autoptic-to? stx #'kw)
      #:when (autoptic-list-to? stx stx)
      
      #:when
      (equal-always? sew-sentinel (syntax-e #/attribute sentinel))
      
      #'(begin
          (define-syntax (8<-plan-from-here-helper stx)
            (syntax-parse #'(rest ...) #/ rest-of-file-pattern
              preprocess))
          (8<-plan-from-here-helper))]
    [ _
      (syntax-parse stx #/ (_ rest-of-file-pattern preprocess:expr)
        #:when (autoptic-list-to? stx stx)
      #/raise-syntax-error #f "use of a Sew directive outside of a `#lang sew` module" stx)]))
