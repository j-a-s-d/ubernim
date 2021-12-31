# ubernim / RENDERING #
#---------------------#

import
  xam

const
  CODEGEN_INDENT* = STRINGS_SPACE & STRINGS_SPACE
  CODEGEN_STATIC* = "static"
  CODEGEN_ECHO* = "echo"
  CODEGEN_CAST* = "cast"
  CODEGEN_CALL* = "()"
  CODEGEN_DOCS* = "##"
  CODEGEN_OF* = "of"
  CODEGEN_REF* = "ref"
  CODEGEN_VAR* = "var"
  CODEGEN_SELF* = "self"
  CODEGEN_TYPE* = "type"
  CODEGEN_PROC* = "proc"
  CODEGEN_FUNC* = "func"
  CODEGEN_TUPLE* = "tuple"
  CODEGEN_METHOD* = "method"
  CODEGEN_PARENT* = "parent"
  CODEGEN_OBJECT* = "object"
  CODEGEN_RESULT* = "result"
  CODEGEN_ROOTOBJ* = "RootObj"
  CODEGEN_DISCARD* = "discard"
  CODEGEN_DATATYPE* = "datatype"
  CODEGEN_TYPEDESC* = "typedesc"
  CODEGEN_TEMPLATE* = "template"
  CODEGEN_PROCCALL* = "procCall"

func renderVersion*(version: string): string =
  CODEGEN_STATIC & STRINGS_COLON & STRINGS_SPACE & CODEGEN_ECHO & STRINGS_SPACE & quote(version) & STRINGS_EOL & STRINGS_EOL

func renderType*(id, pragmas, typedef: string): string =
  STRINGS_EOL &
    CODEGEN_TYPE & STRINGS_SPACE & id & pragmas &
    STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE & typedef

func renderRoutine*(keyword, id, arguments, outputtype, pragmas: string): string =
  STRINGS_EOL &
    keyword & STRINGS_SPACE & id & parenthesize(arguments) &
    (if hasContent(outputtype): STRINGS_COLON & STRINGS_SPACE & outputtype else: STRINGS_EMPTY) & pragmas &
    STRINGS_SPACE & STRINGS_EQUAL

func renderDocs*(docs: StringSeq): string =
  docs.each s:
    result &= STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DOCS & s

func renderId*(name: string, public: bool, generics: string): string =
  result = name
  if public:
    result &= STRINGS_ASTERISK
  if hasContent(generics):
    result &= bracketize(generics)

func renderPragmas*(text: string): string =
  if hasContent(text): STRINGS_SPACE & brace(enclose(text, STRINGS_PERIOD)) else: STRINGS_EMPTY

func renderSelf*(className: string): string =
  STRINGS_EOL & CODEGEN_INDENT &
    # alternatives for self
    # 1. var self = class() \ code \ self -- 2 lines with var, user code goes in the middle
    # 2. template self: auto = result \ self = class() \ code -- 2 lines with template, user code goes after
    # 3. var self = (result = class(); result) \ code -- 1 line with var, user code goes after [CURRENT]
    CODEGEN_VAR & STRINGS_SPACE & CODEGEN_SELF & STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE & parenthesize(
      CODEGEN_RESULT & STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE &
      className & CODEGEN_CALL & STRINGS_SEMICOLON & STRINGS_SPACE & CODEGEN_RESULT
    )

func renderParent*(parentClass: string): string =
  STRINGS_EOL & CODEGEN_INDENT &
  # alternatives for parent
  # 1. var parent = procCall self.parentName
  # 2. template parent: auto = procCall self.parentName
  # 3. var parent = procCall cast[parentName](self)
  # 4. template parent: parentName = procCall cast[parentName](self) [CURRENT]
    CODEGEN_TEMPLATE & STRINGS_SPACE & CODEGEN_PARENT & STRINGS_COLON & STRINGS_SPACE &
      parentClass & STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE & CODEGEN_PROCCALL & STRINGS_SPACE &
      CODEGEN_CAST & bracketize(parentClass) & parenthesize(CODEGEN_SELF)
