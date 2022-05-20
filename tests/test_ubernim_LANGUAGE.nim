# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim LANGUAGE":

  template testLanguageCommand(name, input, output: string, success: bool = true, onError: UbernimErrorHandler = nil, debug: bool = false) =
    writeFile(name & UNIM_EXTENSION, lined(".nimc:project " & name, ".nimc:switch --hints:off", ".nimc:switch --warnings:off", input))
    let eng = makeTestEngine()
    if assigned(onError):
      eng.setErrorHandler(onError)
    let rr = eng.run(name & UNIM_EXTENSION, newStringSeq())
    if success:
      check(rr.compilationErrorlevel == 0)
    else:
      check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    let sig = "static: echo \"" & name & ".nim testing\""
    let expected = if output.isEmpty(): sig else: lined(sig, output)
    let found = strip(readFile(name & NIM_EXTENSION))
    check(found == expected)
    if debug:
      echo "---[FOUND] " & parenthesize $found.len
      echo found
      echo "---[EXPECTED] " & parenthesize $expected.len
      echo expected
      echo "---"
    else:
      removeFiles(name & UNIM_EXTENSION, name & NIM_EXTENSION, name)

  test "test LANGUAGE push and pop":
    #
    testLanguageCommand("push_and_pop", lined(
      ".push inline",
      "proc hey() = discard",
      ".pop",
      "hey()"
    ), lined(
      STRINGS_EOL,
      "{.push inline.}",
      "proc hey() = discard",
      "{.pop.}",
      STRINGS_EMPTY,
      "hey()"
    ))

  test "test LANGUAGE exports":
    #
    testLanguageCommand("exports", lined(
      "import os, strtabs",
      ".exports",
      "  os",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".exports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os, strtabs",
      "export os",
      "export strtabs",
      "export os",
      STRINGS_EMPTY,
      "export os"
    ))

  test "test LANGUAGE exporting always":
    #
    testLanguageCommand("exporting_always", lined(
      "import os, strtabs",
      ".exporting always",
      ".exports",
      "  os",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".exports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os, strtabs",
      "export os",
      "export strtabs",
      "export os",
      STRINGS_EMPTY,
      "export os"
    ))

  test "test LANGUAGE exporting once":
    #
    testLanguageCommand("exporting_once", lined(
      "import os, strtabs",
      ".exporting once",
      ".exports",
      "  os",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".exports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os, strtabs",
      "export os",
      "export strtabs"
    ))

  test "test LANGUAGE imports":
    #
    testLanguageCommand("imports", lined(
      ".imports",
      "  os",
      "  strutils.split",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".imports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os",
      "from strutils import split",
      "import strtabs",
      "import os",
      STRINGS_EMPTY,
      "import os",
    ))

  test "test LANGUAGE importing always":
    #
    testLanguageCommand("importing_always", lined(
      ".importing always",
      ".imports",
      "  os",
      "  strutils.split",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".imports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os",
      "from strutils import split",
      "import strtabs",
      "import os",
      STRINGS_EMPTY,
      "import os",
    ))

  test "test LANGUAGE importing once":
    #
    testLanguageCommand("importing_once", lined(
      ".importing once",
      ".imports",
      "  os",
      "  strutils.split",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".imports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os",
      "from strutils import split",
      "import strtabs"
    ))

  test "test LANGUAGE note nothing":
    #
    testLanguageCommand("note_nothing", lined(
      ".note",
      ".end"
    ), STRINGS_EMPTY)

  test "test LANGUAGE note line":
    #
    testLanguageCommand("note_line", lined(
      ".note",
      "  This will be a comment in the source code.",
      ".end"
    ), STRINGS_EOL & lined(
      "#   This will be a comment in the source code.",
    ))

  test "test LANGUAGE note lines":
    #
    testLanguageCommand("note_lines", lined(
      ".note",
      "  You can insert a note into the emitted source code.",
      "  Just like this.",
      ".end"
    ), STRINGS_EOL & lined(
      "#   You can insert a note into the emitted source code.",
      "#   Just like this."
    ))

  test "test LANGUAGE member immutable immediate":
    #
    testLanguageCommand("member_immutable_immediate", lined(
      ".member immLet*:int",
      ".value 12345",
      ".end"
    ), lined(
      STRINGS_EOL,
      "let immLet*: int = 12345"
    ))

  test "test LANGUAGE member mutable immediate":
    #
    testLanguageCommand("member_mutable_immediate", lined(
      ".member var immVar*:int",
      ".value 12345",
      ".end"
    ), lined(
      STRINGS_EOL,
      "var immVar*: int = 12345"
    ))

  test "test LANGUAGE member immutable block initialized":
    #
    testLanguageCommand("member_immutable_block_initialized", lined(
      ".member biLet*: string",
      ".code",
      "  let res = \"   initializing a member...   \"",
      "  res",
      ".end"
    ), lined(
      STRINGS_EOL,
      "let biLet*: string = block:",
      "  let res = \"   initializing a member...   \"",
      "  res"
    ))

  test "test LANGUAGE member mutable block initialized":
    #
    testLanguageCommand("member_mutable_block_initialized", lined(
      ".member var biVar*: string",
      ".code",
      "  let res = \"   initializing a member...   \"",
      "  res",
      ".end"
    ), lined(
      STRINGS_EOL,
      "var biVar*: string = block:",
      "  let res = \"   initializing a member...   \"",
      "  res"
    ))

  test "test LANGUAGE member immutable immediate documented":
    #
    testLanguageCommand("member_immutable_immediate_documented", lined(
      ".member immLetWithDocs*:int",
      ".docs",
      "  This is an immutable local with an immediate value.",
      ".value 12345",
      ".end"
    ), lined(
      STRINGS_EOL,
      "let immLetWithDocs*: int = 12345 ## \\",
      "  ##  This is an immutable local with an immediate value."
    ))

  test "test LANGUAGE member mutable immediate documented":
    #
    testLanguageCommand("member_mutable_immediate_documented", lined(
      ".member var immVarWithDocs*:int",
      ".docs",
      "  This is an mutable local with an immediate value.",
      ".value 12345",
      ".end"
    ), lined(
      STRINGS_EOL,
      "var immVarWithDocs*: int = 12345 ## \\",
      "  ##  This is an mutable local with an immediate value."
    ))

  test "test LANGUAGE member immutable block initialized documented":
    #
    testLanguageCommand("member_immutable_block_initialized_documented", lined(
      ".member biLetWithDocs*: string",
      ".docs",
      "  This is an immutable local.",
      ".code",
      "  let res = \"   initializing a member...   \"",
      "  res",
      ".end"
    ), lined(
      STRINGS_EOL,
      "let biLetWithDocs*: string = block:",
      "  ##  This is an immutable local.",
      "  let res = \"   initializing a member...   \"",
      "  res"
    ))

  test "test LANGUAGE member mutable block initialized documented":
    #
    testLanguageCommand("member_mutable_block_initialized_documented", lined(
      ".member biVarWithDocs*: string",
      ".docs",
      "  This is an mutable local.",
      ".code",
      "  let res = \"   initializing a member...   \"",
      "  res",
      ".end"
    ), lined(
      STRINGS_EOL,
      "let biVarWithDocs*: string = block:",
      "  ##  This is an mutable local.",
      "  let res = \"   initializing a member...   \"",
      "  res"
    ))

  test "test LANGUAGE member mutable block initialized with uses":
    #
    testLanguageCommand("member_mutable_block_initialized_with_uses", lined(
      ".member biVarWithUses*: string",
      ".uses strutils.strip",
      ".code",
      "  let res = \"   initializing a member...   \"",
      "  strip res",
      ".end"
    ), lined(
      STRINGS_EOL,
      "from strutils import strip",
      STRINGS_EMPTY,
      "let biVarWithUses*: string = block:",
      "  let res = \"   initializing a member...   \"",
      "  strip res"
    ))

  test "test LANGUAGE member mutable uninitialized":
    #
    testLanguageCommand("member_mutable_uninitialized", lined(
      ".member var uninitializedVar*:int",
      ".end"
    ), lined(
      STRINGS_EOL,
      "var uninitializedVar*: int"
    ))

  test "test LANGUAGE member mutable uninitialized with pragma":
    #
    testLanguageCommand("member_mutable_uninitialized_with_pragma", lined(
      ".member var uninitializedVarWithPragma*:int",
      ".pragmas threadvar",
      ".end"
    ), lined(
      STRINGS_EOL,
      "var uninitializedVarWithPragma* {.threadvar.}: int"
    ))

  test "test LANGUAGE empty-body routine":
    #
    testLanguageCommand("routine_emptybody", lined(
      ".routine emptyBody()",
      ".code",
      ".end"
    ), lined(
      STRINGS_EOL,
      "proc emptyBody() ="
    ), false)

  test "test LANGUAGE routine simple":
    #
    testLanguageCommand("routine_simple", lined(
      ".routine greet(name: string): string",
      ".code",
      "  echo \"hello \" & name",
      ".end"
    ), lined(
      STRINGS_EOL,
      "proc greet(name: string): string =",
      "  echo \"hello \" & name",
    ))

  test "test LANGUAGE routine with comments":
    #
    testLanguageCommand("routine_with_comments", lined(
      ".routine greet(name: string): string # a non-preserved ubernim comment",
      ".code",
      "  echo \"hello \" & name # a preserved nim comment",
      ".end"
    ), lined(
      STRINGS_EOL,
      "proc greet(name: string): string =",
      "  echo \"hello \" & name # a preserved nim comment",
    ))

  test "test LANGUAGE routine with uses":
    #
    testLanguageCommand("routine_with_uses", lined(
      ".routine greet(name: string): string",
      ".uses strutils.join, md5",
      ".code",
      "  join([\"hello\", name, \"!\"], \" \") & \" | \" & getMD5(name)",
      ".end"
    ), lined(
      STRINGS_EOL,
      "from strutils import join",
      "import md5",
      STRINGS_EMPTY,
      "proc greet(name: string): string =",
      "  join([\"hello\", name, \"!\"], \" \") & \" | \" & getMD5(name)"
    ))

  test "test LANGUAGE routine with pragmas":
    #
    testLanguageCommand("routine_with_pragmas", lined(
      ".routine greet(name: string): string",
      ".pragmas deprecated: \"do not use it\", used",
      ".code",
      "  echo \"hello \" & name",
      ".end"
    ), lined(
      STRINGS_EOL,
      "proc greet(name: string): string {.deprecated: \"do not use it\", used.} =",
      "  echo \"hello \" & name",
    ))

  test "test LANGUAGE routine with docs":
    #
    testLanguageCommand("routine_with_docs", lined(
      ".routine greet(name: string): string",
      ".docs",
      "  This is a test routine.",
      ".code",
      "  echo \"hello \" & name",
      ".end"
    ), lined(
      STRINGS_EOL,
      "proc greet(name: string): string =",
      "  ##  This is a test routine.",
      "  echo \"hello \" & name"
    ))

  test "test LANGUAGE routine full":
    #
    testLanguageCommand("routine_full", lined(
      ".routine greet*(name: string): string # a non-preserved ubernim comment",
      ".uses strutils.join, md5",
      ".pragmas deprecated: \"do not use it\", used",
      ".docs",
      "  This is a test routine.",
      ".code",
      "  join([\"hello\", name, \"!\"], \" \") & \" | \" & getMD5(name) # a preserved nim comment",
      ".end"
    ), lined(
      STRINGS_EOL,
      "from strutils import join",
      "import md5",
      STRINGS_EMPTY,
      "proc greet*(name: string): string {.deprecated: \"do not use it\", used.} =",
      "  ##  This is a test routine.",
      "  join([\"hello\", name, \"!\"], \" \") & \" | \" & getMD5(name) # a preserved nim comment"
    ))

  test "test LANGUAGE empty-body template":
    #
    testLanguageCommand("template_emptybody", lined(
      ".template emptyBody*()",
      ".code",
      ".end"
    ), lined(
      STRINGS_EOL,
      "template emptyBody*() ="
    ), false)

  test "test LANGUAGE template can not hold pragmas":
    #
    testLanguageCommand("template_nopragmas", lined(
      ".template foo()",
      ".pragmas final",
      ".end"
    ), STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(template_nopragmas.unim:5) errors.CANT_HOLD_PRAGMAS"
    ), false, (msg: string) => check(msg == "(template_nopragmas.unim:5) errors.CANT_HOLD_PRAGMAS"))

  test "test LANGUAGE template simple":
    #
    testLanguageCommand("template_simple", lined(
      ".template globalTemplate*()",
      ".code",
      "  echo \"this is here to make the TestingProtocol fully applied to this file\"",
      ".end"
    ), lined(
      STRINGS_EOL,
      "template globalTemplate*() =",
      "  echo \"this is here to make the TestingProtocol fully applied to this file\""
    ))

  test "test LANGUAGE template with docs":
    #
    testLanguageCommand("template_with_docs", lined(
      ".template foo(something: int): string",
      ".docs",
      "  This is a test template.",
      ".code",
      "  \"bar\"",
      ".end"
    ), lined(
      STRINGS_EOL,
      "template foo(something: int): string =",
      "  ##  This is a test template.",
      "  \"bar\""
    ))

  test "test LANGUAGE record empty":
    #
    testLanguageCommand("record_empty", """
      .record Example
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple"
    ))

  test "test LANGUAGE record can not extend":
    #
    testLanguageCommand("record_noextend", lined(
      ".record Example1",
      ".end",
      ".record Example2",
      ".extends Example1",
      ".end"
    ), STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(record_noextend.unim:7) errors.RECORDS_CANT_EXTEND"
    ), false, (msg: string) => check(msg == "(record_noextend.unim:7) errors.RECORDS_CANT_EXTEND"))

  test "test LANGUAGE record pragmas":
    #
    testLanguageCommand("record_pragmas", """
      .record Example
      .pragmas final
      .end
    """, lined(
      STRINGS_EOL,
      "type Example {.final.} = tuple"
    ))

  test "test LANGUAGE record with docs":
    #
    testLanguageCommand("record_with_docs", """
      .record Example
      .docs
  This is a simple record.
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple",
      "  ##  This is a simple record."
    ))

  test "test LANGUAGE record with fields":
    #
    testLanguageCommand("record_with_fields", """
      .record Example
      .fields
     aaa: string
  bbb:bool # ubernim comments will not be preserved
           ccc:    int
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple",
      "  aaa: string",
      "  bbb: bool",
      "  ccc: int"
    ))

  test "test LANGUAGE record with empty-body method":
    #
    testLanguageCommand("record_with_emptybody_method", """
.record Example
.methods
  emptyBody()
.end

.# NOTE: if you want a trully empty body (which will not compile in nim)
.# that could be useful in some edge cases (appending your own custom code
.# with an external tool, including a large file with the method body, etc),
.# you have to declare an empty .code clause.
.# This applies for routines, methods and templates.

.method Example.emptyBody()
.code
.end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple",
      STRINGS_EMPTY,
      "proc emptyBody(self: Example) ="
    ), false)

  test "test LANGUAGE record with fields and methods":
    #
    testLanguageCommand("record_with_fields_and_methods", """
      .record Example
      .fields
        aaa: string
      .methods
        foo()
      .fields
        bbb: bool
        ccc: int
      .methods
        bar()
      .end

      .method Example.foo()
      .end

      .method Example.bar()
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple",
      "  aaa: string",
      "  bbb: bool",
      "  ccc: int",
      STRINGS_EMPTY,
      "proc foo(self: Example) =",
      "  discard",
      STRINGS_EMPTY,
      "proc bar(self: Example) =",
      "  discard"
    ))

  test "test LANGUAGE record with methods":
    #
    testLanguageCommand("record_with_methods", """
.record Example
.fields
  something: string
.methods
  mutable()
foo (   ) : string # with a comment
  bar():int
  abc[T](): T
  abc2[T]() :T
    abcd  ()
.end

.method var Example.mutable()
.code
  self.something = "hey"
.end

.method Example.foo(): string
.code
  "hello"
.end

.method Example.bar(): int
.code
  123
.end

.method Example.abcd()
.code
  discard
.end

.method Example.abc[T](): T # code-less methods will be automatically filled with discard
.end

.method Example.abc2[T](): T # code-less methods can have docs and pragmas too
.pragmas deprecated: "do not use it"
.docs
  Here a method automatically filled with discard
.end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple",
      "  something: string",
      STRINGS_EMPTY,
      "proc mutable(self: var Example) =",
      "  self.something = \"hey\"",
      STRINGS_EMPTY,
      "proc foo(self: Example): string =",
      "  \"hello\"",
      STRINGS_EMPTY,
      "proc bar(self: Example): int =",
      "  123",
      STRINGS_EMPTY,
      "proc abcd(self: Example) =",
      "  discard",
      STRINGS_EMPTY,
      "proc abc[T](self: Example): T =",
      "  discard",
      STRINGS_EMPTY,
      "proc abc2[T](self: Example): T {.deprecated: \"do not use it\".} =",
      "  ##  Here a method automatically filled with discard",
      "  discard"
    ))

  test "test LANGUAGE record with templates":
    #
    testLanguageCommand("record_with_templates", """
.record Example
.templates
  foo(code: untyped): untyped
  bar(): int
.end

.template Example.foo(code: untyped): untyped
.docs
  This is an example template of a record.
.code
  discard
.end

.template Example.bar(): int
.code
  123
.end
    """, lined(
      STRINGS_EOL,
      "type Example = tuple",
      STRINGS_EMPTY,
      "template foo(self: Example, code: untyped): untyped =",
      "  ##  This is an example template of a record.",
      "  discard",
      STRINGS_EMPTY,
      "template bar(self: Example): int =",
      "  123"
    ))

  test "test LANGUAGE class empty":
    #
    testLanguageCommand("class_empty", """
      .class Example
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object"
    ))

  test "test LANGUAGE class extends":
    #
    testLanguageCommand("class_extends", """
      .class Example1
      .end
      .class Example2
      .extends Example1
      .end
    """, lined(
      STRINGS_EOL,
      "type Example1 = ref object of RootObj",
      STRINGS_EMPTY,
      "type Example2 = ref object of Example1"
    ))

  test "test LANGUAGE class pragmas":
    #
    testLanguageCommand("class_pragmas", """
      .class Example
      .pragmas final
      .end
    """, lined(
      STRINGS_EOL,
      "type Example {.final.} = ref object"
    ))

  test "test LANGUAGE class with docs":
    #
    testLanguageCommand("class_with_docs", """
      .class Example
      .docs
  This is a simple class.
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object",
      "  ##  This is a simple class."
    ))

  test "test LANGUAGE class with fields":
    #
    testLanguageCommand("class_with_fields", """
      .class Example
      .fields
     aaa: string
  bbb:bool # ubernim comments will not be preserved
           ccc:    int
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object",
      "  aaa: string",
      "  bbb: bool",
      "  ccc: int"
    ))

  test "test LANGUAGE class with empty-body method":
    #
    testLanguageCommand("class_with_emptybody_method", """
.class Example
.methods
  emptyBody()
.end

.# NOTE: if you want a trully empty body (which will not compile in nim)
.# that could be useful in some edge cases (appending your own custom code
.# with an external tool, including a large file with the method body, etc),
.# you have to declare an empty .code clause.
.# This applies for routines, methods and templates.

.method Example.emptyBody()
.code
.end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object",
      STRINGS_EMPTY,
      "proc emptyBody(self: Example) ="
    ), false)

  test "test LANGUAGE class with fields and methods":
    #
    testLanguageCommand("record_with_fields_and_methods", """
      .class Example
      .fields
        aaa: string
      .methods
        foo()
      .fields
        bbb: bool
        ccc: int
      .methods
        bar()
      .end

      .method Example.foo()
      .end

      .method Example.bar()
      .end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object",
      "  aaa: string",
      "  bbb: bool",
      "  ccc: int",
      STRINGS_EMPTY,
      "proc foo(self: Example) =",
      "  discard",
      STRINGS_EMPTY,
      "proc bar(self: Example) =",
      "  discard"
    ))

  test "test LANGUAGE record with getters and setters":
    #
    testLanguageCommand("record_with_getters_and_setters", """
.record Person
.fields
  fName: string
.methods
  <name*: string
  >name*(value: string)
.end

.getter Person.name*: string
.code
  self.fName
.end

.setter var Person.name*(value: string)
.code
  self.fName = value
.end
    """, lined(
      STRINGS_EOL,
      "type Person = tuple",
      "  fName: string",
      STRINGS_EMPTY,
      "proc name*(self: Person): string =",
      "  self.fName",
      STRINGS_EMPTY,
      "proc `name=`*(self: var Person, value: string) =",
      "  self.fName = value"
    ))

  test "test LANGUAGE class with methods":
    #
    testLanguageCommand("class_with_methods", """
.class Example
.fields
  something: string
.methods
  mutable()
foo (   ) : string # with a comment
  bar():int
  abc[T](): T
  abc2[T]() :T
    abcd  ()
.end

.method var Example.mutable()
.code
  self.something = "hey"
.end

.method Example.foo(): string
.code
  "hello"
.end

.method Example.bar(): int
.code
  123
.end

.method Example.abcd()
.code
  discard
.end

.method Example.abc[T](): T # code-less methods will be automatically filled with discard
.end

.method Example.abc2[T](): T # code-less methods can have docs and pragmas too
.pragmas deprecated: "do not use it"
.docs
  Here a method automatically filled with discard
.end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object",
      "  something: string",
      STRINGS_EMPTY,
      "proc mutable(self: var Example) =",
      "  self.something = \"hey\"",
      STRINGS_EMPTY,
      "proc foo(self: Example): string =",
      "  \"hello\"",
      STRINGS_EMPTY,
      "proc bar(self: Example): int =",
      "  123",
      STRINGS_EMPTY,
      "proc abcd(self: Example) =",
      "  discard",
      STRINGS_EMPTY,
      "proc abc[T](self: Example): T =",
      "  discard",
      STRINGS_EMPTY,
      "proc abc2[T](self: Example): T {.deprecated: \"do not use it\".} =",
      "  ##  Here a method automatically filled with discard",
      "  discard"
    ))

  test "test LANGUAGE class with templates":
    #
    testLanguageCommand("class_with_templates", """
.class Example
.templates
  foo(code: untyped): untyped
  bar(): int
.end

.template Example.foo(code: untyped): untyped
.docs
  This is an example template of a class.
.code
  discard
.end

.template Example.bar(): int
.code
  123
.end
    """, lined(
      STRINGS_EOL,
      "type Example = ref object",
      STRINGS_EMPTY,
      "template foo(self: Example, code: untyped): untyped =",
      "  ##  This is an example template of a class.",
      "  discard",
      STRINGS_EMPTY,
      "template bar(self: Example): int =",
      "  123"
    ))

  test "test LANGUAGE class with constructors":
    #
    testLanguageCommand("class_with_constructors", """
.class Person
.fields
  age: int
  name: string
.methods
  +create*(age: int, name: string)
  +create*()
.end

.constructor Person.create*()
.pragmas noSideEffect
.docs
  This is an example constructor of a class.
.code
  self.age = 42 # self is allowed in constructors
.end

.constructor Person.create*(age: int, name: string)
.code
  self.age = age
  self.name = name
.end
    """, lined(
      STRINGS_EOL,
      "type Person = ref object",
      "  age: int",
      "  name: string",
      STRINGS_EMPTY,
      "func create*(datatype: typedesc[Person]): Person =",
      "  ##  This is an example constructor of a class.",
      "  var self = (result = Person(); result)",
      "  self.age = 42 # self is allowed in constructors",
      STRINGS_EMPTY,
      "proc create*(datatype: typedesc[Person], age: int, name: string): Person =",
      "  var self = (result = Person(); result)",
      "  self.age = age",
      "  self.name = name"
    ))

  test "test LANGUAGE class with getters and setters":
    #
    testLanguageCommand("class_with_getters_and_setters", """
.class Person
.fields
  fName: string
.methods
  <name*: string
  >name*(value: string)
.end

.getter Person.name*: string
.code
  self.fName
.end

.setter var Person.name*(value: string)
.code
  self.fName = value
.end
    """, lined(
      STRINGS_EOL,
      "type Person = ref object",
      "  fName: string",
      STRINGS_EMPTY,
      "proc name*(self: Person): string =",
      "  self.fName",
      STRINGS_EMPTY,
      "proc `name=`*(self: var Person, value: string) =",
      "  self.fName = value"
    ))

  test "test LANGUAGE compound definition":
    #
    testLanguageCommand("compound_definition", """
.compound Named
.fields
  fName: string
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE compound extends":
    #
    testLanguageCommand("compound_extends", """
.compound Named
.fields
  fName: string
.end

.compound NamedExtended
.extends Named
.fields
  fAge: int
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE compound bad definition":
    #
    testLanguageCommand("compound_bad_definition", """
.compound Named
.methods
  getName(): string
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(compound_bad_definition.unim:5) errors.CANT_HOLD_METHODS"
    ),
    false, (msg: string) => check(msg == "(compound_bad_definition.unim:5) errors.CANT_HOLD_METHODS"))

  test "test LANGUAGE compound wrongly defined":
    #
    testLanguageCommand("compound_wrongly_defined", """
.compound Named
.fields
  getName(): string
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(compound_wrongly_defined.unim:6) errors.INVALID_IDENTIFIER"
    ),
    false, (msg: string) => check(msg == "(compound_wrongly_defined.unim:6) errors.INVALID_IDENTIFIER"))

  test "test LANGUAGE compound bad extends":
    #
    testLanguageCommand("compound_bad_extends", """
.compound Named
.fields
  fName: string
.end

.compound NamedExtended
.extends Named
.fields
  fName: string
  fAge: int
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(compound_bad_extends.unim:12) errors.ALREADY_DEFINED"
    ),
    false, (msg: string) => check(msg == "(compound_bad_extends.unim:12) errors.ALREADY_DEFINED"))

  test "test LANGUAGE compound bad apply":
    #
    testLanguageCommand("compound_bad_apply", """
.compound Named
.fields
  fName: string
.end

.class Person
.applies Named
.fields
  fAge: int
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(compound_bad_apply.unim:9) errors.MISSING_MEMBER"
    ),
    false, (msg: string) => check(msg == "(compound_bad_apply.unim:9) errors.MISSING_MEMBER"))

  test "test LANGUAGE class applying compound":
    #
    testLanguageCommand("class_applying_compound", """
.compound Named
.fields
  fName: string
.end

.class Person
.applies Named
.fields
  fName: string
  fAge: int
.end
    """, lined(
      STRINGS_EOL,
      "type Person = ref object",
      "  fName: string",
      "  fAge: int"
    ))

  test "test LANGUAGE record applying compound":
    #
    testLanguageCommand("record_applying_compound", """
.compound Named
.fields
  fName: string
.end

.record Person
.applies Named
.fields
  fName: string
  fAge: int
.end
    """, lined(
      STRINGS_EOL,
      "type Person = tuple",
      "  fName: string",
      "  fAge: int"
    ))

  test "test LANGUAGE interface definition":
    #
    testLanguageCommand("interface_definition", """
.interface Named
.methods
  getName(): string
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE interface extends":
    #
    testLanguageCommand("interface_extends", """
.interface Named
.methods
  getName(): string
.end

.interface NamedExtended
.extends Named
.methods
  getAge(): int
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE interface bad definition":
    #
    testLanguageCommand("interface_bad_definition", """
.interface Named
.fields
  fName: string
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(interface_bad_definition.unim:5) errors.CANT_HOLD_FIELDS"
    ),
    false, (msg: string) => check(msg == "(interface_bad_definition.unim:5) errors.CANT_HOLD_FIELDS"))

  test "test LANGUAGE interface wrongly defined":
    #
    testLanguageCommand("interface_wrongly_defined", """
.interface Named
.methods
  fName: string
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(interface_wrongly_defined.unim:6) errors.WRONGLY_DEFINED"
    ),
    false, (msg: string) => check(msg == "(interface_wrongly_defined.unim:6) errors.WRONGLY_DEFINED"))

  test "test LANGUAGE interface redundant definition":
    #
    testLanguageCommand("interface_redundant_definition", """
.interface Named
.methods
  getName(): string
.end

.interface NamedExtended
.extends Named
.methods
  getName(): string
  getAge(): int
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE interface bad apply":
    #
    testLanguageCommand("interface_bad_apply", """
.interface Named
.methods
  getName(): string
.end

.class Person
.applies Named
.methods
  getAge(): int
.end

.method Person.getAge(): int
.code
  42
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(interface_bad_apply.unim:9) errors.MISSING_MEMBER"
    ),
    false, (msg: string) => check(msg == "(interface_bad_apply.unim:9) errors.MISSING_MEMBER"))

  test "test LANGUAGE class applying interface with getters and setters":
    #
    testLanguageCommand("class_applying_interface_with_getters_and_setters", """
.interface Named
.methods
  <name*: string
  >name*(value: string)
.end

.class Person
.applies Named
.fields
  fName: string
.methods
  <name*: string
  >name*(value: string)
.end

.getter Person.name*: string
.code
  self.fName
.end

.setter var Person.name*(value: string)
.code
  self.fName = value
.end
    """, lined(
      STRINGS_EOL,
      "type Person = ref object",
      "  fName: string",
      STRINGS_EMPTY,
      "proc name*(self: Person): string =",
      "  self.fName",
      STRINGS_EMPTY,
      "proc `name=`*(self: var Person, value: string) =",
      "  self.fName = value"
    ))

  test "test LANGUAGE protocol definition":
    #
    testLanguageCommand("protocol_definition", """
.protocol Named
.fields
  fName: string
.methods
  getName(): string
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE protocol extends":
    #
    testLanguageCommand("protocol_extends", """
.protocol Named
.fields
  fName: string
.methods
  getName(): string
.end

.protocol NamedExtended
.extends Named
.fields
  fAge: int
.methods
  getAge(): int
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE protocol wrongly defined":
    #
    testLanguageCommand("protocol_wrongly_defined", """
.protocol Named
.methods
  fName: string
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(protocol_wrongly_defined.unim:6) errors.WRONGLY_DEFINED"
    ),
    false, (msg: string) => check(msg == "(protocol_wrongly_defined.unim:6) errors.WRONGLY_DEFINED"))

  test "test LANGUAGE protocol bad extends":
    #
    testLanguageCommand("protocol_bad_extends", """
.protocol Named
.fields
  fName: string
.end

.protocol NamedExtended
.extends Named
.fields
  fName: string
.methods
  getName(): string
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(protocol_bad_extends.unim:12) errors.ALREADY_DEFINED"
    ),
    false, (msg: string) => check(msg == "(protocol_bad_extends.unim:12) errors.ALREADY_DEFINED"))

  test "test LANGUAGE protocol redundant definition":
    #
    testLanguageCommand("protocol_redundant_definition", """
.protocol Named
.fields
  fName: string
.methods
  getName(): string
.end

.protocol NamedExtended
.extends Named
.methods
  getName(): string
  getAge(): int
.end
    """, STRINGS_EMPTY)

  test "test LANGUAGE protocol bad apply":
    #
    testLanguageCommand("protocol_bad_apply", """
.protocol Named
.fields
  fName: string
.methods
  getName(): string
.end

.class Person
.applies Named
.fields
  fAge: int
.methods
  getAge(): int
.end

.method Person.getAge(): int
.code
  fAge
.end
    """, STRINGS_EOL & lined(
      STRINGS_EMPTY,
      "(protocol_bad_apply.unim:11) errors.MISSING_MEMBER"
    ),
    false, (msg: string) => check(msg == "(protocol_bad_apply.unim:11) errors.MISSING_MEMBER"))

  test "test LANGUAGE record applying protocol with templates":
    #
    testLanguageCommand("record_applying_protocol_with_templates", """
.protocol Named
.templates
  getName*(): string
  setName*(value: string)
.end

.record Person
.applies Named
.fields
  fName: string
.templates
  getName*(): string
  setName*(value: string)
.end

.template Person.getName*(): string
.code
  self.fName
.end

.template Person.setName*(value: string)
.code
  self.fName = value
.end
    """, lined(
      STRINGS_EOL,
      "type Person = tuple",
      "  fName: string",
      STRINGS_EMPTY,
      "template getName*(self: Person): string =",
      "  self.fName",
      STRINGS_EMPTY,
      "template setName*(self: Person, value: string) =",
      "  self.fName = value"
    ))

  test "test LANGUAGE applying":
    #
    writeFile("protocol.unim", """
.unim:flush no

.protocol TestingProtocol*
.fields
  uninitializedVar: int
.methods
  makeGreetingMessageTo(name: string): string
.templates
  globalTemplate()
.end
""")
    writeFile("required.unim", """
.require protocol.unim

.member var uninitializedVar*:int
.end

.routine makeGreetingMessageTo(name: string): string
.code
  "hello " & name
.end

.template globalTemplate*()
.code
  echo "this is here to make the TestingProtocol fully applied to this file"
.end

.applying TestingProtocol
""")
    writeFile("require.unim", """
.nimc:project require
.nimc:switch --hints:off
.nimc:switch --warnings:off
.require required.unim
import required

uninitializedVar = 123
""")
    let eng = makeTestEngine()
    let rr = eng.run("require.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("require", "require.unim", "required.unim", "protocol.unim", "require.nim", "required.nim")
