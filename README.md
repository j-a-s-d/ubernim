# ubernim
an experimental tool offering extended capabilities for nim

## MOTIVATION
> *"If you want more effective programmers, you will discover that they should not waste their time debugging, they should not introduce the bugs to starth with."*
- Edger Dijkstra, The Humble Programmer, 1972

## CHARACTERISTICS

Ubernim allows:

* compiler directives in the source file and compiler invokation all at once (without the need of calling nim by hand)
* custom build actions in the source file (without the need of nims or nimble solutions)
* some class-based oop-like features emiting pure nim language source code (without the need of macros usage)

and all this via a simple preprocessing approach (built on top of Preprod, Rodster and Xam libraries).

> NOTE: this is a `work in progress`, complete and enhance existing features, add more options in almost everything, test cases, better documentation and more examples are planned towards a 1.0.0 release

## COMMANDS

### SWITCHES feature commands:

* nimc:project
* nimc:config
* nimc:define
* nimc:switch

See them working in the *directives* example.

### SHELLCMD feature commands:

* exec

See them working in the *actions* example.

### FSACCESS feature commands:

* write
* append
* copy
* move
* remove
* mkdir
* cpdir
* rmdir
* chdir

See them working in the *actions* example.

### REQUIRES feature commands:

* require

See them working in the *coding* example.

### LANGUAGE feature commands:

* compound
* interface
* protocol
* class
* record
* pragmas
* applies
* implies
* extends
* fields
* methods
* templates
* docs
* constructor
* method
* template
* routine
* code
* end
* note

See them working in the *coding* example.

## RELATED

You may also want to check my other nimlang projects:

* [`xam`](https://github.com/j-a-s-d/xam), my multipurpose productivity library for nim
* [`rodster`](https://github.com/j-a-s-d/rodster), my application framework for nim
* [`webrod`](https://github.com/j-a-s-d/webrod), my http server for nim
* [`preprod`](https://github.com/j-a-s-d/preprod), my customizable preprocessor for nim

## HISTORY

* 31-12-21 *[0.1.0]*
    - first public release
* 08-12-21 *[0.0.1]*
	- started coding
