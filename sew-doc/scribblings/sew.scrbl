#lang parendown scribble/manual

@; sew/scribblings/sew.scrbl
@;
@; A Racket meta-language for assembling a file with custom
@; preprocessing logic.

@;   Copyright 2021-2023 The Lathe Authors
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


@(require #/only-in racket/match match-define)


@(require #/for-label #/only-in racket/base
  ... begin build-path complete-path? define displayln
  exact-nonnegative-integer? exact-positive-integer? only-in
  path-for-some-system? path-string? provide read-syntax require
  set-port-next-location! simplify-path write-string)

@(require #/for-label #/only-in sew 8<-plan-from-here)


@(struct printable (rep)
   #:methods gen:custom-write
   [
     (define (write-proc self port mode)
       (match-define (printable rep) self)
       (write-string rep port))
     
     ])

@(define (make-id sym)
   (datum->syntax #f (printable (symbol->string sym))))

@(define-syntax-rule @lang[x]
   @racketmetafont{@hash-lang[] @x})

@(define-syntax-rule @lang-mod[x]
   @lang[@racketmodname[x]])

@(define-syntax-rule @lang-racket-base[]
   @lang-mod[racket/base])

@(define @mod-sew[]
   @racketmodlink[sew/lang/reader]{sew})

@(define @mod-sew-built[]
   @racketmodlink[sew/built/lang/reader]{sew/built})

@(define @lang-sew[]
   @lang[@mod-sew[]])

@(define @lang-sew-built[]
   @lang[@mod-sew-built[]])

@(define-syntax-rule (directiveref directive-name)
   @elemref[
    '(sew-built-directive directive-name)
   ]{@racketfont{@(symbol->string 'directive-name)}})


@title{Sew}

Sew is a library for declaring the language of a Racket file in a more expressive way than just a one-line @hash-lang[] declaration. This longer "declaration" can essentially frontload the boilerplate of the file, leaving the rest of the file to be expressed in a way that's more straightforward for its application domain.

Sew comes with two Racket languages, @lang-sew[] for use in most @lang-mod[racket]-like languages to express boilerplate that gets added on the syntax object level, and @lang-sew-built[] for use in files which have been generated by a text-manipulating build step, to help these generated files associate themselves with the source locations the maintainer actually wants to see in error reports. Using both these techniques at once can make it possible to express certain boilerplate entirely in the build step, factoring it out pervasively from the source representation of the repo, while the code distributed in the Racket package registry still resembles the code maintainers see aside from having some file headers.



@table-of-contents[]



@section[#:tag "sew-lang"]{The Sew Language}

@defmodulelang[@mod-sew[] #:module-path sew/lang/reader]

The @lang-sew[] language makes it easy to add boilerplate that surrounds the rest of the syntax objects in the file, without changing its indentation.

@racketblock[
  @#,racketmetafont{@hash-lang[] @mod-sew[] @racketmodname[racket/base]}
  
  (require (only-in @#,racketmodname[sew] 8<-plan-from-here))
  
  [8<-plan-from-here [_<> ...]
    #'(begin
        (provide _main)

        (define (_main)
          _<> ...))]
  
  (displayln "Hello, world!")
]

The expression in the body of the @racket[8<-plan-from-here] form is evaluated in phase 1, with @racket[_<>] bound as a template variable to the rest of the content of the file.

This can come in handy for maintaining the file as though it belongs to a certain tradition of writing modules, while it actually belongs to another. For instance, the module above can be written as though it's a script that's executed one line after another, when it's actually a module that only executes that behavior when a @racket[provide]d @racket[_main] function is called.

Some other potential uses:

@itemlist[
  @item{A module whose main attraction is a certain nested submodule.}
  
  @item{A module which provides a quoted copy of its own source code.}
  
  @item{A module which compiles the same code in multiple ways, such as with different contract enforcement levels or different debugging features enabled.}
  
  @item{A module which is usually used with a certain compile-time configuration, but which also provides a macro that can be used to define a variant of the module that uses a different compile-time configuration of the caller's choice.}
]

For now, @racket[8<-plan-from-here] is the only directive defined for use in @lang-sew[]. We might extend Sew in the future to allow files to be cut up into more than one piece before they're all sewn together. This may resemble literate programming techniques for assembling programs in terms of chunks.


@subsection[#:tag "sew-directives"]{Sew Directives}

@defmodule[sew]

@defform[[8<-plan-from-here rest-of-file-pattern preprocess-expr]]{
  This must be used at the top level of a module that uses @lang-sew[]. It parses the rest of the forms in the module according to the @racketmodname[syntax/parse] pattern @racket[rest-of-file-pattern] and executes @racket[preprocess-expr] in the syntax phase. The result of that expression is then used as the replacement (expansion) of this form and all the rest of the forms in the file.
  
  For instance, the usage site
  
  @racketblock[
    [8<-plan-from-here [_<> ...]
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



@section[#:tag "sew-built-lang"]{The Sew Built Language}

@defmodulelang[@mod-sew-built[] #:module-path sew/built/lang/reader]

The @lang-sew-built[] language provides a way to associate the surface text of a module with a different source location than it usually would be associated with. This can help attribute error information to appropriate places when Racket module files are generated by a build process or a Racket-targeting compiler/transpiler.

As a simple example, suppose we want to write code like this:

@racketblock[
  (my-fancy-displayln "Hello, world!")
]

And suppose we actually want it to behave as though it were written like this:

@racketblock[
  @#,racketmetafont{@hash-lang[] @racketmodname[racket/base]}
  
  (require "my-util.rkt")
  
  (my-fancy-displayln "Hello, world!")
]

A build script could simply insert the @hash-lang[] and @racket[require] lines as it copies our source file to a distributable directory, but that may not be satisfactory. With such a simplistic build step, if the @tt{my-fancy-displayln} call has an error, that error will be reported in terms of line 5 of the generated file, rather than line 1 of the file we actually need to modify.

Instead, we can generate code that uses @lang-sew-built[]:

@racketblock[
  @#,racketmetafont{@hash-lang[] @mod-sew-built[] @racketmodname[racket/base]}
  
  (require "my-util.rkt")
  
  [@#,directiveref[|#8<-source|] "my-project codebase /src/my-fancy-hello-world.rkt"]
  [@#,directiveref[|#8<-set-port-next-location!|] 1 0 1]
  [@#,directiveref[|#8<-disregard-further-commands|]]
  (my-fancy-displayln "Hello, world!")
]

This way, the source location reported for errors having to do with the @tt{my-fancy-displayln} call will be reported as line 1, column 0, byte position 1 of the source "@tt{my-project codebase /src/my-fancy-hello-world.rkt}".

Since @lang-sew[] can frontload other kinds of boilerplate in Racket programs, there can be a nice synergy between @lang-sew[] and @lang-sew-built[]:

@racketblock[
  @#,racketmetafont{@hash-lang[] @mod-sew-built[] @mod-sew[] @racketmodname[racket/base]}
  [@#,directiveref[|#8<-source|] "my-project codebase /src/my-hello-world.rkt"]
  
  (require (only-in @#,racketmodname[sew] 8<-plan-from-here))
  
  [8<-plan-from-here [_<> ...]
    #'(begin
        (provide _main)
        
        (define (_main)
          _<> ...))]
  
  [@#,directiveref[|#8<-set-port-next-location!|] 1 0 1]
  [@#,directiveref[|#8<-disregard-further-commands|]]
  (displayln "Hello, world!")
]

For now, Sew Built defines a small number of source directives and mid-stream commands, and there's currently no way to extend this.

In detail, a Sew Built module is read using the following process:

First, a form is read using the default Racket reader extended so that @tt{#8<} can begin a symbol. This form is used as a directive to indicate the source of the module, and it must be a correct use of @directiveref[|#8<-authentic-source|], @directiveref[|#8<-authentic-source|], or @directiveref[|#8<-build-path-source|].

Then, the rest of the module is read using the original @hash-lang[]'s reader but using a modified input port. This input port forwards along any text it finds until a space, tab, carriage return, newline, form feed, @tt{(}, @tt{[}, or @tt|{{}|. When it finds one of those, it waits until it can determine whether or not the input is in the form @tt{(#8<}, @tt{[#8<}, or @tt|{{#8<}| with any number of preceding spaces, tabs, newlines, carriage returns, or form feed characters. If the input is not in such a form, it's passed along as usual. If it is in that form, the input port reads a syntax object using the default Racket reader extended so that @tt{#8<} can begin a symbol. Then, it consumes and discards any number of spaces or tabs it finds, and if there is a carriage return, a newline, or a carriage return newline (CRLF) sequence, it consumes that as well. Then the syntax object it read this way is interpreted as a Sew Built mid-stream command, and it must be a correct use of @directiveref[|#8<-set-port-next-location!|], @directiveref[|#8<-write-string|], or @directiveref[|#8<-disregard-further-commands|].

Note that since Sew Built mid-stream commands are recognized by the sequence of an opening bracket directly followed by @tt{#8<}, comments and whitespace cannot appear in between the bracket and the @tt{#8<}. This makes the syntax of mid-stream commands slightly different from the syntax of source directives. Both of these differ from Sew directives like @racket[[8<-plan-from-here _...]]. The resemblance between these three syntaxes is mainly for the sake of superficial visual cohesion of the Sew library as a whole, with the presence or absence of @tt{#} conveying that something out of the ordinary is going on at read time.

Note also that since we're discarding so much whitespace, a non-whitespace token may appear split into two non-whitespace tokens in the source even if it is still ultimately treated as a single token.

@; TODO: The directives don't appear in the outline in the sidebar. See if there's something we can do about that.


@subsection[#:tag "sew-built-source-directives"]{Sew Built Source Directives}

@declare-exporting[#:use-sources (sew/built)]

@(define @source-directive-reminder[]
   @list{Like other Sew Built source directives, this may only be used at the very beginning of a module that uses @lang-sew-built[].})

@elemtag['(sew-built-directive |#8<-authentic-source|)]{}
@defform[
  #:kind "Sew Built source directive"
  #:link-target? #f
  #:id [name (make-id '|#8<-authentic-source|)]
  [name]
]{
  Specifies that the source of this module is the one it would usually be if this were any other language but Sew Built. (This would be a nice default, but the source directive of a Sew Built module is not optional.)
  
  @source-directive-reminder[]
}

@elemtag['(sew-built-directive |#8<-source|)]{}
@defform[
  #:kind "Sew Built source directive"
  #:link-target? #f
  #:id [name (make-id '|#8<-source|)]
  [name source-string]
]{
  Specifies that the source of this module is the given @racket[source-string].
  
  The @racket[source-string] form must be a literal string. This condition may be loosened in the future to allow for other kinds of sources, since any object passed to @racket[read-syntax] can be a source. Usually, the source for a Racket module is a path object; however, the main use for it is to render it to a string in an error report. For modules that are compiled from sources not actually in the distribution users are running, a short description like "@tt{<library name> codebase <path within library>}" may be ideal.
  
  @source-directive-reminder[]
}

@elemtag['(sew-built-directive |#8<-build-path-source|)]{}
@defform[
  #:kind "Sew Built source directive"
  #:link-target? #f
  #:id [name (make-id '|#8<-build-path-source|)]
  [name subpath-string]
]{
  Specifies that the source of this module is a path, namely the path constructible with @racket[build-path] and @racket[simplify-path] using the given @racket[subpath-string] interpreted relative to the path this module would usually have as its source.
  
  If the usual source the module would have is neither a @racket[path-string?] nor a @racket[path-for-some-system?], then the @racket[subpath-string] is just used as the source directly rather than resolving it.
  
  The @racket[subpath-string] form must be a literal string, and it must satisfy @racket[path-string?] and yet not be a @racket[complete-path?].
  
  @source-directive-reminder[]
}


@subsection[#:tag "sew-built-mid-stream-commands"]{Sew Built Mid-Stream Commands}

@declare-exporting[#:use-sources (sew/built)]

@(define @mid-stream-command-reminder[]
   @list{Like other Sew Built mid-stream commands, this may be used anywhere after the source directive of a module that uses @lang-sew-built[]. As with other Sew Built mid-stream commands, certain whitespace characters before the command are consumed and discarded, and certain whitespace after the command, up to and including the first encountered newline (if any), is consumed and discarded as well.})

@elemtag['(sew-built-directive |#8<-set-port-next-location!|)]{}
@defform[
  #:kind "Sew Built mid-stream command"
  #:link-target? #f
  #:id [name (make-id '|#8<-set-port-next-location!|)]
  [name line column position]
]{
  Sets the next source location in the input stream as though using @racket[set-port-next-location!].
  
  The @racket[line] form must be a literal @racket[exact-positive-integer?]. It represents the line number, with 1 representing a position within the first line of the file.
  
  The @racket[column] form must be a literal @racket[exact-nonnegative-integer?]. It represents the column number, with 0 representing the position before the first character in the current line.
  
  The @racket[position] form must be a literal @racket[exact-positive-integer?]. It represents the byte position in the file, with 1 representing the position before the first byte of the file.
  
  @mid-stream-command-reminder[]
}

@elemtag['(sew-built-directive |#8<-write-string|)]{}
@defform[
  #:kind "Sew Built mid-stream command"
  #:link-target? #f
  #:id [name (make-id '|#8<-write-string|)]
  [name input-string]
]{
  Sets up the input stream to read @racket[input-string] next, as though using @racket[write-string] on an output port that feeds into the language reader's input port. The @racket[input-string] form must be a literal string.
  
  This can be used to escape instances of syntax that looks like the beginning of a Sew Built mid-stream command. In particular, it can be useful to use @racket[[@#,tt{#8<-write-string} "#"]] to escape instances of @tt{#} within @tt{#8<}, and it can also be used to escape whitespace sequences around other commands, since those would otherwise be discarded.
  
  @mid-stream-command-reminder[]
}

@elemtag['(sew-built-directive |#8<-disregard-further-commands|)]{}
@defform[
  #:kind "Sew Built mid-stream command"
  #:link-target? #f
  #:id [name (make-id '|#8<-disregard-further-commands|)]
  [name]
]{
  Causes the rest of the input stream to be processed without detecting or executing any further Sew Built mid-stream commands.
  
  This is good for creating build processes that maintain the illusion that Sew Built was never used. Without it, maintainers who accidentally write something that looks like a Sew Build mid-stream command might find their build output failing or misbehaving.
  
  @mid-stream-command-reminder[]
}
