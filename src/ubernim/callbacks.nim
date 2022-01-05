# ubernim / CALLBACKS #
#---------------------#

import
  os, strutils,
  xam, preprod,
  core, errors,
  language / [header, member, division, state]

# TEMPLATES

template callback(name, code: untyped): untyped =
  let name* {.inject.}: PreprodCallback = proc (ustate: var PreprodState, params: StringSeq): PreprodResult =
    var state {.inject, used.} = ustate
    let parameters {.inject, used.} = params
    try:
      code
    except:
      return errors.UNEXPECTED(getCurrentExceptionMsg())

template topCallback(name, code: untyped): untyped =
  callback name:
    if state.hasPropertyValue(KEY_DIVISION):
      return errors.ONLY_TOP_LEVEL
    code

template childCallback(name, code: untyped): untyped =
  callback name:
    if not state.hasPropertyValue(KEY_DIVISION):
      return errors.DONT_TOP_LEVEL
    code

# UNIMCMDS

topCallback doVersion:
  if state.isPreviewing():
    let ls = loadLanguageState(state)
    if newSemanticVersion(parameters[0]).isNewerThan(ls.semver):
      return errors.BAD_VERSION(parenthesize(parameters[0]))
  return OK

# SWITCHES

topCallback doProject:
  if state.isTranslating():
    state.setPropertyValue(NIMC_PROJECT_KEY, parameters[0])
  return OK

topCallback doConfig:
  if state.isTranslating():
    state.setPropertyValue(NIMC_CFGFILE_KEY, parameters[0])
  return OK

topCallback doSwitch:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_SWITCHES_KEY, parameters[0])
  return OK

topCallback doDefine:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_DEFINES_KEY, parameters[0])
  return OK

# SHELLCMD

topCallback doExec:
  if state.isPreviewing():
    discard execShellCmd(spaced(parameters))
  return OK

# FSACCESS

topCallback doChDir:
  if state.isPreviewing():
    setCurrentDir(parameters[0])
  return OK

topCallback doMkDir:
  if state.isPreviewing():
    # NOTE: avoid using existsOrCreateDir
    if not dirExists(parameters[0]):
      createDir(parameters[0])
    if not dirExists(parameters[0]):
      return errors.CANT_CREATE_DIRECTORY(apostrophe(parameters[0]))
  return OK

topCallback doCpDir:
  if state.isPreviewing():
    copyDir(parameters[0], parameters[1])
  return OK

topCallback doRmDir:
  if state.isPreviewing():
    removeDir(parameters[0])
  return OK

topCallback doCopy:
  if state.isPreviewing():
    copyfile(parameters[0], parameters[1])
  return OK

topCallback doMove:
  if state.isPreviewing():
    movefile(parameters[0], parameters[1])
  return OK

topCallback doAppend:
  if state.isPreviewing():
    if not appendToFile(parameters[0], if parameters.len == 1: STRINGS_EMPTY else: spaced(parameters[1..^1])):
      return errors.CANT_APPEND_FILE(apostrophe(parameters[0]))
  return OK

topCallback doWrite:
  if state.isPreviewing():
    if not writeToFile(parameters[0], if parameters.len == 1: STRINGS_EMPTY else: spaced(parameters[1..^1])):
      return errors.CANT_WRITE_FILE(apostrophe(parameters[0]))
  return OK

topCallback doRemove:
  if state.isPreviewing():
    if not tryRemoveFile(parameters[0]):
      return errors.CANT_REMOVE_FILE(apostrophe(parameters[0]))
  return OK

# REQUIRES

topCallback doRequire:
  result = OK
  if state.isPreviewing():
    let ls = loadLanguageState(state)
    if ls.unit == parameters[0]:
      return errors.NO_RECURSIVE_REQUIRE
    let stls = makeLanguageState()
    stls.unit = parameters[0]
    stls.signature = ls.signature
    var st = preprocessPerformer(parameters[0], stls)
    stls.divisions.each d:
      if d.public and not d.imported:
        let p = ls.getDivision(d.name)
        if assigned(p):
          result = errors.ALREADY_DEFINED(apostrophe(d.name))
          break
        d.imported = true
        ls.divisions.add(d)
    freeLanguageState(st)
    reset(st)

# LANGUAGE

proc startDivision(state: var PreprodState, division, subdivision, id: string): PreprodResult =
  let ls = loadLanguageState(state)
  if state.isPreviewing():
    let p = ls.getDivision(id)
    if assigned(p):
      return errors.ALREADY_DEFINED(apostrophe(id))
  state.setPropertyValue(KEY_DIVISION, division)
  state.setPropertyValue(KEY_SUBDIVISION, subdivision)
  openDivision(state, division, id)
  return OK

topCallback doProtocol:
  return startDivision(state, DIVISIONS_PROTOCOL, SUBDIVISIONS_CLAUSES, parameters[0])

topCallback doInterface:
  return startDivision(state, DIVISIONS_INTERFACE, SUBDIVISIONS_CLAUSES, parameters[0])

topCallback doCompound:
  return startDivision(state, DIVISIONS_COMPOUND, SUBDIVISIONS_CLAUSES, parameters[0])

topCallback doClass:
  result = startDivision(state, DIVISIONS_CLASS, SUBDIVISIONS_CLAUSES, parameters.join(STRINGS_SPACE))
  if result.ok and state.isTranslating():
    let ls = loadLanguageState(state)
    let p = ls.getDivision(ls.currentName)
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
    let ls = loadLanguageState(state)
    let p = ls.getDivision(ls.currentName)
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
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
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
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
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
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
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
      let ls = loadLanguageState(state)
      var p = ls.getDivision(ls.currentName)
      if not assigned(p):
        return errors.BAD_STATE
      if hasContent(p.pragmas):
        return errors.ALREADY_DEFINED(WORDS_PRAGMAS)
      p.pragmas = spaced(parameters)
  elif state.isTranslating():
    if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
      if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE:
        return errors.CANT_HAVE_PRAGMAS
      let ls = loadLanguageState(state)
      var p = ls.getDivision(ls.currentName)
      if not assigned(p):
        return errors.BAD_STATE
      if hasContent(ls.currentImplementation.pragmas):
        return errors.ALREADY_DEFINED(WORDS_PRAGMAS)
      ls.currentImplementation.pragmas = spaced(parameters)
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

topCallback doConstructor:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_CONSTRUCTOR)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_CONSTRUCTOR)
    let ls = loadLanguageState(state)
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
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

topCallback doMethod:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_METHOD)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_METHOD)
    let ls = loadLanguageState(state)
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
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

topCallback doTemplate:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_TEMPLATE)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return errors.WRONGLY_DEFINED(WORDS_TEMPLATE)
    let ls = loadLanguageState(state)
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
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

topCallback doRoutine:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_ROUTINE)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let full = parameters.join(STRINGS_SPACE)
    let parts = full.split(STRINGS_PERIOD)
    if parts.len == 2:
      return errors.WRONGLY_DEFINED(WORDS_ROUTINE)
    let ls = loadLanguageState(state)
    var p = ls.getDivision(SCOPE_GLOBAL)
    if not assigned(p):
      return errors.BAD_STATE
    var lm = newLanguageMember(SUBDIVISIONS_TEMPLATES)
    if not lm.read(full):
      return errors.WRONGLY_DEFINED(WORDS_ROUTINE)
    if ls.hasMethod(p, lm.name):
      return errors.ALREADY_DEFINED(spaced(WORDS_ROUTINE, apostrophe(full)))
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

childCallback doCode:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_CODE:
    return errors.CANT_OUTPUT_CODE
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_BODY)
  if state.isTranslating():
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
    if not assigned(p):
      return errors.BAD_STATE
    let lc = p.kind == DIVISIONS_CLASS
    let lp = p.extends
    let ln = ls.currentName
    let lm = ls.currentImplementation
    lm.rendered = true
    if d == DIVISIONS_CONSTRUCTOR:
      return GOOD(renderConstructorBegin(lm, lc, ln))
    elif d == DIVISIONS_METHOD:
      return GOOD(renderMethodBegin(lm, lc, ln, lp))
    elif d == DIVISIONS_TEMPLATE:
      return GOOD(renderTemplateBegin(lm, ln))
    else: # if d == DIVISIONS_ROUTINE:
      return GOOD(renderRoutineBegin(lm))
  return OK

childCallback doEnd:
  let d = state.getPropertyValue(KEY_DIVISION)
  state.removePropertyValue(KEY_SUBDIVISION)
  state.removePropertyValue(KEY_DIVISION)
  let ls = loadLanguageState(state)
  var p = ls.getDivision(ls.currentName)
  let lc = assigned(p) and p.kind == DIVISIONS_CLASS
  let lp = if lc: p.extends else: STRINGS_EMPTY
  let ln = ls.currentName
  let lm = ls.currentImplementation
  closeDivision(state)
  if state.isTranslating():
    if d == DIVISIONS_CONSTRUCTOR:
      let p = if lm.rendered: STRINGS_EMPTY else: renderConstructorBegin(lm, lc, ln)
      return GOOD(p & renderConstructorEnd())
    elif d == DIVISIONS_METHOD:
      let p = if lm.rendered: STRINGS_EMPTY else: renderMethodBegin(lm, lc, ln, lp) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderMethodEnd())
    elif d == DIVISIONS_TEMPLATE:
      let p = if lm.rendered: STRINGS_EMPTY else: renderTemplateBegin(lm, ln) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderTemplateEnd())
    elif d == DIVISIONS_ROUTINE:
      let p = if lm.rendered: STRINGS_EMPTY else: renderRoutineBegin(lm) & STRINGS_EOL & CODEGEN_INDENT & CODEGEN_DISCARD
      return GOOD(p & renderRoutineEnd())
    elif d == DIVISIONS_NOTE:
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
