# ubernim / PREPROCESSING #
#-------------------------#

import
  xam, preprod,
  features, errors, constants, performers, rendering,
  language / [header, member, state]

use os,changeFileExt
use strutils,find
use strutils,split
use strutils,strip

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
    if d != DIVISIONS_NOTE and d != DIVISIONS_IMPORTS and d != DIVISIONS_EXPORTS:
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
          if lm.kind == SUBDIVISIONS_FIELDS:
            if lm.public and d == DIVISIONS_RECORD:
              return errors.RECORDS_DONT_ASTERISK
            if ls.hasField(ld, lm.name):
              return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
            if ls.hasMethod(ld, lm.name, (member: LanguageMember) => not member.data_constructor and not member.data_getter and not member.data_setter and member.data_sealed):
              return errors.ALREADY_DEFINED(spaced(WORDS_SEALED, WORDS_METHOD, apostrophe(lm.name)))
          else:
            if (lm.data_getter or lm.data_setter) and ls.hasField(ld, lm.name):
              return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
          ld.members.add(lm)

let ppTranslater: PreprodTranslater = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
  result = r
  if hasText(r.output):
    if state.hasPropertyValue(KEY_DIVISION):
      let d = state.getPropertyValue(KEY_DIVISION)
      let s = state.getPropertyValue(KEY_SUBDIVISION)
      let ls = loadLanguageState(state)
      if d == DIVISIONS_NOTE or d == DIVISIONS_IMPORTS or d == DIVISIONS_EXPORTS:
        if s == SUBDIVISIONS_BODY:
          state.setPropertyValue(KEY_SUBDIVISION, STRINGS_EMPTY)
          return OK
        else:
          if d == DIVISIONS_NOTE:
            return GOOD(STRINGS_NUMERAL & STRINGS_SPACE & r.output)
          else:
            let item = strip(r.output)
            if d == DIVISIONS_EXPORTS:
              if not ls.exported.contains(item):
                ls.exported.add(item)
              elif state.getPropertyValue(UNIM_EXPORTING_KEY) == FREQUENCY_ONCE:
                return OK
              return GOOD(CODEGEN_EXPORT & STRINGS_SPACE & item)
            else: # d == DIVISIONS_IMPORTS
              if not ls.imported.contains(item):
                ls.imported.add(item)
              elif state.getPropertyValue(UNIM_IMPORTING_KEY) == FREQUENCY_ONCE:
                return OK
              if r.output.find(STRINGS_PERIOD) > -1:
                let p = item.split(STRINGS_PERIOD)
                return GOOD(spaced(CODEGEN_FROM, strip(p[0]), CODEGEN_IMPORT, strip(p[1])))
              else:
                return GOOD(spaced(CODEGEN_IMPORT, item))
      elif s == SUBDIVISIONS_DOCS:
        let lm = ls.currentImplementation
        if assigned(lm) and (hasContent(lm.docs) or hasContent(r.output)):
          lm.docs.add(r.output)
        return OK
      elif s != SUBDIVISIONS_CLAUSES and s != SUBDIVISIONS_BODY:
        return OK
      else:
        state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EOL)
    elif state.getPropertyValue(UNIM_MODE_KEY) == MODE_STRICT:
      return errors.STRICT_MODE

proc makePreprocessor*(filename: string): PreprodPreprocessor =
  newPreprodPreprocessor(filename, ppOptions, ppCommands, ppTranslater, ppPreviewer)

let DefaultPreprocessDoer* = proc (filename: string, ls: LanguageState): var PreprodState =
  # setup preprocessor
  var pp = makePreprocessor(filename)
  pp.state.storeLanguageState(ls)
  pp.state.setPropertyValue(NIMC_PROJECT_KEY, filename.changeFileExt(NIM_EXTENSION))
  pp.state.setPropertyValue(UNIM_FLUSH_KEY, FLAG_YES)
  pp.state.setPropertyValue(UNIM_MODE_KEY, MODE_FREE)
  pp.state.setPropertyValue(UNIM_IMPORTING_KEY, FREQUENCY_ALWAYS)
  pp.state.setPropertyValue(UNIM_EXPORTING_KEY, FREQUENCY_ALWAYS)
  # run preprocessor
  var r = pp.run()
  if not r.ok:
    UbernimPerformers.errorHandler(r.output)
  # emit output
  if pp.state.getPropertyValue(UNIM_FLUSH_KEY) == FLAG_YES:
    if not writeToFile(pp.state.getPropertyValue(NIMC_PROJECT_KEY), renderVersion(spaced(ls.callstack[^1], ls.signature)) & r.output):
      UbernimPerformers.errorHandler(errors.CANT_WRITE_OUTPUT.output)
  pp.state
