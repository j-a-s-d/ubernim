# ubernim / LANGUAGE FEATURE #
#----------------------------#

import
  xam, preprod,
  commands,
  ../errors, ../rendering, ../constants, ../status,
  ../language / [header, member, division]

use strutils,strip
use strutils,join
use strutils,split
use strutils,toLower

# DIVISION

func validateDivision(ls: UbernimStatus, d: LanguageDivision): PreprodResult =
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

func renderDivision(ls: UbernimStatus, d: LanguageDivision): string =
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

proc startDivision(state: var PreprodState, division, subdivision, id: string): PreprodResult =
  if state.isPreviewing():
    let ls = loadUbernimStatus(state)
    if ls.hasDivision(id):
      return errors.ALREADY_DEFINED(apostrophe(id))
  state.setPropertyValue(KEY_DIVISION, division)
  state.setPropertyValue(KEY_SUBDIVISION, subdivision)
  openDivision(state, division, id)
  return OK

# CALLBACKS

topCallback doProtocol:
  return startDivision(state, DIVISIONS_PROTOCOL, SUBDIVISIONS_CLAUSES, parameters[0])

topCallback doInterface:
  return startDivision(state, DIVISIONS_INTERFACE, SUBDIVISIONS_CLAUSES, parameters[0])

topCallback doCompound:
  return startDivision(state, DIVISIONS_COMPOUND, SUBDIVISIONS_CLAUSES, parameters[0])

topCallback doClass:
  result = startDivision(state, DIVISIONS_CLASS, SUBDIVISIONS_CLAUSES, parameters.join(STRINGS_SPACE))
  if result.ok and state.isTranslating():
    let ls = loadUbernimStatus(state)
    let p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let v = ls.validateDivision(p)
    if not v.ok:
      return v
    let rc = ls.renderDivision(p)
    if hasContent(rc):
      state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EMPTY)
    result.output = rc

topCallback doRecord:
  result = startDivision(state, DIVISIONS_RECORD, SUBDIVISIONS_CLAUSES, parameters[0])
  if result.ok and state.isTranslating():
    let ls = loadUbernimStatus(state)
    let p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let v = ls.validateDivision(p)
    if not v.ok:
      return v
    let rc = ls.renderDivision(p)
    if hasContent(rc):
      state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EMPTY)
    result.output = rc

childCallback doApplies:
  if state.isPreviewing():
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let ld = ls.getDivision(parameters[0])
    if not assigned(ld):
      return errors.UNDEFINED_REFERENCE(apostrophe(parameters[0]))
    if ld.kind notin DIVISIONS_ON_APPLY:
      return errors.NOT_APPLICABLE
    if parameters[0] in p.applies:
      return errors.ALREADY_APPLYING(apostrophe(parameters[0]))
    p.applies.add(parameters[0])
  return OK

childCallback doImplies:
  if state.isPreviewing():
    let d = state.getPropertyValue(KEY_DIVISION)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let ld = ls.getDivision(parameters[0])
    if not assigned(ld):
      return errors.UNDEFINED_REFERENCE(apostrophe(parameters[0]))
    if ld.kind != d:
      return errors.NOT_IMPLIABLE
    if hasContent(p.implies):
      return errors.ALREADY_IMPLYING(apostrophe(p.implies))
    p.implies = parameters[0]
  return OK

childCallback doExtends:
  if state.isPreviewing():
    let d = state.getPropertyValue(KEY_DIVISION)
    if d == DIVISIONS_RECORD:
      return errors.RECORDS_CANT_EXTEND
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    if hasContent(p.extends):
      return errors.ALREADY_EXTENDING(apostrophe(p.extends))
    let x = ls.getDivision(parameters[0])
    if not assigned(x):
      return errors.CANT_EXTEND_INEXISTENT(apostrophe(parameters[0]))
    if x.data_sealed:
      return errors.CANT_EXTEND_SEALED(apostrophe(parameters[0]))
    p.extends = parameters[0]
  return OK

childCallback doPragmas:
  let d = state.getPropertyValue(KEY_DIVISION)
  if state.isPreviewing():
    if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE:
      if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
        return errors.CANT_HAVE_PRAGMAS
      let ls = loadUbernimStatus(state)
      var p = ls.getDivision(ls.language.currentName)
      if not assigned(p):
        return errors.BAD_STATE
      if hasContent(p.pragmas):
        return errors.ALREADY_DEFINED(WORDS_PRAGMAS)
      p.pragmas = spaced(parameters)
  elif state.isTranslating():
    if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
      if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE:
        return errors.CANT_HAVE_PRAGMAS
      let ls = loadUbernimStatus(state)
      var p = ls.getDivision(ls.language.currentName)
      if not assigned(p):
        return errors.BAD_STATE
      if hasContent(ls.language.currentImplementation.pragmas):
        return errors.ALREADY_DEFINED(WORDS_PRAGMAS)
      ls.language.currentImplementation.pragmas = spaced(parameters)
  return OK

childCallback doFields:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_FIELDS:
    return errors.CANT_HAVE_FIELDS
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_FIELDS)
  return OK

childCallback doMethods:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_METHODS:
    return errors.CANT_HAVE_METHODS
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_METHODS)
  return OK

childCallback doTemplates:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_TEMPLATES:
    return errors.CANT_HAVE_TEMPLATES
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_TEMPLATES)
  return OK

childCallback doDocs:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_DOCS:
    return errors.CANT_OUTPUT_DOCS
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_DOCS)
  return OK

topCallback doNote:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_NOTE)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_BODY)
  return OK

topCallback doImports:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_IMPORTS)
  state.setPropertyValue(KEY_SUBDIVISION, STRINGS_EMPTY)
  return OK

topCallback doExports:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_EXPORTS)
  state.setPropertyValue(KEY_SUBDIVISION, STRINGS_EMPTY)
  return OK

topCallback doConstructor:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_CONSTRUCTOR)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_CONSTRUCTOR)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_METHODS)
    if not lm.read(STRINGS_PLUS & parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_CONSTRUCTOR)
    if not ls.hasMethod(p, lm.name):
      return errors.NEVER_DEFINED(spaced(WORDS_CONSTRUCTOR, apostrophe(parts[1])))
    let pm = ls.getMember(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_CONSTRUCTOR, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    ls.language.currentName = p.name
    ls.language.currentImplementation = lm
  return OK

topCallback doGetter:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_GETTER)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_GETTER)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_METHODS)
    # NOTE: due to the differences between definition and implementation special flag has to be set
    lm.data_getter = true # before reading (for the getter)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_GETTER)
    if not isValidNimIdentifier(lm.name):
      return errors.INVALID_IDENTIFIER
    if not ls.hasMethod(p, lm.name, (member: LanguageMember) => member.data_getter):
      return errors.NEVER_DEFINED(spaced(WORDS_GETTER, apostrophe(parts[1])))
    let pm = ls.getMember(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_GETTER, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    ls.language.currentName = p.name
    ls.language.currentImplementation = lm
  return OK

topCallback doSetter:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_SETTER)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let isVar = parameters[0] == CODEGEN_VAR
    let parts = (if isVar: parameters[1..^1] else: parameters).join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_SETTER)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_METHODS)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_SETTER)
    # NOTE: due to the differences between definition and implementation special flag has to be set
    lm.data_setter = true # after reading (for the setter)
    if not isValidNimIdentifier(lm.name):
      return errors.INVALID_IDENTIFIER
    if not ls.hasMethod(p, lm.name, (member: LanguageMember) => member.data_setter):
      return errors.NEVER_DEFINED(spaced(WORDS_SETTER, apostrophe(parts[1])))
    let pm = ls.getMember(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_SETTER, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    ls.language.currentName = p.name
    lm.data_var = isVar
    ls.language.currentImplementation = lm
  return OK

topCallback doMethod:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_METHOD)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let isVar = parameters[0] == CODEGEN_VAR
    let parts = (if isVar: parameters[1..^1] else: parameters).join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_METHOD)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_METHODS)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_METHOD)
    if not ls.hasMethod(p, lm.name):
      return errors.NEVER_DEFINED(spaced(WORDS_METHOD, apostrophe(parts[1])))
    let pm = ls.getMember(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_METHOD, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    ls.language.currentName = p.name
    lm.data_var = isVar
    ls.language.currentImplementation = lm
  return OK

topCallback doTemplate:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_TEMPLATE)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_TEMPLATE)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_TEMPLATES)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_TEMPLATE)
    if not ls.hasTemplate(p, lm.name):
      return errors.NEVER_DEFINED(spaced(WORDS_TEMPLATE, apostrophe(parts[1])))
    let pm = ls.getMember(p, SUBDIVISIONS_TEMPLATES, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_TEMPLATE, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    ls.language.currentName = p.name
    ls.language.currentImplementation = lm
  return OK

topCallback doRoutine:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_ROUTINE)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let full = parameters.join(STRINGS_SPACE)
    let parts = full.split(STRINGS_PERIOD)
    if parts.len == 2:
      return errors.WRONGLY_DEFINED(WORDS_ROUTINE)
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(SCOPE_GLOBAL)
    if not assigned(p):
      return errors.BAD_STATE
    var lm = newLanguageMember(SUBDIVISIONS_TEMPLATES)
    if not lm.read(full):
      return errors.WRONGLY_DEFINED(WORDS_ROUTINE)
    if ls.hasMethod(p, lm.name):
      return errors.ALREADY_DEFINED(spaced(WORDS_ROUTINE, apostrophe(full)))
    ls.language.currentName = p.name
    ls.language.currentImplementation = lm
  return OK

childCallback doCode:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_CODE:
    return errors.CANT_OUTPUT_CODE
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_BODY)
  if state.isTranslating():
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let lc = p.kind == DIVISIONS_CLASS
    let lp = p.extends
    let ln = ls.language.currentName
    let lm = ls.language.currentImplementation
    lm.rendered = true
    if d == DIVISIONS_CONSTRUCTOR:
      return GOOD(renderUses(lm.uses) & renderConstructorBegin(lm, lc, ln))
    elif d == DIVISIONS_METHOD or d == DIVISIONS_GETTER or d == DIVISIONS_SETTER:
      return GOOD(renderUses(lm.uses) & renderMethodBegin(lm, lc, ln, lp))
    elif d == DIVISIONS_TEMPLATE:
      return GOOD(renderUses(lm.uses) & renderTemplateBegin(lm, ln))
    else: # if d == DIVISIONS_ROUTINE:
      return GOOD(renderUses(lm.uses) & renderRoutineBegin(lm))
  return OK

childCallback doUses:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_CODE:
    return errors.CANT_OUTPUT_CODE
  if state.isTranslating():
    let ls = loadUbernimStatus(state)
    var p = ls.getDivision(ls.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    if not assigned(ls.language.currentImplementation):
      return errors.BAD_STATE
    let once = state.getPropertyValue(UNIM_IMPORTING_KEY) == FREQUENCY_ONCE
    parameters.join(STRINGS_SPACE).split(STRINGS_COMMA).each u:
      let lu = strip(u)
      if lu notin ls.files.imported:
        ls.files.imported.add(lu)
      elif once:
        continue
      ls.language.currentImplementation.uses.add(lu)
  return OK

childCallback doEnd:
  let d = state.getPropertyValue(KEY_DIVISION)
  state.removePropertyValue(KEY_SUBDIVISION)
  state.removePropertyValue(KEY_DIVISION)
  let ls = loadUbernimStatus(state)
  var p = ls.getDivision(ls.language.currentName)
  let lc = assigned(p) and p.kind == DIVISIONS_CLASS
  let lp = if lc: p.extends else: STRINGS_EMPTY
  let ln = ls.language.currentName
  let lm = ls.language.currentImplementation
  closeDivision(state)
  if state.isTranslating():
    if d == DIVISIONS_CONSTRUCTOR:
      let p = if lm.rendered: STRINGS_EMPTY else: renderUses(lm.uses) & renderConstructorBegin(lm, lc, ln) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderConstructorEnd())
    elif d == DIVISIONS_GETTER or d == DIVISIONS_SETTER or d == DIVISIONS_METHOD:
      let p = if lm.rendered: STRINGS_EMPTY else: renderUses(lm.uses) & renderMethodBegin(lm, lc, ln, lp) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderMethodEnd())
    elif d == DIVISIONS_TEMPLATE:
      let p = if lm.rendered: STRINGS_EMPTY else: renderUses(lm.uses) & renderTemplateBegin(lm, ln) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderTemplateEnd())
    elif d == DIVISIONS_ROUTINE:
      let p = if lm.rendered: STRINGS_EMPTY else: renderUses(lm.uses) & renderRoutineBegin(lm) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderRoutineEnd())
    elif d == DIVISIONS_NOTE or d == DIVISIONS_IMPORTS or d == DIVISIONS_EXPORTS:
      return GOOD(STRINGS_EOL)
  return OK

topCallback doPush:
  if state.isTranslating():
    return GOOD(STRINGS_EOL & renderPush(spaced(parameters)))
  return OK

topCallback doPop:
  if state.isTranslating():
    return GOOD(renderPop() & STRINGS_EOL)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "LANGUAGE":
    cmd("note", PreprodArguments.uaNone, doNote)
    cmd("imports", PreprodArguments.uaNone, doImports)
    cmd("exports", PreprodArguments.uaNone, doExports)
    cmd("push", PreprodArguments.uaNonZero, doPush)
    cmd("pop", PreprodArguments.uaNone, doPop)
    cmd("pragmas", PreprodArguments.uaNonZero, doPragmas)
    cmd("class", PreprodArguments.uaNonZero, doClass)
    cmd("record", PreprodArguments.uaOne, doRecord)
    cmd("compound", PreprodArguments.uaOne, doCompound)
    cmd("interface", PreprodArguments.uaOne, doInterface)
    cmd("protocol", PreprodArguments.uaOne, doProtocol)
    cmd("applies", PreprodArguments.uaOne, doApplies)
    cmd("implies", PreprodArguments.uaOne, doImplies)
    cmd("extends", PreprodArguments.uaOne, doExtends)
    cmd("fields", PreprodArguments.uaNone, doFields)
    cmd("methods", PreprodArguments.uaNone, doMethods)
    cmd("templates", PreprodArguments.uaNone, doTemplates)
    cmd("docs", PreprodArguments.uaNone, doDocs)
    cmd("constructor", PreprodArguments.uaNonZero, doConstructor)
    cmd("getter", PreprodArguments.uaNonZero, doGetter)
    cmd("setter", PreprodArguments.uaNonZero, doSetter)
    cmd("method", PreprodArguments.uaNonZero, doMethod)
    cmd("template", PreprodArguments.uaNonZero, doTemplate)
    cmd("routine", PreprodArguments.uaNonZero, doRoutine)
    cmd("code", PreprodArguments.uaNone, doCode)
    cmd("uses", PreprodArguments.uaNonZero, doUses)
    cmd("end", PreprodArguments.uaNone, doEnd)