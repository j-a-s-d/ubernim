# ubernim / PREPROCESSING #
#-------------------------#

import
  xam, preprod,
  callbacks, errors,
  language / [header, member, state]

const
  FEATURE_UNIMCMDS* = "UNIMCMDS" # ubernim general commands
  FEATURE_SWITCHES* = "SWITCHES" # nim compiler command line switches
  FEATURE_SHELLCMD* = "SHELLCMD" # os shell commands execution
  FEATURE_FSACCESS* = "FSACCESS" # os filesystem access
  FEATURE_REQUIRES* = "REQUIRES" # ubernim external files requirement (differs from INCLUDE in that the required modules are preprocessed separatelly)
  FEATURE_LANGUAGE* = "LANGUAGE" # ubernim language extensions

var ppOptions: PreprodOptions = PREPROD_DEFAULT_OPTIONS
ppOptions.keepBlankLines = false
ppOptions.initialEnabledFeatures &= @[
  FEATURE_UNIMCMDS,
  FEATURE_SWITCHES,
  FEATURE_SHELLCMD,
  FEATURE_FSACCESS,
  FEATURE_REQUIRES,
  FEATURE_LANGUAGE
]

let ppCommands: PreprodCommands = @[
  makeCommand(FEATURE_UNIMCMDS, "unim:version", PreprodArguments.uaOne, doVersion),
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
  makeCommand(FEATURE_LANGUAGE, "push", PreprodArguments.uaNonZero, doPush),
  makeCommand(FEATURE_LANGUAGE, "pop", PreprodArguments.uaNone, doPop),
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

let ppPreviewer: PreprodPreviewer = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
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
          return errors.BAD_STATE_IN_PREVIEW
        if s == SUBDIVISIONS_DOCS:
          if hasContent(ld.docs) or hasContent(l):
            ld.docs.add(l)
        else:
          var lm = newLanguageMember(s)
          if not lm.read(l):
            return errors.WRONGLY_DEFINED(WORDS_MEMBER)
          if not isValidNimIdentifier(lm.name):
            return errors.INVALID_IDENTIFIER
          if lm.public and d == DIVISIONS_RECORD:
            return errors.RECORDS_DONT_ASTERISK
          if lm.kind == SUBDIVISIONS_FIELDS and ls.hasField(ld, lm.name):
            return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
          proc sealedExaminer(member: LanguageMember): bool =
            not member.data_constructor and member.data_sealed
          if lm.kind == SUBDIVISIONS_METHODS and ls.hasMethod(ld, lm.name, sealedExaminer):
            return errors.ALREADY_DEFINED(spaced(WORDS_SEALED, WORDS_METHOD, apostrophe(lm.name)))
          ld.members.add(lm)

let ppTranslater: PreprodTranslater = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
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

proc makePreprocessor*(filename: string): PreprodPreprocessor =
  newPreprodPreprocessor(filename, ppOptions, ppCommands, ppTranslater, ppPreviewer)
