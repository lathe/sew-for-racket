# Sew

[![CI](https://github.com/lathe/sew-for-racket/actions/workflows/ci.yml/badge.svg)](https://github.com/lathe/sew-for-racket/actions/workflows/ci.yml)

Sew is a library for declaring the language of a Racket file in a more expressive way than just a one-line `#lang` declaration. This longer "declaration" can essentially frontload the boilerplate of the file, leaving the rest of the file to be expressed in a way that's more straightforward for its application domain.

Sew comes with two Racket languages, `#lang sew` for use in most `#lang racket`-like languages to express boilerplate that gets added on the syntax object level, and `#lang sew/built` for use in files which have been generated by a text-manipulating build step, to help these generated files associate themselves with the source locations the maintainer actually wants to see in error reports. Using both these techniques at once can make it possible to express certain boilerplate entirely in the build step, factoring it out pervasively from the source representation of the repo, while the code distributed in the Racket package registry still resembles the code maintainers see aside from having some file headers.


## The Sew language

The `#lang sew` language makes it easy to add boilerplate that surrounds the rest of the syntax objects in the file, without changing its indentation.

```racket
#lang sew racket/base

(require (only-in sew 8<-plan-from-here))

[8<-plan-from-here [<> ...]
  #'(begin
      (provide main)
      
      (define (main)
        <> ...))]

(displayln "Hello, world!")
```

The expression in the body of the `8<-plan-from-here` form is evaluated in phase 1, with `<>` bound as a template variable to the rest of the content of the file.

This can come in handy for maintaining the file as though it belongs to a certain tradition of writing modules, while it actually belongs to another. For instance, the module above can be written as though it's a script that's executed one line after another, when it's actually a module that only executes that behavior when a `provide`d `main` function is called.

Some other potential uses:

* A module whose main attraction is a certain nested submodule.

* A module which provides a quoted copy of its own source code.

* A module which compiles the same code in multiple ways, such as with different contract enforcement levels or different debugging features enabled.

* A module which is usually used with a certain compile-time configuration, but which also provides a macro that can be used to define a variant of the module that uses a different compile-time configuration of the caller's choice.

For now, `8<-plan-from-here` is the only directive defined for use in `#lang sew`. We might extend Sew in the future to allow files to be cut up into more than one piece before they're all sewn together. This may resemble literate programming techniques for assembling programs in terms of chunks.


## The Sew Built language

The `#lang sew/built` language provides a way to associate the surface text of a module with a different source location than it usually would be associated with. This can help attribute error information to appropriate places when Racket module files are generated by a build process or a Racket-targeting compiler/transpiler.

As a simple example, suppose we want to write code like this:

```racket
(my-fancy-displayln "Hello, world!")
```

And suppose we actually want it to behave as though it were written like this:

```racket
#lang racket/base

(require "my-util.rkt")

(my-fancy-displayln "Hello, world!")
```

A build script could simply insert the `#lang` and `require` lines as it copies our source file to a distributable directory, but that may not be satisfactory. With such a simplistic build step, if the `my-fancy-displayln` call has an error, that error will be reported in terms of line 5 of the generated file, rather than line 1 of the file we actually need to modify.

Instead, we can generate code that uses `#lang sew/built`:

```racket
#lang sew/built racket/base

(require "my-util.rkt")

[#8<-source "my-project codebase /src/my-fancy-hello-world.rkt"]
[#8<-set-port-next-location! 1 0 1]
[#8<-disregard-further-commands]
(my-fancy-displayln "Hello, world!")
```

This way, the source location reported for errors having to do with the `my-fancy-displayln` call will be reported as line 1, column 0, byte position 1 of the source "`my-project codebase /src/my-fancy-hello-world.rkt`".

Since `#lang sew` can frontload other kinds of boilerplate in Racket programs, there can be a nice synergy between `#lang sew` and `#lang sew/built`:

```racket
#lang sew/built sew racket/base
[#8<-source "my-project codebase /src/my-hello-world.rkt"]

(require (only-in sew 8<-plan-from-here))

[8<-plan-from-here [<> ...]
  #'(begin
      (provide main)
      
      (define (main)
        <> ...))]

[#8<-set-port-next-location! 1 0 1]
[#8<-disregard-further-commands]
(displayln "Hello, world!")
```

For now, Sew Built defines a small number of source directives and mid-stream commands, and there's currently no way to extend this.

In detail, a Sew Built module is read using the following process:

First, a form is read using the default Racket reader extended so that `#8<` can begin a symbol. This form is used as a directive to indicate the source of the module, and it must be a correct use of `#8<-authentic-source`, `#8<-authentic-source`, or `#8<-build-path-source`.

Then, the rest of the module is read using the original `#lang`'s reader but using a modified input port. This input port forwards along any text it finds until a space, tab, carriage return, newline, form feed, `(`, `[`, or `{`. When it finds one of those, it waits until it can determine whether or not the input is in the form `(#8<`, `[#8<`, or `{#8<` with any number of preceding spaces, tabs, newlines, carriage returns, or form feed characters. If the input is not in such a form, it's passed along as usual. If it is in that form, the input port reads a syntax object using the default Racket reader extended so that `#8<` can begin a symbol. Then, it consumes and discards any number of spaces or tabs it finds, and if there is a carriage return, a newline, or a carriage return newline (CRLF) sequence, it consumes that as well. Then the syntax object it read this way is interpreted as a Sew Built mid-stream command, and it must be a correct use of `#8<-set-port-next-location!`, `#8<-write-string`, or `#8<-disregard-further-commands`.

Note that since Sew Built mid-stream commands are recognized by the sequence of an opening bracket directly followed by `#8<`, comments and whitespace cannot appear in between the bracket and the `#8<`. This makes the syntax of mid-stream commands slightly different from the syntax of source directives. Both of these differ from Sew directives like `[8<-plan-from-here ...]`. The resemblance between these three syntaxes is mainly for the sake of superficial visual cohesion of the Sew library as a whole, with the presence or absence of `#` conveying that something out of the ordinary is going on at read time.

Note also that since we're discarding so much whitespace, a non-whitespace token may appear split into two non-whitespace tokens in the source even if it is still ultimately treated as a single token.


## Installation and use

This is a library for Racket. To install it from the Racket package index, run `raco pkg install sew`. Then you can change the `#lang` line of your Racket modules to `#lang sew <other language>` or `#lang sew/built <other language>`, where `#lang <other language>` is the line you were using before. The `#lang sew` language is likely to be handy for many `#lang`s based on `racket` or `racket/base`, and `#lang sew/built` is likely to be handy for just about any `#lang`.

To install Sew from source, run `raco pkg install --deps search-auto` from the `sew-lib/` directory.

[Documentation for Sew for Racket](https://docs.racket-lang.org/sew/index.html) is available at the Racket documentation website, and it's maintained in the `sew-doc/` directory.
