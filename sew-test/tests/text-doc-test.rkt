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
  "Hello #(struct:srcloc \"sew codebase /tests/text-doc-sample.rkt\" 6 11 103 14)"
  "The result of `(quote-srcloc)` is affected by `8<-set-port-next-location!`.")

; TODO: Currently, it doesn't work quite the way we'd like. If we put
; a newline and any number of spaces before our use of
; `8<-set-port-next-location!`, somehow the line number we observe is
; 1 more than what we tried to set it to. This seems to mean means
; something in Racket's reader is waiting to increment the line count
; until well after it has peeked that newline, and we're setting the
; location while we're in between those two moments.
;
; Maybe the solution to this will involve monitoring peeking somehow,
; or maybe it will involve getting the location update to be processed
; while the reader is in the middle of stuff. It seems likely we'll be
; able to get this to work if we make more extensive use of
; `make-input-port` or `make-input-port/read-to-peek`.
;
; TODO: Once we get that sorted out, document Ventriloquy.
