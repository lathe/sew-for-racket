#lang info

(define collection "sew")

(define deps (list "base"))
(define build-deps
  (list
    "lathe-comforts-doc"
    "parendown-lib"
    "racket-doc"
    "scribble-lib"
    "sew-lib"))

(define scribblings (list (list "scribblings/sew.scrbl" (list))))
