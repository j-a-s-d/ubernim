# ubernim / PREPROCESSING #
#-------------------------#

import
  xam, preprod,
  features, errors,
  language / [header, member, state]

var ppOptions: PreprodOptions = PREPROD_DEFAULT_OPTIONS
ppOptions.keepBlankLines = false
ppOptions.initialEnabledFeatures &= @[
  UbernimFeatures.UNIMCMDS.name,
  UbernimFeatures.SWITCHES.name,
  UbernimFeatures.SHELLCMD.name,
  UbernimFeatures.FSACCESS.name,
  UbernimFeatures.REQUIRES.name,
  UbernimFeatures.LANGUAGE.name
]

let ppCommands: PreprodCommands =
  UbernimFeatures.UNIMCMDS.commands &
  UbernimFeatures.SWITCHES.commands &
  UbernimFeatures.SHELLCMD.commands &
  UbernimFeatures.FSACCESS.commands &
  UbernimFeatures.REQUIRES.commands &
  UbernimFeatures.LANGUAGE.commands

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
          if lm.public and d == DIVISIONS_RECORD and lm.kind == SUBDIVISIONS_FIELDS:
            return errors.RECORDS_DONT_ASTERISK
          if lm.kind == SUBDIVISIONS_FIELDS and ls.hasField(ld, lm.name):
            return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
          if lm.kind == SUBDIVISIONS_METHODS and ls.hasMethod(ld, lm.name, (member: LanguageMember) => not member.data_constructor and not member.data_getter and not member.data_setter and member.data_sealed):
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
