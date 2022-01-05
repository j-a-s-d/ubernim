# ubernim / CORE #
#----------------#

import
  rodster, xam, preprod,
  errors,
  language / [header, state]

reexport(rendering, rendering)

var
  preprocessPerformer*: DoubleArgsProc[string, LanguageState, var PreprodState]
  compilerInvoker*: DoubleArgsProc[string, StringSeq, int]
  errorHandler*: SingleArgVoidProc[string]

# CONSTANTS

const
  NIMC_DEFINES_KEY* = "NIMC_DEFINES"
  NIMC_SWITCHES_KEY* = "NIMC_SWITCHES"
  NIMC_CFGFILE_KEY* = "NIMC_CFGFILE"
  NIMC_PROJECT_KEY* = "NIMC_PROJECT"
  NIMC_INVOKATION* = "nim c"
  NIMC_DEFINE* = "--define:"

func validateDivision*(ls: LanguageState, d: LanguageDivision): PreprodResult =
  result = OK
  # check extensions to exist and be of the same type -- redundant?
  var m: LanguageDivision = nil
  if hasContent(d.extends):
    m = ls.getDivision(d.extends)
    if not assigned(m):
      return errors.UNDEFINED_REFERENCE(apostrophe(d.extends))
    else:
      while assigned(m):
        if m.kind != d.kind:
          return BAD("the referred " & apostrophe(d.extends) & " is not of the same type as " & apostrophe(d.name))
        m = ls.getDivision(m.extends)
  # check inherited classes not to imply the same classes -- redundant?
  m = d
  var s = newStringSeq()
  while assigned(m):
    if hasContent(m.implies):
      if m.implies notin s:
        s.add(m.implies)
      else:
        return BAD("an ancestor class of " & apostrophe(d.name) & " implies " & apostrophe(m.implies) & " which is already implied")
    m = ls.getDivision(m.extends)
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
    m = ls.getDivision(m.extends)
  m = d
  while assigned(m):
    m.applies.each a:
      let p = ls.getDivision(a)
      if not assigned(p):
        return errors.UNDEFINED_REFERENCE(apostrophe(a))
      else:
        p.members.each b:
          if not isPresent(b):
            return BAD("the member " & apostrophe(b.name) & " from " & apostrophe(a) & " is not present in " & apostrophe(m.name))
    m = ls.getDivision(m.extends)

func renderDivision*(ls: LanguageState, d: LanguageDivision): string =
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
      m = ls.getDivision(m.implies)
  case d.kind:
  of DIVISIONS_CLASS:
    var typedef = CODEGEN_REF & STRINGS_SPACE & CODEGEN_OBJECT
    if hasContent(d.extends):
      typedef &= STRINGS_SPACE & CODEGEN_OF & STRINGS_SPACE & d.extends
    elif ls.isDivisionInherited(d.name):
      typedef &= STRINGS_SPACE & CODEGEN_OF & STRINGS_SPACE & CODEGEN_ROOTOBJ
    return renderType(renderId(d.name, d.public, d.generics), renderPragmas(d.pragmas), typedef) & renderDocs(d.docs) & buildFields(CODEGEN_INDENT, true) & STRINGS_EOL
  of DIVISIONS_RECORD:
    return renderType(renderId(d.name, d.public, d.generics), renderPragmas(d.pragmas), CODEGEN_TUPLE) & renderDocs(d.docs) & buildFields(CODEGEN_INDENT, false) & STRINGS_EOL
  else:
    return STRINGS_EMPTY

let compilationPerformer* = proc (state: var PreprodState): int =
  result = low(int)
  # setup defines
  var clDefs = newStringSeq()
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      clDefs.add(NIMC_DEFINE & define)
  # setup switches
  var nimcSwitches = newStringSeq()
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    nimcSwitches = state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY)
  # emit config and compile
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    let ls = loadLanguageState(state)
    let cfg = state.getPropertyValue(NIMC_CFGFILE_KEY)
    if not writeToFile(cfg, lined(spaced(STRINGS_NUMERAL, cfg, ls.signature) & nimcSwitches)):
      errorHandler(errors.CANT_WRITE_CONFIG.output)
  else:
    clDefs &= nimcSwitches
  return compilerInvoker(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)
