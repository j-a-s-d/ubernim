# ubernim / CORE #
#----------------#

import
  xam, preprod

reexport(strutils, strutils)
reexport(rendering, rendering)

use sequtils,filterIt

# CONSTANTS

const
  FEATURE_SWITCHES* = "SWITCHES" # nim compiler command line switches
  FEATURE_SHELLCMD* = "SHELLCMD" # os shell commands execution
  FEATURE_FSACCESS* = "FSACCESS" # os filesystem access
  FEATURE_REQUIRES* = "REQUIRES" # ubernim external files requirement (differs from INCLUDE in that the required modules are preprocessed separatelly)
  FEATURE_LANGUAGE* = "LANGUAGE" # ubernim language extensions
  NIMC_DEFINES_KEY* = "NIMC_DEFINES"
  NIMC_SWITCHES_KEY* = "NIMC_SWITCHES"
  NIMC_CFGFILE_KEY* = "NIMC_CFGFILE"
  NIMC_PROJECT_KEY* = "NIMC_PROJECT"
  NIM_COMPILE* = "nim c"
  NIM_DEFINE* = "--define:"
  NIMLANG_NOSIDEEFFECT = "noSideEffect"

# TEMPLATES

template lined*(strings: varargs[string]): string =
  strings.join(STRINGS_EOL)

template spaced*(strings: varargs[string]): string =
  strings.join(STRINGS_SPACE)

# LANGUAGE

const
  KEY_DIVISION* = "DIVISION"
  KEY_SUBDIVISION* = "SUBDIVISION"
  SCOPE_GLOBAL* = "<GLOBAL>"
  DIVISIONS_NOTE* = "NOTE"
  DIVISIONS_COMPOUND* = "COMPOUND"
  DIVISIONS_INTERFACE* = "INTERFACE"
  DIVISIONS_PROTOCOL* = "PROTOCOL"
  DIVISIONS_RECORD* = "RECORD"
  DIVISIONS_CLASS* = "CLASS"
  DIVISIONS_CONSTRUCTOR* = "CONSTRUCTOR" # implementation
  DIVISIONS_METHOD* = "METHOD" # implementation
  DIVISIONS_TEMPLATE* = "TEMPLATE" # implementation
  DIVISIONS_ROUTINES* = "ROUTINES" # global
  DIVISIONS_ROUTINE* = "ROUTINE" # implementation
  DIVISIONS_WITH_CODE* = [DIVISIONS_CONSTRUCTOR, DIVISIONS_METHOD, DIVISIONS_TEMPLATE, DIVISIONS_ROUTINE]
  DIVISIONS_WITH_FIELDS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL, DIVISIONS_COMPOUND]
  DIVISIONS_WITH_METHODS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL, DIVISIONS_INTERFACE]
  DIVISIONS_WITH_TEMPLATES* = [DIVISIONS_CLASS, DIVISIONS_RECORD]
  DIVISIONS_WITH_DOCS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_CONSTRUCTOR, DIVISIONS_METHOD, DIVISIONS_TEMPLATE, DIVISIONS_ROUTINE]
  SUBDIVISIONS_BODY* = "BODY" # implementation
  SUBDIVISIONS_DOCS* = "DOCS"
  SUBDIVISIONS_CLAUSES* = "CLAUSES" # where attribute clauses can appear (ex. extends, applies, etc)
  SUBDIVISIONS_FIELDS* = "FIELDS"
  SUBDIVISIONS_METHODS* = "METHODS"
  SUBDIVISIONS_TEMPLATES* = "TEMPLATES"

type
  LanguageMember* = ref object of RootObj
    #line*: string
    kind*: string
    name*: string
    public*: bool
    imported*: bool
    generics*: string
    data_type*: string # methods: return type & fields: value type
    data_extra*: string # methods: parameters & class fields: initialization value
    data_constructor*: bool # methods: constructor flag & fields: unused
    data_sealed*: bool # class and methods: sealed flag & fields: unused
    pragmas*: string
    docs*: StringSeq
    rendered*: bool

  LanguageMembers* = seq[LanguageMember]

  LanguageDivision* = ref object of LanguageMember
    applies*: StringSeq
    implies*: string
    extends*: string
    members*: LanguageMembers

  LanguageDivisions* = seq[LanguageDivision]

  TLanguageState* = object of PreprodTag
    version*: string
    unit*: string
    currentName*: string
    currentKind*: string
    currentImplementation*: LanguageMember
    divisions*: LanguageDivisions
  LanguageState* = ptr TLanguageState

# STATE

template makeLanguageState*(): LanguageState =
  var ads = TLanguageState(
    version: STRINGS_EMPTY,
    unit: STRINGS_EMPTY,
    currentName: STRINGS_EMPTY,
    currentKind: STRINGS_EMPTY,
    currentImplementation: nil,
    divisions: @[newLanguageDivision(DIVISIONS_ROUTINES, SCOPE_GLOBAL)]
  )
  addr(ads)

template loadLanguageState*(state: var PreprodState): LanguageState =
  cast[LanguageState](state.tag)

template storeLanguageState*(state: var PreprodState, langState: LanguageState) =
  state.tag = addr(langState[])

template freeLanguageState*(state: var PreprodState) =
  if assigned(state.tag):
    reset(state.tag)

# MEMBER

func `$`*(mbr: LanguageMember): string =
  bracketize([
    #"line: " & quote(mbr.line),
    "kind: " & quote(mbr.kind),
    "name: " & quote(mbr.name),
    "public: " & $mbr.public,
    "imported: " & $mbr.imported,
    "data_type: " & quote(mbr.data_type),
    "data_extra: " & quote(mbr.data_extra),
    "data_constructor: " & $mbr.data_constructor,
    "data_sealed: " & $mbr.data_sealed,
    "generics: " & $mbr.generics,
    "pragmas: " & $mbr.pragmas,
    "docs: " & $mbr.docs,
    "rendered: " & $mbr.rendered
  ].join(STRINGS_COMMA & STRINGS_SPACE))

func setupItem(item: LanguageMember, name: string) =
  item.public = name.endsWith(STRINGS_ASTERISK)
  item.name = if item.public: dropRight(name, 1) else: name
  if item.name.find(STRINGS_BRACKETS_OPEN) > -1 and item.name.find(STRINGS_BRACKETS_CLOSE) > -1:
    let parts = item.name.split(STRINGS_BRACKETS_OPEN)
    item.name = parts[0]
    item.generics = parts[1].replace(STRINGS_BRACKETS_CLOSE, STRINGS_EMPTY)
  else:
    item.generics = STRINGS_EMPTY

proc readField(fld: LanguageMember, line: string): bool =
  result = true
  let lp = line.split(STRINGS_COLON)
  if lp.len != 2:
    return false
  let n = strip(lp[0])
  let t = strip(lp[1])
  if not haveContent(n, t) or t.find(STRINGS_EQUAL) != -1:
    return false
  fld.setupItem(n)
  if fld.kind == DIVISIONS_RECORD and fld.public:
    return false
  fld.data_type = t

proc readMethod(mtd: LanguageMember, line: string): bool =
  result = true
  if line.find(STRINGS_PARENTHESES_OPEN) == -1 or line.find(STRINGS_PARENTHESES_CLOSE) == -1:
    return false
  let x = line.split(STRINGS_PARENTHESES_OPEN)
  if x.len != 2:
    return false
  let m = strip(x[0])
  if not hasContent(m):
    return false
  let c = m.startsWith(STRINGS_PLUS)
  let f = m.startsWith(STRINGS_EXCLAMATION)
  let n = if c or f: dropLeft(m, 1) else: m
  let y = strip(x[1]).split(STRINGS_PARENTHESES_CLOSE)
  if y.len != 2:
    return false
  let a = y[0]
  let d = y[1]
  #if not c and (not hasContent(d) or d.find(STRINGS_COLON) == -1):
  #  return false
  let t = d.replace(STRINGS_COLON, STRINGS_EMPTY).replace(STRINGS_EQUAL, STRINGS_EMPTY).strip()
  #if (not c and not hasContent(t)): # or t.find(STRINGS_EQUAL) != -1:
  #  return false
  mtd.setupItem(n)
  mtd.data_type = t
  mtd.data_constructor = c
  mtd.data_sealed = f
  mtd.data_extra = a

proc read*(mbr: LanguageMember, line: string): bool =
  case mbr.kind:
  of SUBDIVISIONS_FIELDS:
    mbr.readField(line)
  of SUBDIVISIONS_METHODS:
    mbr.readMethod(line)
  of SUBDIVISIONS_TEMPLATES:
    mbr.readMethod(line)
  else:
    false

func newLanguageMember*(kind: string): LanguageMember =
  result = new LanguageMember
  result.kind = kind
  result.docs = @[]

# DIVISION

func newLanguageDivision*(kind: string, name: string): LanguageDivision =
  result = new LanguageDivision
  result.kind = kind
  result.data_sealed = kind == DIVISIONS_CLASS and name.startsWith(STRINGS_EXCLAMATION)
  let n = if result.data_sealed: dropLeft(name, 1) else: name
  result.setupItem(n)
  result.members = @[]

func getDivision*(langState: LanguageState, name: string): LanguageDivision =
  let l = name.strip()
  let m = if l.endsWith(STRINGS_ASTERISK): dropRight(l, 1) else: l
  let n = if m.startsWith(STRINGS_EXCLAMATION): dropLeft(m, 1) else: m
  langState.divisions.each p:
    if p.name == n:
      return p
  return nil

func openDivision*(state: var PreprodState, kind: string, name: string) =
  let ls = loadLanguageState(state)
  var item = LanguageMember()
  item.setupItem(name)
  let p = ls.getDivision(item.name)
  if not assigned(p):
    ls.divisions.add(newLanguageDivision(kind, name))
  ls.currentName = item.name
  ls.currentKind = kind
  ls.currentImplementation = nil

func closeDivision*(state: var PreprodState) =
  let ls = loadLanguageState(state)
  ls.currentName = STRINGS_EMPTY
  ls.currentKind = STRINGS_EMPTY
  ls.currentImplementation = nil

const DUMMY_EXAMINER = proc (member: LanguageMember): bool = true

proc getMember*(ls: LanguageState, d: LanguageDivision, kind, name: string): LanguageMember =
  var m = d
  while assigned(m):
    m.members.each f:
      if f.kind == kind and f.name == name:
        return f
    m = ls.getDivision(m.extends)
  return nil

proc hasMember*(ls: LanguageState, d: LanguageDivision, kind, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  var m = d
  while assigned(m):
    m.members.each f:
      if f.kind == kind and f.name == name:
        return examiner(f)
    m = ls.getDivision(m.extends)
  return false

proc hasField*(ls: LanguageState, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_FIELDS, name, examiner)

proc hasMethod*(ls: LanguageState, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_METHODS, name, examiner)

proc hasTemplate*(ls: LanguageState, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_TEMPLATES, name, examiner)

func isDivisionInherited*(langState: LanguageState, name: string): bool =
  langState.divisions.each p:
    if p.extends == name:
      return true
  return false

func validateDivision*(langState: LanguageState, d: LanguageDivision): PreprodResult =
  result = OK
  # check extensions to exist and be of the same type
  var m: LanguageDivision = nil
  if hasContent(d.extends):
    m = langState.getDivision(d.extends)
    if not assigned(m):
      return BAD("the referred " & apostrophe(d.extends) & " is undefined")
    else:
      while assigned(m):
        if m.kind != d.kind:
          return BAD("the referred " & apostrophe(d.extends) & " is not of the same type as " & apostrophe(d.name))
        m = langState.getDivision(m.extends)
  # check inherited classes not to imply the same classes
  m = d
  var s = newStringSeq()
  while assigned(m):
    if hasContent(m.implies):
      if m.implies notin s:
        s.add(m.implies)
      else:
        return BAD("an ancestor class of " & apostrophe(d.name) & " implies " & apostrophe(m.implies) & " which is already implied")
    m = langState.getDivision(m.extends)
  # check for the presence of the applies against the fields of own division, from implies and from extensions
  m = d
  var r: LanguageMembers = @[]
  func isPresent(b: LanguageMember): bool =
    result = false
    r.each x:
      result = x.name == b.name and x.kind == b.kind and x.data_type == b.data_type# and x.public == b.public
      if result:
        break
  while assigned(m):
    m.members.each b:
      r.add(b)
    m = langState.getDivision(m.extends)
  m = d
  while assigned(m):
    m.applies.each a:
      let p = langState.getDivision(a)
      if not assigned(p):
        return BAD("the referred " & apostrophe(a) & " is undefined")
      else:
        p.members.each b:
          if not isPresent(b):
            return BAD("the member " & apostrophe(b.name) & " from " & apostrophe(a) & " is not present in " & apostrophe(m.name))
    m = langState.getDivision(m.extends)

func renderDivision*(langState: LanguageState, d: LanguageDivision): string =
  func buildFields(indent: string, allowVisibility: bool): string =
    func writeFields(members: LanguageMembers): string =
      result = STRINGS_EMPTY
      members.each f:
        if f.kind == SUBDIVISIONS_FIELDS:
          let v = if allowVisibility and f.public: STRINGS_ASTERISK else: STRINGS_EMPTY
          result &= STRINGS_EOL & indent & f.name & v & STRINGS_COLON & STRINGS_SPACE & f.data_type
    result = STRINGS_EMPTY
    var m = d
    while assigned(m):
      result &= writeFields(m.members)
      m = langState.getDivision(m.implies)
  case d.kind:
  of DIVISIONS_CLASS:
    var typedef = CODEGEN_REF & STRINGS_SPACE & CODEGEN_OBJECT
    if hasContent(d.extends):
      typedef &= STRINGS_SPACE & CODEGEN_OF & STRINGS_SPACE & d.extends
    elif langState.isDivisionInherited(d.name):
      typedef &= STRINGS_SPACE & CODEGEN_OF & STRINGS_SPACE & CODEGEN_ROOTOBJ
    return renderType(renderId(d.name, d.public, d.generics), renderPragmas(d.pragmas.strip()), typedef) & renderDocs(d.docs) & buildFields(CODEGEN_INDENT, true) & STRINGS_EOL
  of DIVISIONS_RECORD:
    return renderType(renderId(d.name, d.public, d.generics), renderPragmas(d.pragmas.strip()), CODEGEN_TUPLE) & renderDocs(d.docs) & buildFields(CODEGEN_INDENT, false) & STRINGS_EOL
  else:
    return STRINGS_EMPTY

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

# GLOBALS

var
  preprocess*: DoubleArgsProc[string, LanguageState, var PreprodState]
  postprocess*: SingleArgProc[var PreprodState, int]
  previewer*: PreprodPreviewer
  translater*: PreprodTranslater
  options*: PreprodOptions = PREPROD_DEFAULT_OPTIONS
  commands*: PreprodCommands = @[]
