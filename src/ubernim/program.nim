# ubernim / PROGRAM #
#-------------------#

import
  os,
  rodster, xam, preprod,
  common, core, callbacks

options.keepBlankLines = false
options.initialEnabledFeatures &= @[
  FEATURE_SWITCHES,
  FEATURE_SHELLCMD,
  FEATURE_FSACCESS,
  FEATURE_REQUIRES,
  FEATURE_LANGUAGE
]

commands = @[
  makeCommand(FEATURE_SWITCHES, "nimc:project", PreprodArguments.uaOne, doProject),
  makeCommand(FEATURE_SWITCHES, "nimc:config", PreprodArguments.uaOne, doConfig),
  makeCommand(FEATURE_SWITCHES, "nimc:define", PreprodArguments.uaOne, doDefine),
  makeCommand(FEATURE_SWITCHES, "nimc:switch", PreprodArguments.uaOne, doSwitch),
  makeCommand(FEATURE_SHELLCMD, "exec", PreprodArguments.uaNonZero, doExec),
  makeCommand(FEATURE_FSACCESS, "copy", PreprodArguments.uaTwo, doCopy),
  makeCommand(FEATURE_FSACCESS, "move", PreprodArguments.uaTwo, doMove),
  makeCommand(FEATURE_FSACCESS, "remove", PreprodArguments.uaOne, doRemove),
  makeCommand(FEATURE_FSACCESS, "write", PreprodArguments.uaNonZero, doWrite),
  makeCommand(FEATURE_FSACCESS, "append", PreprodArguments.uaNonZero, doAppend),
  makeCommand(FEATURE_FSACCESS, "mkdir", PreprodArguments.uaOne, doMkDir),
  makeCommand(FEATURE_FSACCESS, "chdir", PreprodArguments.uaOne, doChDir),
  makeCommand(FEATURE_FSACCESS, "cpdir", PreprodArguments.uaTwo, doCpDir),
  makeCommand(FEATURE_FSACCESS, "rmdir", PreprodArguments.uaOne, doRmDir),
  makeCommand(FEATURE_REQUIRES, "require", PreprodArguments.uaOne, doRequire),
  makeCommand(FEATURE_LANGUAGE, "note", PreprodArguments.uaNone, doNote),
  makeCommand(FEATURE_LANGUAGE, "pragmas", PreprodArguments.uaNonZero, doPragmas),
  makeCommand(FEATURE_LANGUAGE, "class", PreprodArguments.uaNonZero, doClass),
  makeCommand(FEATURE_LANGUAGE, "record", PreprodArguments.uaOne, doRecord),
  makeCommand(FEATURE_LANGUAGE, "compound", PreprodArguments.uaOne, doCompound),
  makeCommand(FEATURE_LANGUAGE, "interface", PreprodArguments.uaOne, doInterface),
  makeCommand(FEATURE_LANGUAGE, "protocol", PreprodArguments.uaOne, doProtocol),
  makeCommand(FEATURE_LANGUAGE, "applies", PreprodArguments.uaOne, doApplies),
  makeCommand(FEATURE_LANGUAGE, "implies", PreprodArguments.uaOne, doImplies),
  makeCommand(FEATURE_LANGUAGE, "extends", PreprodArguments.uaOne, doExtends),
  makeCommand(FEATURE_LANGUAGE, "fields", PreprodArguments.uaNone, doFields),
  makeCommand(FEATURE_LANGUAGE, "methods", PreprodArguments.uaNone, doMethods),
  makeCommand(FEATURE_LANGUAGE, "templates", PreprodArguments.uaNone, doTemplates),
  makeCommand(FEATURE_LANGUAGE, "docs", PreprodArguments.uaNone, doDocs),
  makeCommand(FEATURE_LANGUAGE, "constructor", PreprodArguments.uaNonZero, doConstructor),
  makeCommand(FEATURE_LANGUAGE, "method", PreprodArguments.uaNonZero, doMethod),
  makeCommand(FEATURE_LANGUAGE, "template", PreprodArguments.uaNonZero, doTemplate),
  makeCommand(FEATURE_LANGUAGE, "routine", PreprodArguments.uaNonZero, doRoutine),
  makeCommand(FEATURE_LANGUAGE, "code", PreprodArguments.uaNone, doCode),
  makeCommand(FEATURE_LANGUAGE, "end", PreprodArguments.uaNone, doEnd)
]

previewer = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
  result = r
  if hasContent(r.output) and state.hasPropertyValue(KEY_DIVISION):
    let d = state.getPropertyValue(KEY_DIVISION)
    if d != DIVISIONS_NOTE:
      let s = state.getPropertyValue(KEY_SUBDIVISION)
      let l = if s == SUBDIVISIONS_DOCS: r.output else: removeComments(state, r.output)
      if hasContent(l) and d notin DIVISIONS_WITH_CODE and s != SUBDIVISIONS_CLAUSES:
        let ls = loadLanguageState(state)
        var ld = ls.getDivision(ls.currentName)
        if not assigned(ld):
          return BAD("bad state in preview")
        if s == SUBDIVISIONS_DOCS:
          if hasContent(ld.docs) or hasContent(l):
            ld.docs.add(l)
        else:
          var lm = newLanguageMember(s)
          if not lm.read(l):
            return BAD("bad member definition")
          if not isValidNimIdentifier(lm.name):
            return BAD("invalid identifier")
          if lm.public and d == DIVISIONS_RECORD:
            return BAD("the * modifier is not allowed in record fields")
          if lm.kind == SUBDIVISIONS_FIELDS and ls.hasField(ld, lm.name):
            return BAD("already defined field " & apostrophe(lm.name))
          proc sealedExaminer(member: LanguageMember): bool =
            not member.data_constructor and member.data_sealed
          if lm.kind == SUBDIVISIONS_METHODS and ls.hasMethod(ld, lm.name, sealedExaminer):
            return BAD("already defined sealed method " & apostrophe(lm.name))
          ld.members.add(lm)

translater = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
  result = r
  if state.hasPropertyValue(KEY_DIVISION):
    let s = state.getPropertyValue(KEY_SUBDIVISION)
    if state.getPropertyValue(KEY_DIVISION) == DIVISIONS_NOTE:
      if s == SUBDIVISIONS_BODY:
        state.setPropertyValue(KEY_SUBDIVISION, STRINGS_EMPTY)
        return OK
      else:
        return GOOD(STRINGS_NUMERAL & STRINGS_SPACE & r.output)
    if s == SUBDIVISIONS_DOCS:
      let ls = loadLanguageState(state)
      let lm = ls.currentImplementation
      if assigned(lm) and (hasContent(lm.docs) or hasContent(r.output)):
        lm.docs.add(r.output)
      return OK
    elif s != SUBDIVISIONS_CLAUSES and s != SUBDIVISIONS_BODY:
      return OK
    else:
      state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EOL)

preprocess = proc (filename: string, ls: LanguageState): var PreprodState =
  var pp = newPreprodPreprocessor(filename, options, commands, translater, previewer)
  storeLanguageState(pp.state, ls)
  var r = pp.run()
  if not r.ok:
    err r.output
  if not writeToFile(filename.changeFileExt(NIM_EXTENSION), (
    if hasText(ls.version): renderVersion(ls.version) else: STRINGS_EMPTY
  ) & r.output):
    err "could not write output file"
  pp.state

postprocess = proc (state: var PreprodState): int =
  var cldefs = newStringSeq()
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      cldefs.add(NIM_DEFINE & define)
  var nimcSwitches = newStringSeq()
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    nimcSwitches = state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY)
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    if not writeToFile(state.getPropertyValue(NIMC_CFGFILE_KEY), lined(nimcSwitches)):
      err "could not write config file"
  else:
    cldefs &= nimcSwitches
  if state.hasPropertyValue(NIMC_PROJECT_KEY):
    let cmd = spaced(NIM_COMPILE, spaced(cldefs), state.getPropertyValue(NIMC_PROJECT_KEY))
    return execShellCmd(cmd)
    #let cres = execCmdEx(cmd, options = {poStdErrToStdOut})
    #echo cres.output
    #return cres.exitCode

# EVENTS

let onInitialize* = proc (app: RodsterApplication) =
  if paramCount() != 1:
    app.showHelp()
    halt()
  let nfo = app.getInformation()
  let kvm = app.getKvm()
  kvm["version"] = spaced(nfo.getTitle(), STRINGS_LOWERCASE_V & $nfo.getVersion())
  kvm["input"] = paramStr(1)

let programRun* = proc (app: RodsterApplication) =
  let kvm = app.getKvm()
  var ls = makeLanguageState()
  ls.version = kvm["version"]
  ls.unit = kvm["input"]
  var state = preprocess(ls.unit, ls)
  kvm["errorlevel"] = $postprocess(state)
  freeLanguageState(state)

let onFinalize* = (app: RodsterApplication) => done tryParseInt(app.getKvm()["errorlevel"], -1)
