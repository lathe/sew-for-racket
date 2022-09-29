# Sew

[![CI](https://github.com/lathe/sew-for-racket/actions/workflows/ci.yml/badge.svg)](https://github.com/lathe/sew-for-racket/actions/workflows/ci.yml)

Sew is a Racket language that makes it easy to add boilerplate that surrounds the rest of the file, without changing its indentation.

```racket
#lang sew racket

(require (only-in sew 8<-plan-from-here))

[8<-plan-from-here [<> ...]
  #'(begin
      (provide main)
      
      (define (main)
        <> ...))]

(displayln "Hello, world!")
```

The expression in the body of the `8<-plan-from-here` form is evaluated in phase 1, with `<>` bound as a template variable to the rest of the content of the file.

This can come in handy for maintaining the file as though it belongs to a certain tradition of writing modules, while it actually belongs to another. For instance, the module above can be written as though it's a script, but it's actually a module that provides a `main` function.

Some other potential uses:

* A module whose main attraction is a certain nested submodule.

* A module which provides a quoted copy of its own source code.

* A module which compiles the same code in multiple ways, such as with different contract enforcement levels or different debugging features enabled.

* A module which provides a macro that can be used to compile a new variant of the module that's compiled with a non-default configuration.

For now, `8<-plan-from-here` is the only directive defined by Sew. We might extend this in the future to allow files to be cut up into more than one piece before they're all sewn together. This may resemble literate programming techniques for assembling programs in terms of chunks.


## Installation and use

This is a library for Racket. To install it from the Racket package index, run `raco pkg install sew`. Then you can change the `#lang` line of your Racket modules to `#lang sew <other language>`, where `#lang <other language>` is the line you were using before. Sew is likely to be handy for many languages based on `racket` or `racket/base`.

To install Sew from source, run `raco pkg install --deps search-auto` from the `sew-lib/` directory.

[Documentation for Sew for Racket](http://docs.racket-lang.org/sew/index.html) is available at the Racket documentation website, and it's maintained in the `sew-doc/` directory.
