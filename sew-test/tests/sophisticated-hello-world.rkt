#lang sew racket

; sew/tests/sophisticated-hello-world
;
; Unit tests.

;   Copyright 2022 The Lathe Authors
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

(require (for-syntax (only-in syntax/parse expr)))

(require (only-in rackunit check-equal?))

(require (only-in sew 8<-plan-from-here))


[8<-plan-from-here [<main>:expr ... #:test <test>:expr ...]
  #'(begin
      (provide (for-syntax main-code))
      (provide main)
      
      (define-for-syntax main-code #'(begin <main> ...))
      (define (main)
        <main> ...)
      
      (module+ test
        <test> ...))]


(displayln "Hello, world!")


#:test

(check-equal? (+ 1 2) 3)
