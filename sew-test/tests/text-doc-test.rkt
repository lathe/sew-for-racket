#lang racket/base

; sew/tests/text-doc-test
;
; Verifying the source location captured in
; `sew/tests/text-doc-sample` is what we expect.

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


(require (only-in rackunit check-equal?))
(require (only-in sew/tests/text-doc-sample doc))


(check-equal?
  doc
  "Hello #(struct:srcloc \"sew codebase /tests/text-doc-sample.rkt\" 5 11 102 14)"
  "The result of `(quote-srcloc)` is affected by `8<-set-port-next-location!`.")

; TODO: Document Ventriloquy.
