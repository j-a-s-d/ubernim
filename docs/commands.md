# ubernim

This is the documentation of the ubernim commands (separated by preprod features).

## COMMANDS

### UNIMCMDS feature commands:

* **.unim:version** *(since 0.2.0)*
	- specifies the minimum version of ubernim required to process this file
	- values: semantic version format (x.x.x)
	- example: `.unim:version 0.3.0`
* **.unim:flush** *(since 0.2.1)*
	- specifies if the current file will emit output as a file
	- values: yes/no (default: yes)
	- note: this is useful for files where compounds, interfaces or protocols are defined and exported
	- example: `.unim:flush no`
* **.unim:mode** *(since 0.3.2)*
	- specifies if the following lines in the file can be not ubernim lines
	- values: free/strict (default: free)
	- note: this is useful to restrict portions or entire files from containing nim code
	- example: `.unim:mode strict`

See them working in the *coding* example.

### SWITCHES feature commands:

* **.nimc:project** *(since 0.1.0)*
	- specifies the project file name for the nim compile command, if you don't specify any file name the transpile will be done but the nim compiler won't be invoked
	- values: any valid file name (typically a .nim extension file)
	- example: `.nimc:project file.nim`
* **.nimc:config** *(since 0.1.0)*
	- specifies the project configuration file name for the nim compile command, if you don't specify any file name the defines and switches will be passed via command line on compiler invokation
	- values: any valid file name (typically a .nim.cfg extension file)
	- example: `.nimc:config file.nim.cfg`
* **.nimc:define** *(since 0.1.0)*
	- specifies a define name to be passed to the nim compiler
	- values: any valid define name
	- example: `.nimc:define release`
* **.nimc:switch** *(since 0.1.0)*
	- specifies a switch name to be passed to the nim compiler
	- values: any valid switch name
	- example: `.nimc:switch --threads:on`

See them working in the *directives* example.

### SHELLCMD feature commands:

* **.exec** *(since 0.1.0)*
	- specifies a shell command to be executed
	- values: any valid shell command
	- example: `.exec dir`

See them working in the *actions* example.

### FSACCESS feature commands:

* **.write** *(since 0.1.0)*
	- creates a file using the specified name and content
	- values: any valid file name and content
	- example: `.write foo.txt bar`
* **.append** *(since 0.1.0)*
	- appends a file using the specified name and content
	- values: any valid file name and content
	- example: `.append foo.txt !!!`
* **.copy** *(since 0.1.0)*
	- copies a file
	- values: any valid file names
	- example: `.copy foo.txt bar.txt`
* **.move** *(since 0.1.0)*
	- moves or rename a file
	- values: any valid file names
	- example: `.move bar.txt blah.txt`
* **.remove** *(since 0.1.0)*
	- removes a file
	- values: any valid file names
	- example: `.remove blah.txt`
* **.mkdir** *(since 0.1.0)*
	- creates a directory
	- values: any valid directory name
	- example: `.mkdir bin`
* **.cpdir** *(since 0.1.0)*
	- copies a directory
	- values: any valid directory name
	- example: `.cpdir bin out`
* **.rmdir** *(since 0.1.0)*
	- removes a directory
	- values: any valid directory name
	- example: `.rmdir bin`
* **.chdir** *(since 0.1.0)*
	- changes currenty directory to the specified one
	- values: any valid directory name
	- example: `.chdir ..`

See them working in the *actions* example.

### REQUIRES feature commands:

* **.require** *(since 0.1.0)*
	- specifies another ubernim file to be preprocessed, importing all the exported symbols from it to be used in the current one
	- values: any valid file name (typically a .unim extension file)
	- example: `.require file.unim`
* **.requirable** *(since 0.2.2)*
	- specifies if the current ubernim file can be required from other ubernim file
	- values: yes/no (default: yes)
	- note: the main file is not requirable by default and that can not be changed
	- example: `.requirable no`

See them working in the *coding* example.

### LANGUAGE feature commands:

* **.compound** *(since 0.1.0)*
	- specifies a group of fields that must be present in those that applies it
	- values: any valid identifier
	- example: `.compound BunchOfFields`
* **.interface** *(since 0.1.0)*
	- specifies a group of methods that must be present in those that applies it
	- values: any valid identifier
	- example: `.interface BunchOfMethods`
* **.protocol** *(since 0.1.0)*
	- specifies a group of fields and methods that must be present in those that applies it
	- values: any valid identifier
	- example: `.protocol MyProcotol`
* **.class** *(since 0.1.0)*
	- specifies a new class type
	- values: any valid identifier
	- example: `.class MyClass`
* **.record** *(since 0.1.0)*
	- specifies a new record type
	- values: any valid identifier
	- example: `.record MyRecord`
* **.pragmas** *(since 0.1.0)*
	- specifies one or more pragmas
	- values: any valid pragmas in the regular comma separated fashion (the same you would write inside {. .})
	- example: `.pragmas noSideEffect, deprecated: "use something else"`
* **.applies** *(since 0.1.0)*
	- specifies a compound, interface or protocol that will be applied to this protocol, class or record
	- values: any valid existing compound, interface or protocol
	- example: `.applies SomeInterface`
* **.implies** *(since 0.1.0)*
	- specifies a class or record which fields will be copied inside the current class or record
	- values: any valid existing class or record (type must match)
	- example: `.implies AnotherClass`
* **.extends** *(since 0.1.0)*
	- specifies a class or record to extend the current class or record
	- values: any valid existing class or record (type must match)
	- example: `.extends SuperClass`
* **.fields** *(since 0.1.0)*
	- specifies a group of fields
	- values: field defitions after it (in the regular form of identifier:type), check the examples
	- example: `.fields`
* **.methods** *(since 0.1.0)*
	- specifies a group of methods
	- values: method definitions after it (mostly like in regular nim), check the examples
	- example: `.methods`
* **.templates** *(since 0.1.0)*
	- specifies a group of templates
	- values: any valid identifier
	- example: `.templates`
* **.docs** *(since 0.1.0)*
	- specifies the documentation for this item
	- values: any valid documentation content (whatever you would write after regular ## lines) after it
	- example: `.docs`
* **.constructor** *(since 0.1.0)*
	- specifies a new constructor for a class or record implementation
	- values: class name period the regular method definition (any valid identifier plus the arguments inside parenthesis)
	- note: access to parent -if any- is not available in constructors
	- example: `.constructor TestClass.create(something: int, somethingElse: string)`
* **.getter** *(since 0.3.0)*
	- specifies a new property getter for a class or record implementation
	- values: the regular getter -field like- definition (any valid identifier plus the return type)
	- example: `.getter TestClass.prop: string`
* **.setter** *(since 0.3.0)*
	- specifies a new property setter for a class or record implementation
	- values: the regular setter definition (any valid identifier plus the arguments inside parenthesis, and the return type after a colon if any)
	- note: remember to add 'var' before the class name if the setter does actually modify any field value (which typically will)
	- example: `.setter var TestClass.prop(value: string)`
* **.method** *(since 0.1.0)*
	- specifies a new method for a class or record implementation
	- values: the regular method definition (any valid identifier plus the arguments inside parenthesis, and the return type after a colon if any)
	- note: remember to add 'var' before the class name if the setter does actually modify any field value
	- example: `.method TestClass.MyMethod(a: int, b: float): string`
* **.template** *(since 0.1.0)*
	- specifies a new template
	- values: the regular method definition (any valid identifier plus the arguments inside parenthesis, and the return type after a colon if any)
	- example: `.template MyTemplate(a: untyped)`
* **.routine** *(since 0.1.0)*
	- specifies a new routine
	- values: the regular method definition (any valid identifier plus the arguments inside parenthesis, and the return type after a colon if any)
	- example: `.routine MyProcedure(a: int, b: float): string`
* **.code** *(since 0.1.0)*
	- specifies the code for the current block
	- values: any valid nim lines after it
	- example: `.code`
* **.uses** *(since 0.3.3)*
	- specifies one or more imports required by the current block
	- values: any valid nim import in the regular comma separated fashion (except of the from/import syntax that is simplified with a period between the module and the entity)
	- example: `.uses sequtils, strutils.join, json`
* **.end** *(since 0.1.0)*
	- specifies the end of the current block
	- values: none
	- example: `.end`
* **.note** *(since 0.1.0)*
	- specifies a note block that will be emitted as comment lines
	- values: any valid comment content after it
	- example: `.note`
* **.push** *(since 0.2.0)*
	- specifies pragmas that will be pushed to the nim's pragma stack
	- values: any valid pragma values you would push in nim
	- example: `.push`
* **.pop** *(since 0.2.0)*
	- specifies a pop from the nim's pragma stack
	- values: none
	- example: `.pop`

See them working in the *coding* example.
