#lang parendown scribble/manual

@; sew/scribblings/sew.scrbl
@;
@; A Racket meta-language for assembling a file with custom
@; preprocessing logic.

@;   Copyright 2021 The Lathe Authors
@;
@;   Licensed under the Apache License, Version 2.0 (the "License");
@;   you may not use this file except in compliance with the License.
@;   You may obtain a copy of the License at
@;
@;       http://www.apache.org/licenses/LICENSE-2.0
@;
@;   Unless required by applicable law or agreed to in writing,
@;   software distributed under the License is distributed on an
@;   "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
@;   either express or implied. See the License for the specific
@;   language governing permissions and limitations under the License.


@(require #/for-label #/only-in racket/base
  ... begin define displayln only-in provide require)

@(require #/for-label #/only-in sew 8<-plan-from-here)


@title{Sew}

@defmodulelang[sew]

Sew is a Racket language that makes it easy to add boilerplate that surrounds the rest of the file, without changing its indentation.

@racketblock[
  @#,racketmetafont{@hash-lang[] @racketmodname[sew] @racketmodname[racket/base]}
  
  (require (only-in @racketmodname[sew] 8<-plan-from-here))

  [8<-plan-from-here _<>
    #'(begin
        (provide _main)

        (define (_main)
          _<> ...))]

  (displayln "Hello, world!")
]

The expression directly after the @racket[[8<-plan-from-here _<>]] line is evaluated in phase 1, with @racket[_<>] bound as a template variable to the rest of the content of the file.

This can come in handy for maintaining the file as though it belongs to a certain tradition of writing modules, while it actually belongs to another. For instance, the module above can be written as though it's a script, but it's actually a module that provides a @racket[_main] function.

In the Lathe project, we intend to use Sew to write a module once but compile it with multiple levels of contract enforcement.

For now, @racket[8<-plan-from-here] is the only directive defined by Sew. We might extend this in the future to allow files to be cut up into more than one piece before they're all sewn together. This may resemble literate programming techniques for assembling programs in terms of chunks.



@table-of-contents[]



@section[#:tag "directives"]{Sew Directives}

@defform[[8<-plan-from-here rest-of-file-id preprocess-expr]]{
  This must be used at the top level of a module using @racket[@#,hash-lang[] @#,racketmodname[sew]]. It binds the rest of the forms in the module to the pattern variable @racket[#'(rest-of-file-id ...)] as it runs @racket[preprocess-expr] in the syntax phase. The result of that expression is then used as the replacement (expansion) of this form and all the rest of the forms in the file.
  
  For instance, the usage site
  
  @racketblock[
    [8<-plan-from-here _<>
      #'(begin
          (provide _main)
          
          (define (_main)
            _<> ...))]
    
    (displayln "Hello, world!")
  ]
  
  expands into this:
  
  @racketblock[
    (begin
      (provide _main)
      
      (define (_main)
        (displayln "Hello, world!")))
  ]
}
