#lang parendown racket/base

; parendown/tests
;
; Unit tests.

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


(require #/only-in racket/port with-output-to-string)

(require #/only-in rackunit check-equal?)

(require #/only-in sew/tests/hello-world main)

; (We provide nothing from this module.)


(check-equal?
  (with-output-to-string #/lambda () #/main)
  (with-output-to-string #/lambda () #/displayln "Hello, world!")
  "Using `#lang sew`")
