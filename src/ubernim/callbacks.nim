# ubernim / CALLBACKS #
#---------------------#

import
  os,
  xam, preprod,
  core

# TEMPLATES

type CbKind = enum
  RAW, TOP, CHILD

template callback(kind: CbKind, name, code: untyped): untyped =
  let name* {.inject.}: PreprodCallback = proc (ustate: var PreprodState, params: StringSeq): PreprodResult =
    var state {.inject, used.} = ustate
    let parameters {.inject, used.} = params
    try:
      case kind:
      of TOP:
        if state.hasPropertyValue(KEY_DIVISION):
          return BAD("this can only be defined in the top level")
      of CHILD:
        if not state.hasPropertyValue(KEY_DIVISION):
          return BAD("this can not be defined in the top level")
      of RAW:
        discard
      code
    except:
      return BAD("an unexpected error ocurred: " & getCurrentExceptionMsg())

template rawCallback(name, code: untyped): untyped =
  callback RAW, name:
    code

template topCallback(name, code: untyped): untyped =
  callback TOP, name:
    code

template childCallback(name, code: untyped): untyped =
  callback CHILD, name:
    code

# SWITCHES

rawCallback doProject:
  if state.isTranslating():
    state.setPropertyValue(NIMC_PROJECT_KEY, parameters[0])
  return OK

rawCallback doConfig:
  if state.isTranslating():
    state.setPropertyValue(NIMC_CFGFILE_KEY, parameters[0])
  return OK

rawCallback doSwitch:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_SWITCHES_KEY, parameters[0])
  return OK

rawCallback doDefine:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_DEFINES_KEY, parameters[0])
  return OK

# SHELLCMD

rawCallback doExec:
  if state.isPreviewing():
    discard execShellCmd(spaced(parameters))
  return OK

# FSACCESS

rawCallback doChDir:
  if state.isPreviewing():
    setCurrentDir(parameters[0])
  return OK

rawCallback doMkDir:
  if state.isPreviewing():
    # NOTE: avoid using existsOrCreateDir
    if not dirExists(parameters[0]):
      createDir(parameters[0])
    if not dirExists(parameters[0]):
      return BAD("can not create directory " & apostrophe(parameters[0]))
  return OK

rawCallback doCpDir:
  if state.isPreviewing():
    copyDir(parameters[0], parameters[1])
  return OK

rawCallback doRmDir:
  if state.isPreviewing():
    removeDir(parameters[0])
  return OK

rawCallback doCopy:
  if state.isPreviewing():
    copyfile(parameters[0], parameters[1])
  return OK

rawCallback doMove:
  if state.isPreviewing():
    movefile(parameters[0], parameters[1])
  return OK

rawCallback doAppend:
  if state.isPreviewing():
    if not appendToFile(parameters[0], if parameters.len == 1: STRINGS_EMPTY else: spaced(parameters[1..^1])):
      return BAD("can not append file " & apostrophe(parameters[0]))
  return OK

rawCallback doWrite:
  if state.isPreviewing():
    if not writeToFile(parameters[0], if parameters.len == 1: STRINGS_EMPTY else: spaced(parameters[1..^1])):
      return BAD("can not write file " & apostrophe(parameters[0]))
  return OK

rawCallback doRemove:
  if state.isPreviewing():
    if not tryRemoveFile(parameters[0]):
      return BAD("can not remove file " & apostrophe(parameters[0]))
  return OK

# REQUIRES

rawCallback doRequire:
  result = OK
  if state.isPreviewing():
    let ls = loadLanguageState(state)
    if ls.unit == parameters[0]:
      return BAD("recursive require instruction is not allowed")
    let stls = makeLanguageState()
    stls.unit = parameters[0]
    stls.version = ls.version
    var st = preprocess(parameters[0], stls)
    stls.divisions.each d:
      if d.public and not d.imported:
        let p = ls.getDivision(d.name)
        if assigned(p):
          result = BAD("already defined " & apostrophe(d.name))
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
    if p != nil:
      return BAD("already defined " & apostrophe(id))
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
      return BAD("bad state")
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
      return BAD("bad state")
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
      return BAD("bad state")
    let ld = ls.getDivision(parameters[0])
    if not assigned(ld):
      return BAD("the referred " & apostrophe(parameters[0]) & " is undefined")
    if ld.kind != DIVISIONS_COMPOUND and ld.kind != DIVISIONS_INTERFACE and ld.kind != DIVISIONS_PROTOCOL:
      return BAD("the referred " & apostrophe(parameters[0]) & " is not a compound, interface or protocol")
    if parameters[0] notin p.applies:
      p.applies.add(parameters[0])
  return OK

childCallback doImplies:
  if state.isPreviewing():
    let d = state.getPropertyValue(KEY_DIVISION)
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
    if not assigned(p):
      return BAD("bad state")
    let ld = ls.getDivision(parameters[0])
    if not assigned(ld):
      return BAD("the referred " & apostrophe(parameters[0]) & " is undefined")
    if ld.kind != d:
      return BAD("the referred " & apostrophe(parameters[0]) & " is not of the same type as " & apostrophe(ls.currentName))
    if hasContent(p.implies):
      return BAD("this is already impliying " & apostrophe(p.implies))
    p.implies = parameters[0]
  return OK

childCallback doExtends:
  if state.isPreviewing():
    let d = state.getPropertyValue(KEY_DIVISION)
    if d == DIVISIONS_RECORD:
      return BAD("records can not be extended, try to imply if it's possible")
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
    if not assigned(p):
      return BAD("bad state")
    if hasContent(p.extends):
      return BAD("this is already extending " & apostrophe(p.extends))
    let x = ls.getDivision(parameters[0])
    if not assigned(x):
      return BAD("can not extend from inexistent " & apostrophe(parameters[0]))
    if x.data_sealed:
      return BAD("can not extend from sealed " & apostrophe(parameters[0]))
    p.extends = parameters[0]
  return OK

childCallback doPragmas:
  let d = state.getPropertyValue(KEY_DIVISION)
  if state.isPreviewing():
    if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE:
      if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
        return BAD("this can not have pragmas")
      let ls = loadLanguageState(state)
      var p = ls.getDivision(ls.currentName)
      if not assigned(p):
        return BAD("bad state")
      if hasContent(p.pragmas):
        return BAD("pragmas were already defined")
      p.pragmas = spaced(parameters)
  elif state.isTranslating():
    if d != DIVISIONS_CLASS and d != DIVISIONS_RECORD:
      if d != DIVISIONS_CONSTRUCTOR and d != DIVISIONS_METHOD and d != DIVISIONS_ROUTINE:
        return BAD("this can not have pragmas")
      let ls = loadLanguageState(state)
      var p = ls.getDivision(ls.currentName)
      if not assigned(p):
        return BAD("bad state")
      if hasContent(ls.currentImplementation.pragmas):
        return BAD("pragmas were already defined")
      ls.currentImplementation.pragmas = spaced(parameters)
  return OK

childCallback doFields:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_FIELDS:
    return BAD("this can not have fields")
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_FIELDS)
  return OK

childCallback doMethods:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_METHODS:
    return BAD("this can not have methods")
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_METHODS)
  return OK

childCallback doTemplates:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_TEMPLATES:
    return BAD("this can not have templates")
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_TEMPLATES)
  return OK

childCallback doDocs:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_DOCS:
    return BAD("this can not output documentation")
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
      return BAD("bad constructor definition")
    let ls = loadLanguageState(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return BAD("never defined " & apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_METHODS)
    if not lm.read(STRINGS_PLUS & parts[1]):
      return BAD("bad constructor definition")
    if not ls.hasMethod(p, lm.name):
      return BAD("never defined constructor " & apostrophe(parts[1]))
    let pm = ls.getMember(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return BAD("bad state")
    if pm.public != lm.public:
      return BAD("visibility does not match for constructor " & apostrophe(lm.name & parenthesize(lm.data_extra)) & " at " & apostrophe(p.name))
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

topCallback doMethod:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_METHOD)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return BAD("bad method definition")
    let ls = loadLanguageState(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return BAD("never defined " & apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_METHODS)
    if not lm.read(parts[1]):
      return BAD("bad method definition")
    if not ls.hasMethod(p, lm.name):
      return BAD("never defined method " & apostrophe(parts[1]))
    let pm = ls.getMember(p, SUBDIVISIONS_METHODS, lm.name)
    if not assigned(pm):
      return BAD("bad state")
    if pm.public != lm.public:
      return BAD("visibility does not match for method " & apostrophe(lm.name & parenthesize(lm.data_extra)) & " at " & apostrophe(p.name))
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

topCallback doTemplate:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_TEMPLATE)
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_CLAUSES)
  if state.isTranslating():
    let parts = parameters.join(STRINGS_SPACE).split(STRINGS_PERIOD)
    if parts.len != 2:
      return BAD("bad template definition")
    let ls = loadLanguageState(state)
    var p = ls.getDivision(parts[0])
    if not assigned(p):
      return BAD("never defined " & apostrophe(parts[0]))
    var lm = newLanguageMember(SUBDIVISIONS_TEMPLATES)
    if not lm.read(parts[1]):
      return BAD("bad template definition")
    if not ls.hasTemplate(p, lm.name):
      return BAD("never defined template " & apostrophe(parts[1]))
    let pm = ls.getMember(p, SUBDIVISIONS_TEMPLATES, lm.name)
    if not assigned(pm):
      return BAD("bad state")
    if pm.public != lm.public:
      return BAD("visibility does not match for template " & apostrophe(lm.name & parenthesize(lm.data_extra)) & " at " & apostrophe(p.name))
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
      return BAD("bad routine definition")
    let ls = loadLanguageState(state)
    var p = ls.getDivision(SCOPE_GLOBAL)
    if not assigned(p):
      return BAD("bad state")
    var lm = newLanguageMember(SUBDIVISIONS_TEMPLATES)
    if not lm.read(full):
      return BAD("bad routine definition")
    if ls.hasMethod(p, lm.name):
      return BAD("already defined routine " & apostrophe(full))
    ls.currentName = p.name
    ls.currentImplementation = lm
  return OK

childCallback doCode:
  let d = state.getPropertyValue(KEY_DIVISION)
  if d notin DIVISIONS_WITH_CODE:
    return BAD("this can not output code")
  state.setPropertyValue(KEY_SUBDIVISION, SUBDIVISIONS_BODY)
  if state.isTranslating():
    let ls = loadLanguageState(state)
    var p = ls.getDivision(ls.currentName)
    if not assigned(p):
      return BAD("bad state")
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
