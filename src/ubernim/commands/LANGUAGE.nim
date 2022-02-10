# ubernim / LANGUAGE FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../errors, ../rendering, ../constants, ../status,
  ../language / [header, implementation]

use strutils,strip
use strutils,join
use strutils,split
use strutils,toLower

# DIVISION

func getFullDivisionItems(status: UbernimStatus, p: LanguageDivision): LanguageItems =
  result = p.items
  if hasContent(p.extends):
    result.add(getFullDivisionItems(status, status.getDivision(p.extends)))
  p.applies.each u:
    result.add(getFullDivisionItems(status, status.getDivision(u)))

proc validateDivision*(status: UbernimStatus, d: LanguageDivision): PreprodResult =
  result = OK
  # check for the presence of the applies against the fields of own division, from implies and from extensions
  var m: LanguageDivision = d
  var r: LanguageItems = @[]
  proc isPresent(applyingItem: LanguageItem): bool =
    result = false
    r.each x:
      let kok = applyingItem.kind == x.kind or
        (applyingItem.kind == SUBDIVISIONS_FIELDS and x.kind == SUBDIVISIONS_MEMBERS) or
        (applyingItem.kind == SUBDIVISIONS_METHODS and x.kind == SUBDIVISIONS_ROUTINES)
      result = x.name == applyingItem.name and kok and x.data_type == applyingItem.data_type# and x.public == applyingItem.public
      if result:
        break
  while assigned(m):
    m.items.each b:
      r.add(b)
    m = status.getDivision(m.extends)
  m = d
  while assigned(m):
    m.applies.each a:
      let p = status.getDivision(a)
      if not assigned(p):
        return errors.UNDEFINED_REFERENCE(apostrophe(a))
      else:
        status.getFullDivisionItems(p).each b:
          if not isPresent(b):
            return BAD(spaced(WORDS_MISSING, apostrophe(b.name), WORDS_FROM, apostrophe(a), WORDS_AT, apostrophe(status.getCurrentFile())))
    m = status.getDivision(m.extends)

func renderDivision(status: UbernimStatus, d: LanguageDivision): string =
  func buildFields(indent: string, allowVisibility: bool): string =
    func writeFields(items: LanguageItems): string =
      result = STRINGS_EMPTY
      items.each f:
        if f.kind == SUBDIVISIONS_FIELDS:
          let v = if allowVisibility and f.public: STRINGS_ASTERISK else: STRINGS_EMPTY
          result &= STRINGS_EOL & indent & f.name & v & STRINGS_COLON & STRINGS_SPACE & f.data_type
    result = writeFields(d.items)
  case d.kind:
  of DIVISIONS_CLASS:
    var typedef = CODEGEN_REF & STRINGS_SPACE & CODEGEN_OBJECT
    if hasContent(d.extends):
      typedef &= STRINGS_SPACE & CODEGEN_OF & STRINGS_SPACE & d.extends
    elif status.isDivisionInherited(d.name):
      typedef &= STRINGS_SPACE & CODEGEN_OF & STRINGS_SPACE & CODEGEN_ROOTOBJ
    return renderType(renderId(d.name, d.public, d.generics), renderPragmas(d.pragmas), typedef) & renderDocs(d.docs) & buildFields(CODEGEN_INDENT, true) & STRINGS_EOL
  of DIVISIONS_RECORD:
    return renderType(renderId(d.name, d.public, d.generics), renderPragmas(d.pragmas), CODEGEN_TUPLE) & renderDocs(d.docs) & buildFields(CODEGEN_INDENT, false) & STRINGS_EOL
  else:
    return STRINGS_EMPTY

proc startDivision(state: var PreprodState, division, subdivision, id: string): PreprodResult =
  if state.isPreviewing():
    let status = loadUbernimStatus(state)
    if status.hasDivision(id):
      return errors.ALREADY_DEFINED(apostrophe(id))
  setDivision(state, division)
  setSubdivision(state, subdivision)
  let lm = openDivision(state, division, id)
  if not lm.hasValidIdentifier():
    return errors.INVALID_IDENTIFIER
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
    let status = loadUbernimStatus(state)
    let p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let v = status.validateDivision(p)
    if not v.ok:
      return v
    let rc = status.renderDivision(p)
    if hasContent(rc):
      state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EMPTY)
    result.output = rc

topCallback doRecord:
  result = startDivision(state, DIVISIONS_RECORD, SUBDIVISIONS_CLAUSES, parameters[0])
  if result.ok and state.isTranslating():
    let status = loadUbernimStatus(state)
    let p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let v = status.validateDivision(p)
    if not v.ok:
      return v
    let rc = status.renderDivision(p)
    if hasContent(rc):
      state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EMPTY)
    result.output = rc

childCallback doApplies:
  if state.isPreviewing():
    let status = loadUbernimStatus(state)
    var p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let ld = status.getDivision(parameters[0])
    if not assigned(ld):
      return errors.UNDEFINED_REFERENCE(apostrophe(parameters[0]))
    if ld.kind notin DIVISIONS_ON_APPLY:
      return errors.NOT_APPLIABLE
    if parameters[0] in p.applies:
      return errors.ALREADY_APPLYING(apostrophe(parameters[0]))
    p.applies.add(parameters[0])
  return OK

childCallback doExtends:
  if state.isPreviewing():
    let d = fetchDivision(state)
    if d == DIVISIONS_RECORD:
      return errors.RECORDS_CANT_EXTEND
    let status = loadUbernimStatus(state)
    var p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    if hasContent(p.extends):
      return errors.ALREADY_EXTENDING(apostrophe(p.extends))
    if parameters[0] != CODEGEN_ROOTOBJ:
      let x = status.getDivision(parameters[0])
      if not assigned(x):
        return errors.CANT_EXTEND_INEXISTENT(apostrophe(parameters[0]))
      if p.kind != x.kind:
        return errors.CANT_EXTEND_DIFFERENT
      if x.data_sealed:
        return errors.CANT_EXTEND_SEALED(apostrophe(parameters[0]))
    p.extends = parameters[0]
  return OK

childCallback doPragmas:
  let d = fetchDivision(state)
  if state.isPreviewing():
    if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE and d != DIVISIONS_MEMBER:
      if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
        return errors.CANT_HOLD_PRAGMAS
      let status = loadUbernimStatus(state)
      var p = status.getDivision(status.language.currentName)
      if not assigned(p):
        return errors.BAD_STATE
      if hasContent(p.pragmas):
        return errors.ALREADY_DEFINED(WORDS_PRAGMAS)
      p.pragmas = spaced(parameters)
  elif state.isTranslating():
    if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
      if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE and d != DIVISIONS_MEMBER:
        return errors.CANT_HOLD_PRAGMAS
      let status = loadUbernimStatus(state)
      var p = status.getDivision(status.language.currentName)
      if not assigned(p):
        return errors.BAD_STATE
      let lm = status.language.currentImplementation
      if lm.rendered:
        return errors.DEFINE_BEFORE_VALUE
      if hasContent(lm.pragmas):
        return errors.ALREADY_DEFINED(WORDS_PRAGMAS)
      lm.pragmas = spaced(parameters)
  return OK

childCallback doFields:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_FIELDS:
    return errors.CANT_HOLD_FIELDS
  setSubdivision(state, SUBDIVISIONS_FIELDS)
  return OK

childCallback doMethods:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_METHODS:
    return errors.CANT_HOLD_METHODS
  setSubdivision(state, SUBDIVISIONS_METHODS)
  return OK

childCallback doTemplates:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_TEMPLATES:
    return errors.CANT_HOLD_TEMPLATES
  setSubdivision(state, SUBDIVISIONS_TEMPLATES)
  return OK

topCallback doNote:
  setDivision(state, DIVISIONS_NOTE)
  setSubdivision(state, SUBDIVISIONS_BODY)
  return OK

topCallback doImports:
  setDivision(state, DIVISIONS_IMPORTS)
  setSubdivision(state, STRINGS_EMPTY)
  return OK

topCallback doExports:
  setDivision(state, DIVISIONS_EXPORTS)
  setSubdivision(state, STRINGS_EMPTY)
  return OK

topCallback doConstructor:
  setDivision(state, DIVISIONS_CONSTRUCTOR)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_CONSTRUCTOR)
    let status = loadUbernimStatus(state)
    var p = status.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageItem(SUBDIVISIONS_METHODS)
    if not lm.read(STRINGS_PLUS & parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_CONSTRUCTOR)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if not status.hasMethod(p, lm.name):
      return errors.NEVER_DEFINED(spaced(WORDS_CONSTRUCTOR, apostrophe(parts[1])))
    let pm = status.getItem(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_CONSTRUCTOR, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    status.language.currentName = p.name
    status.language.currentImplementation = lm
  return OK

topCallback doGetter:
  setDivision(state, DIVISIONS_GETTER)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_GETTER)
    let status = loadUbernimStatus(state)
    var p = status.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageItem(SUBDIVISIONS_METHODS)
    # NOTE: due to the differences between definition and implementation special flag has to be set
    lm.data_getter = true # before reading (for the getter)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_GETTER)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if not status.hasMethod(p, lm.name, (item: LanguageItem) => item.data_getter):
      return errors.NEVER_DEFINED(spaced(WORDS_GETTER, apostrophe(parts[1])))
    let pm = status.getItem(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_GETTER, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    status.language.currentName = p.name
    status.language.currentImplementation = lm
  return OK

topCallback doSetter:
  setDivision(state, DIVISIONS_SETTER)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let isVar = parameters[0] == CODEGEN_VAR
    let parts = (if isVar: parameters[1..^1] else: parameters).join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_SETTER)
    let status = loadUbernimStatus(state)
    var p = status.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageItem(SUBDIVISIONS_METHODS)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_SETTER)
    # NOTE: due to the differences between definition and implementation special flag has to be set
    lm.data_setter = true # after reading (for the setter)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if not status.hasMethod(p, lm.name, (item: LanguageItem) => item.data_setter):
      return errors.NEVER_DEFINED(spaced(WORDS_SETTER, apostrophe(parts[1])))
    let pm = status.getItem(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_SETTER, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    status.language.currentName = p.name
    lm.data_var = isVar
    status.language.currentImplementation = lm
  return OK

topCallback doMethod:
  setDivision(state, DIVISIONS_METHOD)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let isVar = parameters[0] == CODEGEN_VAR
    let parts = (if isVar: parameters[1..^1] else: parameters).join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_METHOD)
    let status = loadUbernimStatus(state)
    var p = status.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageItem(SUBDIVISIONS_METHODS)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_METHOD)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if not status.hasMethod(p, lm.name):
      return errors.NEVER_DEFINED(spaced(WORDS_METHOD, apostrophe(parts[1])))
    let pm = status.getItem(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return errors.BAD_STATE
    if pm.public != lm.public:
      return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_METHOD, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    status.language.currentName = p.name
    lm.data_var = isVar
    status.language.currentImplementation = lm
  return OK

topCallback doTemplate:
  setDivision(state, DIVISIONS_TEMPLATE)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    var parts = newStringSeq()
    let tmp = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if tmp.len != 2:
      parts.add(SCOPE_GLOBAL)
    parts.add(tmp)
    let status = loadUbernimStatus(state)
    var p = status.getDivision(parts[0])
    if not assigned(p):
      return errors.NEVER_DEFINED(apostrophe(parts[0]))
    var lm = newLanguageItem(SUBDIVISIONS_TEMPLATES)
    if not lm.read(parts[1]):
      return errors.WRONGLY_DEFINED(WORDS_TEMPLATE)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if parts[0] == SCOPE_GLOBAL:
      if status.hasTemplate(p, lm.name):
        return errors.ALREADY_DEFINED(spaced(WORDS_TEMPLATE, apostrophe(parts[1])))
      p.items.add(lm)
    else:
      if not status.hasTemplate(p, lm.name):
        return errors.NEVER_DEFINED(spaced(WORDS_TEMPLATE, apostrophe(parts[1])))
      let pm = status.getItem(p, SUBDIVISIONS_TEMPLATES, lm.name)
      if not assigned(pm):
        return errors.BAD_STATE
      if pm.public != lm.public:
        return errors.VISIBILITY_DOESNT_MATCH(spaced(WORDS_FOR, WORDS_TEMPLATE, apostrophe(lm.name & parenthesize(lm.data_extra)), WORDS_AT, apostrophe(p.name)))
    status.language.currentName = p.name
    status.language.currentImplementation = lm
  return OK

topCallback doRoutine:
  setDivision(state, DIVISIONS_ROUTINE)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let full = parameters.join(STRINGS_SPACE)
    let parts = full.split(STRINGS_PERIOD)
    if parts.len == 2:
      return errors.WRONGLY_DEFINED(WORDS_ROUTINE)
    let status = loadUbernimStatus(state)
    var p = status.getDivision(SCOPE_GLOBAL)
    if not assigned(p):
      return errors.BAD_STATE
    var lm = newLanguageItem(SUBDIVISIONS_ROUTINES)
    if not lm.read(full):
      return errors.WRONGLY_DEFINED(WORDS_ROUTINE)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if status.hasMethod(p, lm.name):
      return errors.ALREADY_DEFINED(spaced(WORDS_ROUTINE, apostrophe(full)))
    status.language.currentName = p.name
    status.language.currentImplementation = lm
    p.items.add(lm)
  return OK

childCallback doDocs:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_DOCS:
    return errors.CANT_OUTPUT_DOCS
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    let lm = status.language.currentImplementation
    if assigned(lm) and lm.rendered:
      return errors.DEFINE_BEFORE_VALUE
  setSubdivision(state, SUBDIVISIONS_DOCS)
  return OK

childCallback doCode:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_CODE:
    return errors.CANT_OUTPUT_CODE
  setSubdivision(state, SUBDIVISIONS_BODY)
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    var p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let lc = p.kind == DIVISIONS_CLASS
    let lp = p.extends
    let ln = status.language.currentName
    let lm = status.language.currentImplementation
    if lm.rendered:
      return errors.ALREADY_RENDERED
    lm.rendered = true
    if d == DIVISIONS_CONSTRUCTOR:
      return GOOD(renderUses(lm.uses) & renderConstructorBegin(lm, lc, ln))
    elif d == DIVISIONS_METHOD or d == DIVISIONS_GETTER or d == DIVISIONS_SETTER:
      return GOOD(renderUses(lm.uses) & renderMethodBegin(lm, lc, ln, lp))
    elif d == DIVISIONS_TEMPLATE:
      return GOOD(renderUses(lm.uses) & renderTemplateBegin(lm, ln))
    elif d == DIVISIONS_MEMBER:
      return GOOD(renderUses(lm.uses) & renderMemberBegin(lm, true))
    else: # if d == DIVISIONS_ROUTINE:
      return GOOD(renderUses(lm.uses) & renderRoutineBegin(lm))
  return OK

childCallback doUses:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_CODE:
    return errors.CANT_OUTPUT_CODE
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    var p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let lm = status.language.currentImplementation
    if not assigned(lm):
      return errors.BAD_STATE
    if lm.rendered:
      return errors.DEFINE_BEFORE_VALUE
    let once = state.getPropertyValue(FREQ_IMPORTING_KEY) == FREQUENCY_ONCE
    parameters.join(STRINGS_SPACE).split(STRINGS_COMMA).each u:
      let lu = strip(u)
      if lu notin status.files.imported:
        status.files.imported.add(lu)
      elif once:
        continue
      lm.uses.add(lu)
  return OK

topCallback doMember:
  setDivision(state, DIVISIONS_MEMBER)
  setSubdivision(state, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    var p = status.getDivision(SCOPE_GLOBAL)
    if not assigned(p):
      return errors.BAD_STATE
    let isVar = parameters[0] == CODEGEN_VAR
    let l = (if isVar: parameters[1..^1] else: parameters).join(STRINGS_SPACE)
    var lm = newLanguageItem(SUBDIVISIONS_MEMBERS)
    if not lm.read(l):
      return errors.WRONGLY_DEFINED(WORDS_MEMBER)
    if not lm.hasValidIdentifier():
      return errors.INVALID_IDENTIFIER
    if status.hasField(p, lm.name):
      return errors.ALREADY_DEFINED(spaced(WORDS_MEMBER, apostrophe(lm.name)))
    status.language.currentName = p.name
    lm.data_var = isVar
    status.language.currentImplementation = lm
    p.items.add(lm)
  return OK

childCallback doValue:
  let d = fetchDivision(state)
  if d notin DIVISIONS_WITH_VALUE:
    return errors.CANT_HOLD_VALUE
  setSubdivision(state, SUBDIVISIONS_BODY)
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    var p = status.getDivision(status.language.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let lm = status.language.currentImplementation
    if not assigned(lm):
      return errors.BAD_STATE
    if lm.rendered:
      return errors.ALREADY_RENDERED
    lm.rendered = true
    #let lc = p.kind == DIVISIONS_CLASS
    #let lp = p.extends
    #let ln = status.language.currentName
    lm.data_extra = parameters.join(STRINGS_SPACE)
    if d == DIVISIONS_MEMBER:
      return GOOD(renderUses(lm.uses) & renderMemberBegin(lm, false))
  return OK

childCallback doEnd:
  let d = fetchDivision(state)
  unsetDivision(state)
  unsetSubdivision(state)
  let status = loadUbernimStatus(state)
  var p = status.getDivision(status.language.currentName)
  let lc = assigned(p) and p.kind == DIVISIONS_CLASS
  let lp = if lc: p.extends else: STRINGS_EMPTY
  let ln = status.language.currentName
  let lm = status.language.currentImplementation
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
    elif d == DIVISIONS_MEMBER:
      if not lm.rendered and not lm.data_var:
        return errors.UNDEFINED_MEMBER_VALUE
      let p = if lm.rendered: STRINGS_EMPTY else: renderUses(lm.uses) & renderMemberBegin(lm, false)
      return GOOD(p & renderMemberEnd())
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

topCallback doImporting:
  if state.isTranslating():
    let frequency = parameters[0].toLower()
    if frequency notin [FREQUENCY_ALWAYS, FREQUENCY_ONCE]:
      return errors.BAD_FREQUENCY
    state.setPropertyValue(FREQ_IMPORTING_KEY, frequency)
  return OK

topCallback doExporting:
  if state.isTranslating():
    let frequency = parameters[0].toLower()
    if frequency notin [FREQUENCY_ALWAYS, FREQUENCY_ONCE]:
      return errors.BAD_FREQUENCY
    state.setPropertyValue(FREQ_EXPORTING_KEY, frequency)
  return OK

topCallback doApplying:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    var p = status.getDivision(SCOPE_GLOBAL)
    if not assigned(p):
      return errors.BAD_STATE
    let ld = status.getDivision(parameters[0])
    if not assigned(ld):
      return errors.UNDEFINED_REFERENCE(apostrophe(parameters[0]))
    if ld.kind notin DIVISIONS_ON_APPLY:
      return errors.NOT_APPLIABLE
    if parameters[0] in p.applies:
      return errors.ALREADY_APPLYING(apostrophe(parameters[0]))
    p.applies.add(parameters[0])
    return validateDivision(status, p)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "LANGUAGE":
    cmd("note", PreprodArguments.uaNone, doNote)
    cmd("imports", PreprodArguments.uaNone, doImports)
    cmd("exports", PreprodArguments.uaNone, doExports)
    cmd("importing", PreprodArguments.uaOne, doImporting)
    cmd("exporting", PreprodArguments.uaOne, doExporting)
    cmd("applying", PreprodArguments.uaOne, doApplying)
    cmd("push", PreprodArguments.uaNonZero, doPush)
    cmd("pop", PreprodArguments.uaNone, doPop)
    cmd("pragmas", PreprodArguments.uaNonZero, doPragmas)
    cmd("class", PreprodArguments.uaNonZero, doClass)
    cmd("record", PreprodArguments.uaOne, doRecord)
    cmd("compound", PreprodArguments.uaOne, doCompound)
    cmd("interface", PreprodArguments.uaOne, doInterface)
    cmd("protocol", PreprodArguments.uaOne, doProtocol)
    cmd("applies", PreprodArguments.uaOne, doApplies)
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
    cmd("member", PreprodArguments.uaNonZero, doMember)
    cmd("value", PreprodArguments.uaNonZero, doValue)
    cmd("end", PreprodArguments.uaNone, doEnd)
