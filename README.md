# ubernim
an experimental tool offering extended capabilities for nim

## MOTIVATION
> *"If you want more effective programmers, you will discover that they should not waste their time debugging, they should not introduce the bugs to starth with."*
- Edger Dijkstra, The Humble Programmer, 1972

## CHARACTERISTICS

Ubernim allows:

* compiler directives in the source file and compiler invokation all at once (without the need of calling nim by hand)
* custom build actions in the source file (without the need of nims or nimble solutions)
* some class-based oop superset features emiting pure nim language source code (without the need of macros usage)

and all this via a simple preprocessing approach (built on top of Preprod, Rodster and Xam libraries).

> NOTE: this is a `work in progress`, complete and enhance existing features, add more options in almost everything, test cases, better documentation and more examples are planned towards a 1.0.0 release

## COMMANDS

### UNIMCMDS feature commands:

* **.unim:version** *(since 0.2.0)*
* **.unim:flush** *(since 0.2.1)*

See them working in the *directives* example.

### SWITCHES feature commands:

* **.nimc:project** *(since 0.1.0)*
* **.nimc:config** *(since 0.1.0)*
* **.nimc:define** *(since 0.1.0)*
* **.nimc:switch** *(since 0.1.0)*

See them working in the *directives* example.

### SHELLCMD feature commands:

* **.exec** *(since 0.1.0)*

See them working in the *actions* example.

### FSACCESS feature commands:

* **.write** *(since 0.1.0)*
* **.append** *(since 0.1.0)*
* **.copy** *(since 0.1.0)*
* **.move** *(since 0.1.0)*
* **.remove** *(since 0.1.0)*
* **.mkdir** *(since 0.1.0)*
* **.cpdir** *(since 0.1.0)*
* **.rmdir** *(since 0.1.0)*
* **.chdir** *(since 0.1.0)*

See them working in the *actions* example.

### REQUIRES feature commands:

* **.require** *(since 0.1.0)*
* **.requirable** *(since 0.2.2)*

See them working in the *coding* example.

### LANGUAGE feature commands:

* **.compound** *(since 0.1.0)*
* **.interface** *(since 0.1.0)*
* **.protocol** *(since 0.1.0)*
* **.class** *(since 0.1.0)*
* **.record** *(since 0.1.0)*
* **.pragmas** *(since 0.1.0)*
* **.applies** *(since 0.1.0)*
* **.implies** *(since 0.1.0)*
* **.extends** *(since 0.1.0)*
* **.fields** *(since 0.1.0)*
* **.methods** *(since 0.1.0)*
* **.templates** *(since 0.1.0)*
* **.docs** *(since 0.1.0)*
* **.constructor** *(since 0.1.0)*
* **.getter** *(since 0.3.0)*
* **.setter** *(since 0.3.0)*
* **.method** *(since 0.1.0)*
* **.template** *(since 0.1.0)*
* **.routine** *(since 0.1.0)*
* **.code** *(since 0.1.0)*
* **.end** *(since 0.1.0)*
* **.note** *(since 0.1.0)*
* **.push** *(since 0.2.0)*
* **.pop** *(since 0.2.0)*

See them working in the *coding* example.

## RELATED

You may also want to check my other nimlang projects:

* [`xam`](https://github.com/j-a-s-d/xam), my multipurpose productivity library for nim
* [`rodster`](https://github.com/j-a-s-d/rodster), my application framework for nim
* [`webrod`](https://github.com/j-a-s-d/webrod), my http server for nim
* [`preprod`](https://github.com/j-a-s-d/preprod), my customizable preprocessor for nim

## HISTORY

* 08-01-22 **[0.3.0]**
	- added .getter/.setter commands to LANGUAGE feature to wrap the native way of defining properties
	- added var modifier for .method and .setter commands
* 07-01-22 **[0.2.2]**
	- added .requirable command to REQUIRES feature to disallow the processing of files that should not be required
	- general improvements
* 06-01-22 **[0.2.1]**
	- added .unim:flush command to UNIMCMDS feature to allow the processing of files without content output
* 05-01-22 **[0.2.0]**
	- changed version signature to "FILE generated with ubernim vX.Y.Z"
	- added version signature also to .cfg generated files as a comment
	- added UNIMCMDS preprod feature
	- added .unim:version command to UNIMCMDS feature to enforce a minimum version to process
	- added .push/.pop commands to LANGUAGE feature to wrap the native pragma pair {.push ?.}/{.pop.}
	- general improvements
* 04-01-22 **[0.1.1]**
	- improved error handling
	- improved project name handling
	- general improvements
	- updated xam dependency
	- updated rodster dependency
* 31-12-21 **[0.1.0]**
	- first public release
* 08-12-21 **[0.0.1]**
	- started coding
