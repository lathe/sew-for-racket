#lang racket/base

; sew/tests/text-doc-sample
;
; An example of using `#reader sew/ventriloquy/lang/reader` to make a
; module that can mostly be comprised of DSL code. In this case, the
; DSL we're using is `#lang scribble/text`, and we use `#reader` so we
; can specify a different way to expose that text, through an export
; named `doc`, somewhat like what `#lang scribble/manual` does. Where
; Ventriloquy shines here is that it lets this whole
; `#lang racket/base` boilerplate prelude have no impact on the line
; numbers associated with the rest of the file, which could be handy
; if this boilerplate were inserted by a build process.

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


(require (for-syntax racket/base))

(require (only-in racket/port with-output-to-string))
(require (only-in racket/runtime-path define-runtime-path))
(require (only-in racket/string string-trim))

(provide doc)


(define doc
  (string-trim
    (with-output-to-string
      (lambda ()
        (dynamic-require
          '(submod sew/tests/text-doc-sample text-doc-sample)
          #f)))))


#reader sew/ventriloquy/lang/reader scribble/text
[8<-source "sew codebase /tests/text-doc-sample.rkt"]#8<[8<-set-port-next-location! 1 0 1]

@(require (only-in racket/format ~s))
@(require (only-in syntax/location quote-srcloc))

Hello @~s{@(quote-srcloc)}
