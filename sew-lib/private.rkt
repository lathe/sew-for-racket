#lang parendown racket/base

; sew/private
;
; A representation for Sew's reader to communicate with its
; preprocessing directive syntaxes.

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


(provide sew-sentinel)


; TODO: See if there's a more tamper-proof way of defining this
; sentinel. If we use a struct, the struct constructed at read time
; doesn't belong to the structure type defined when the directives are
; processing this sentinel in phase 1.
(define sew-sentinel
  (string->unreadable-symbol "private-interface:sew"))
