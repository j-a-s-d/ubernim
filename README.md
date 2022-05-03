# ubernim
an experimental tool offering extended capabilities for nim

## MOTIVATION
> *"If you want more effective programmers, you will discover that they should not waste their time debugging, they should not introduce the bugs to starth with."*
- Edger Dijkstra, The Humble Programmer, 1972

## CHARACTERISTICS

Ubernim allows:

* compiler directives in the source file and compiler invokation all at once (without the need of calling nim by hand)
* custom build actions in the source file (without the need of nims or nimble solutions)
* language-like superset to allow fields and methods enforcement (via the use of compounds -a novelty-, interfaces and protocols applying to tuples, objects and even files) with some class-based oop features emitting pure nim language source code (without the need of macros usage at all)
* old-school preprocessing capabilities (by exposing Preprod features)

and all this via a simple preprocessing approach (built on top of Preprod, Rodster and Xam libraries).

> NOTE: this is a `work in progress`, complete and enhance existing features, add more options in almost everything, test cases, better documentation and more examples are planned towards a 1.0.0 release

## COMMANDS

All the preprocessing work is specified via commands.
Check the full available [`commands`](docs/commands.md) list.

## RELATED

You may also want to check my other nimlang projects:

* [`xam`](https://github.com/j-a-s-d/xam), my multipurpose productivity library for nim
* [`rodster`](https://github.com/j-a-s-d/rodster), my application framework for nim
* [`webrod`](https://github.com/j-a-s-d/webrod), my http server for nim
* [`preprod`](https://github.com/j-a-s-d/preprod), my customizable preprocessor for nim

## HISTORY

* 03-05-22 **[0.7.3]**
	- added PT (portguese) language for displaying error messages
* 30-04-22 **[0.7.2]**
	- added command line error messages language specification handling
	- added ES (spanish) language for displaying error messages
* 27-04-22 **[0.7.1]**
	- updated xam dependency to 1.7.4
	- general improvements
* 23-04-22 **[0.7.0]**
	- added .unim:destination to UNIMCMDS feature to allow the modification of the autocatically generated files directory
	- added the official Ubernim plugin for Lite XL editor to the extras directory
* 28-03-22 **[0.6.6]**
	- added more test cases
	- general improvements
* 22-03-22 **[0.6.5]**
	- added more test cases
	- general improvements
* 11-03-22 **[0.6.4]**
	- added more test cases
	- general improvements
* 09-03-22 **[0.6.3]**
	- added more test cases
	- general improvements
* 03-03-22 **[0.6.2]**
	- added more test cases
	- updated xam dependency to 1.7.2
	- general improvements
* 24-02-22 **[0.6.1]**
	- added more test cases
	- updated xam dependency to 1.7.1
	- general improvements
* 21-02-22 **[0.6.0]**
	- added initial test cases
	- general improvements
* 14-02-22 **[0.5.5]**
	- improved .applies command to support multiple comma separated values
	- general improvements
* 10-02-22 **[0.5.4]**
	- added UNIMPRJS preprod feature to allow projects definition and handling
	- updated preprod dependency to 1.0.2
	- general improvements
* 04-02-22 **[0.5.3]**
	- added TARGETED preprod feature to allow targeted code blocks
* 03-02-22 **[0.5.2]**
	- improved valid identifier check
* 02-02-22 **[0.5.1]**
	- added .templates child command to .protocol command to allow templates enforcing in classes, records and files
	- general improvements
* 01-02-22 **[0.5.0]**
	- added .member to LANGUAGE feature to allow the declaration of initializable let and var locals
	- added .value child command to .member command to allow immediate value assignments
	- moved .importing and .exporting commands to the LANGUAGE feature
	- added .applying to the LANGUAGE feature to allow enforcement of routines and members in files
	- removed .implies from LANGUAGE feature due to redundancy
	- added command line preprocessor defines handling
	- updated rodster dependency to 1.3.0
	- general improvements
* 19-01-22 **[0.4.4]**
	- added .nimc:target to SWITCHES feature to allow to specify the target compiler
	- general improvements
* 18-01-22 **[0.4.3]**
	- added .unim:cleanup to UNIMCMDS feature to allow the removal of generated files after all steps are done
	- updated rodster dependency to 1.2.0
	- general improvements
* 16-01-22 **[0.4.2]**
	- added .nimc:minimum to SWITCHES feature to require a minimum nim version installed to perform the preprocessing
	- updated xam dependency to 1.7.0
	- general improvements
* 15-01-22 **[0.4.1]**
	- added .unim:importing and .unim:exporting commands to UNIMCMDS feature to allow imports and exports to be generated only once per file
	- general improvements
* 14-01-22 **[0.4.0]**
	- added .imports and .exports commands to LANGUAGE feature to add support for imports and exports
	- general improvements
* 13-01-22 **[0.3.3]**
	- added .uses command to LANGUAGE feature to add support for local imports to .routine, .constructor, .getter, .setter, .method and .template
	- general improvements
* 12-01-22 **[0.3.2]**
	- added .unim:mode command to UNIMCMDS feature to disallow the processing of files that contain raw nim code
	- general improvements
* 11-01-22 **[0.3.1]**
	- added docs/commands.md documentation file
	- improved name clash detection for properties
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
	- updated xam dependency to 1.6.2
	- updated rodster dependency to 1.1.0
* 31-12-21 **[0.1.0]**
	- first public release
* 08-12-21 **[0.0.1]**
	- started coding
