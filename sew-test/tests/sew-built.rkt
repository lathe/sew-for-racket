#lang sew/built racket
;[#-8<-authentic-source]
;[#-8<-source "sew codebase /tests/sew-built.rkt"]
[#8<-build-path "../../../src/tests/sew-built.txt"]

; sew/tests/built
;
; A demo of the `#lang sew/built` language, which shows how to use
; this language to produce errors with replaced source locations.

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


(require (only-in syntax/location quote-srcloc))

(require (only-in rackunit check-equal?))


; TODO: This file is written more like a demo sandbox than a set of
; unit tests. Figure out how to set up unit tests for checking that
; compile-time and run-time errors have appropriate source location
; attribution.


#;
(define-syntax (cause-trouble stx)
  [#8<-set-port-next-location! 122 0 23](raise-syntax-error 'cause-trouble "hello" stx))

; NOTE: To see the line number reporting for this one, use DrRacket or use
; `racket -l errortrace -t sew-test/tests/sew-built.rkt`.
#;
(define (cause-trouble)
  [#8<-set-port-next-location! 122 0 23](error "hello"))

;#;
(define (cause-trouble)
  [#8<-set-port-next-location! 122 0 23](quote-srcloc))

(define (invite-trouble)
  (list "no trouble here" (cause-trouble)))

#;
(invite-trouble)

;#;
(check-equal?
  (match (invite-trouble)
    [
      (list _
        (srcloc
          (regexp #px"src/tests/sew-built\\.txt" src)
          line col pos span))
      (list src line col pos)])
  (list (list "src/tests/sew-built.txt") 122 0 23)
  "The `#8<-build-path` directive sets the source, and the `#8<-set-port-next-location!` command sets the line, column, and position.")
