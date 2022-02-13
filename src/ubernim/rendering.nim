# ubernim / RENDERING #
#---------------------#

import
  xam,
  language / header

use sequtils,filter
use strutils,split
use strutils,strip
use strutils,join
use strutils,find

const
  NIMLANG_NOSIDEEFFECT = "noSideEffect"
  NIMLANG_TRIPLEQUOTE = "\"\"\"" # heredoc
  CODEGEN_STATIC* = "static"
  CODEGEN_ECHO* = "echo"
  CODEGEN_CAST* = "cast"
  CODEGEN_FROM* = "from"
  CODEGEN_OF* = "of"
  CODEGEN_REF* = "ref"
  CODEGEN_LET* = "let"
  CODEGEN_VAR* = "var"
  CODEGEN_POP* = "pop"
  CODEGEN_PUSH* = "push"
  CODEGEN_SELF* = "self"
  CODEGEN_AUTO* = "auto"
  CODEGEN_TYPE* = "type"
  CODEGEN_PROC* = "proc"
  CODEGEN_FUNC* = "func"
  CODEGEN_LINK* = "link"
  CODEGEN_EMIT* = "emit"
  CODEGEN_BLOCK* = "block"
  CODEGEN_TUPLE* = "tuple"
  CODEGEN_IMPORT* = "import"
  CODEGEN_EXPORT* = "export"
  CODEGEN_METHOD* = "method"
  CODEGEN_PARENT* = "parent"
  CODEGEN_OBJECT* = "object"
  CODEGEN_RESULT* = "result"
  CODEGEN_ROOTOBJ* = "RootObj"
  CODEGEN_DISCARD* = "discard"
  CODEGEN_COMPILE* = "compile"
  CODEGEN_DATATYPE* = "datatype"
  CODEGEN_TYPEDESC* = "typedesc"
  CODEGEN_TEMPLATE* = "template"
  CODEGEN_PROCCALL* = "procCall"
  CODEGEN_EMIT_OPEN* = STRINGS_BRACES_OPEN & STRINGS_PERIOD & CODEGEN_EMIT & STRINGS_COLON & STRINGS_SPACE & NIMLANG_TRIPLEQUOTE
  CODEGEN_EMIT_CLOSE* = NIMLANG_TRIPLEQUOTE & STRINGS_PERIOD & STRINGS_BRACES_CLOSE
  CODEGEN_INDENT* = STRINGS_SPACE & STRINGS_SPACE
  CODEGEN_CALL* = STRINGS_PARENTHESES_OPEN & STRINGS_PARENTHESES_CLOSE
  CODEGEN_DOCS* = STRINGS_NUMERAL & STRINGS_NUMERAL

func renderSignature*(file, signature: string): string =
  spaced(CODEGEN_STATIC & STRINGS_COLON, CODEGEN_ECHO, quote(spaced(file, signature))) & STRINGS_EOL & STRINGS_EOL

func renderType*(id, pragmas, typedef: string): string =
  STRINGS_EOL &
    spaced(CODEGEN_TYPE, id & pragmas, STRINGS_EQUAL, typedef)

func renderRoutine*(keyword, id, arguments, outputtype, pragmas: string): string =
  STRINGS_EOL &
    spaced(keyword, id & parenthesize(arguments) & (
      if hasContent(outputtype): spaced(STRINGS_COLON, outputtype) else: STRINGS_EMPTY
    ) & pragmas, STRINGS_EQUAL)

func renderMember*(keyword, id, pragmas, outputtype, extra: string): string =
  STRINGS_EOL &
    spaced(keyword, id & pragmas & (
      if hasContent(outputtype): spaced(STRINGS_COLON, outputtype) else: STRINGS_EMPTY
    )) & (
      if hasContent(extra): STRINGS_SPACE & spaced(STRINGS_EQUAL, extra) else: STRINGS_EMPTY
    )

func renderDocs*(docs: StringSeq): string =
  docs.each line:
    result &= STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DOCS & line

func renderId*(name: string, public: bool, generics: string): string =
  result = name
  if public:
    result &= STRINGS_ASTERISK
  if hasContent(generics):
    result &= bracketize(generics)

func renderPragmas*(text: string; prefixSpace: bool = true): string =
  if hasContent(text):
    (if prefixSpace: STRINGS_SPACE else: STRINGS_EMPTY) & brace(enclose(text.strip(), STRINGS_PERIOD))
  else:
    STRINGS_EMPTY

func renderClassSelf*(className: string): string =
  STRINGS_EOL & CODEGEN_INDENT &
    # alternatives for self
    # 1. var self = class() \ code \ self -- 2 lines with var, user code goes in the middle
    # 2. template self: auto = result \ self = class() \ code -- 2 lines with template, user code goes after
    # 3. var self = (result = class(); result) \ code -- 1 line with var, user code goes after [CURRENT]
    CODEGEN_VAR & STRINGS_SPACE & CODEGEN_SELF & STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE & parenthesize(
      CODEGEN_RESULT & STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE &
      className & CODEGEN_CALL & STRINGS_SEMICOLON & STRINGS_SPACE & CODEGEN_RESULT
    )

func renderRecordSelf*(className: string): string =
  STRINGS_EOL & CODEGEN_INDENT &
    # alternatives for self
    # 1. var self = class() \ code \ self -- 2 lines with var, user code goes in the middle
    # 2. template self: auto = result \ self = class() \ code -- 2 lines with template, user code goes after [CURRENT]
    # 3. var self = (result = class(); result) \ code -- 1 line with var, user code goes after
    CODEGEN_TEMPLATE & STRINGS_SPACE & CODEGEN_SELF & STRINGS_COLON & STRINGS_SPACE &
      CODEGEN_AUTO & STRINGS_SPACE & STRINGS_EQUAL & STRINGS_SPACE & CODEGEN_RESULT

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

func renderUses*(uses: StringSeq): string =
  if hasContent(uses):
    result = STRINGS_EOL
    uses.each u:
      if u.find(STRINGS_PERIOD) > -1:
        let p = u.split(STRINGS_PERIOD)
        result &= spaced(CODEGEN_FROM, strip(p[0]), CODEGEN_IMPORT, strip(p[1]))
      else:
        result &= spaced(CODEGEN_IMPORT, strip(u))
      result &= STRINGS_EOL
    result &= STRINGS_EOL
  else:
    result = STRINGS_EMPTY

func renderConstructorBegin*(m: LanguageItem, isClass: bool, className: string): string =
  let kw = if m.pragmas.find(NIMLANG_NOSIDEEFFECT) != -1: CODEGEN_FUNC else: CODEGEN_PROC
  let args = spaced(CODEGEN_DATATYPE & STRINGS_COLON, CODEGEN_TYPEDESC & bracketize(className) & (
    if hasContent(m.data_extra): spaced(STRINGS_COMMA, m.data_extra) else: STRINGS_EMPTY
  ))
  let pragmas = renderPragmas(m.pragmas.split(STRINGS_COMMA).filter((it) => it.strip() != NIMLANG_NOSIDEEFFECT).join(STRINGS_COMMA))
  let stub = if isClass: renderClassSelf(className) else: renderRecordSelf(className)
  renderRoutine(kw, renderId(m.name, m.public, m.generics), args, className, pragmas) & renderDocs(m.docs) & stub

func renderConstructorEnd*(): string =
  #CODEGEN_INDENT & CODEGEN_SELF &
  STRINGS_EOL

func renderMethodBegin*(m: LanguageItem, isClass: bool, className: string, parentName: string): string =
  let kw = if m.pragmas.find(NIMLANG_NOSIDEEFFECT) != -1: CODEGEN_FUNC else: CODEGEN_PROC
  let args = spaced(CODEGEN_SELF & STRINGS_COLON, (
    if m.data_var: CODEGEN_VAR & STRINGS_SPACE else: STRINGS_EMPTY
  ) & className & (
    if hasContent(m.data_extra): spaced(STRINGS_COMMA, m.data_extra) else: STRINGS_EMPTY
  ))
  let pragmas = renderPragmas(m.pragmas.split(STRINGS_COMMA).filter((it) => it.strip() != NIMLANG_NOSIDEEFFECT).join(STRINGS_COMMA).strip())
  let stub = if isClass and hasContent(parentName): renderParent(parentName) else: STRINGS_EMPTY
  let name = if m.data_setter: enclose(m.name & STRINGS_EQUAL, STRINGS_BACKTICK) else: m.name
  renderRoutine(kw, renderId(name, m.public, m.generics), args, m.data_type, pragmas) & renderDocs(m.docs) & stub

func renderMethodEnd*(): string =
  STRINGS_EOL

func renderTemplateBegin*(m: LanguageItem, className: string): string =
  let args = if className == SCOPE_GLOBAL: STRINGS_EMPTY else: spaced(CODEGEN_SELF & STRINGS_COLON, className & (
    if hasContent(m.data_extra): spaced(STRINGS_COMMA, m.data_extra) else: STRINGS_EMPTY
  ))
  renderRoutine(
    CODEGEN_TEMPLATE, renderId(m.name, m.public, m.generics), args, m.data_type, renderPragmas(m.pragmas)
  ) & renderDocs(m.docs)

func renderTemplateEnd*(): string =
  STRINGS_EOL

func renderMemberBegin*(m: LanguageItem, init: bool): string =
  let kw = if m.data_var: CODEGEN_VAR else: CODEGEN_LET
  let pragmas = renderPragmas(m.pragmas)
  let doc = renderDocs(m.docs)
  let extra = if hasContent(m.data_extra): (
    if hasContent(doc): spaced(m.data_extra, CODEGEN_DOCS, STRINGS_BACKSLASH) else: m.data_extra
  ) else: (
    if init: CODEGEN_BLOCK & STRINGS_COLON else: STRINGS_EMPTY
  )
  renderMember(
    kw, renderId(m.name, m.public, m.generics), pragmas, m.data_type, extra
  ) & doc

func renderMemberEnd*(): string =
  STRINGS_EOL

func renderRoutineBegin*(m: LanguageItem): string =
  let kw = if m.pragmas.find(NIMLANG_NOSIDEEFFECT) != -1: CODEGEN_FUNC else: CODEGEN_PROC
  let pragmas = renderPragmas(m.pragmas.split(STRINGS_COMMA).filter((it) => it.strip() != NIMLANG_NOSIDEEFFECT).join(STRINGS_COMMA))
  renderRoutine(
    kw, renderId(m.name, m.public, m.generics), m.data_extra, m.data_type, pragmas
  ) & renderDocs(m.docs)

func renderRoutineEnd*(): string =
  STRINGS_EOL

func renderPush*(pragmas: string): string =
  if hasContent(pragmas): renderPragmas(spaced(CODEGEN_PUSH, pragmas), false) else: STRINGS_EMPTY

func renderPop*(): string =
  renderPragmas(CODEGEN_POP, false)
