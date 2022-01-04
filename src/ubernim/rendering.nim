# ubernim / RENDERING #
#---------------------#

import
  xam,
  language / header

use sequtils,filterIt
use strutils,split
use strutils,strip
use strutils,join
use strutils,find

const
  NIMLANG_NOSIDEEFFECT = "noSideEffect"
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

func renderConstructorBegin*(m: LanguageMember, isClass: bool, className: string): string =
  let kw = if m.pragmas.find(NIMLANG_NOSIDEEFFECT) != -1: CODEGEN_FUNC else: CODEGEN_PROC
  let args = CODEGEN_DATATYPE & STRINGS_COLON & STRINGS_SPACE & CODEGEN_TYPEDESC & bracketize(className) & (
    if hasContent(m.data_extra): STRINGS_COMMA & STRINGS_SPACE & m.data_extra else: STRINGS_EMPTY
  )
  let pragmas = renderPragmas(m.pragmas.split(STRINGS_COMMA).filterIt(it.strip() != NIMLANG_NOSIDEEFFECT).join(STRINGS_COMMA).strip())
  let stub = if isClass: renderSelf(className) else: STRINGS_EMPTY
  renderRoutine(kw, renderId(m.name, m.public, m.generics), args, className, pragmas) & renderDocs(m.docs) & stub

func renderConstructorEnd*(): string =
  #CODEGEN_INDENT & CODEGEN_SELF &
  STRINGS_EOL

func renderMethodBegin*(m: LanguageMember, isClass: bool, className: string, parentName: string): string =
  let kw = if m.pragmas.find(NIMLANG_NOSIDEEFFECT) != -1: CODEGEN_FUNC else: CODEGEN_PROC
  let args = CODEGEN_SELF & STRINGS_COLON & STRINGS_SPACE & className & (
    if hasContent(m.data_extra): STRINGS_COMMA & STRINGS_SPACE & m.data_extra else: STRINGS_EMPTY
  )
  let pragmas = renderPragmas(m.pragmas.split(STRINGS_COMMA).filterIt(it.strip() != NIMLANG_NOSIDEEFFECT).join(STRINGS_COMMA).strip())
  let stub = if isClass and hasContent(parentName): renderParent(parentName) else: STRINGS_EMPTY
  renderRoutine(kw, renderId(m.name, m.public, m.generics), args, m.data_type, pragmas) & renderDocs(m.docs) & stub

func renderMethodEnd*(): string =
  STRINGS_EOL

func renderTemplateBegin*(m: LanguageMember, className: string): string =
  let args = CODEGEN_SELF & STRINGS_COLON & STRINGS_SPACE & className & (
    if hasContent(m.data_extra): STRINGS_COMMA & STRINGS_SPACE & m.data_extra else: STRINGS_EMPTY
  )
  renderRoutine(
    CODEGEN_TEMPLATE, renderId(m.name, m.public, m.generics), args, m.data_type, renderPragmas(m.pragmas.strip())
  ) & renderDocs(m.docs)

func renderTemplateEnd*(): string =
  STRINGS_EOL

func renderRoutineBegin*(m: LanguageMember): string =
  let kw = if m.pragmas.find(NIMLANG_NOSIDEEFFECT) != -1: CODEGEN_FUNC else: CODEGEN_PROC
  let pragmas = renderPragmas(m.pragmas.split(STRINGS_COMMA).filterIt(it.strip() != NIMLANG_NOSIDEEFFECT).join(STRINGS_COMMA).strip())
  renderRoutine(
    kw, renderId(m.name, m.public, m.generics), m.data_extra, m.data_type, pragmas
  ) & renderDocs(m.docs)

func renderRoutineEnd*(): string =
  STRINGS_EOL
