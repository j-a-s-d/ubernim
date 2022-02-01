# ubernim / PREPROCESSING #
#-------------------------#

import
  xam, preprod,
  errors, constants, rendering, status,
  commands / [UNIMCMDS, SWITCHES, SHELLCMD, FSACCESS, REQUIRES, LANGUAGE],
  language / [header, implementation]

use os,changeFileExt
use strutils,find
use strutils,split
use strutils,strip

let ppFeatures = [
  UNIMCMDS.initialize(), # ubernim general commands
  SWITCHES.initialize(), # nim compiler command line switches
  SHELLCMD.initialize(), # os shell commands execution
  FSACCESS.initialize(), # os filesystem access
  REQUIRES.initialize(), # ubernim external files requirement (differs from INCLUDE in that the required modules are preprocessed separatelly)
  LANGUAGE.initialize()  # ubernim language extensions
]

var ppOptions: PreprodOptions = PREPROD_DEFAULT_OPTIONS
ppOptions.keepBlankLines = false
ppFeatures.each x:
  ppOptions.initialEnabledFeatures &= x.name

let ppCommands: PreprodCommands = block:
  var cmds: PreprodCommands = @[]
  ppFeatures.each x:
    cmds &= x.commands
  cmds

let ppPreviewer: PreprodPreviewer = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
  result = r
  if hasContent(r.output) and state.hasPropertyValue(KEY_DIVISION):
    let d = state.getPropertyValue(KEY_DIVISION)
    if d != DIVISIONS_NOTE and d != DIVISIONS_IMPORTS and d != DIVISIONS_EXPORTS:
      let s = state.getPropertyValue(KEY_SUBDIVISION)
      let l = if s == SUBDIVISIONS_DOCS: r.output else: removeComments(state, r.output)
      if hasContent(l) and d notin DIVISIONS_WITH_CODE and s != SUBDIVISIONS_CLAUSES:
        let ls = loadUbernimStatus(state)
        var ld = ls.getDivision(ls.language.currentName)
        if not assigned(ld):
          return errors.BAD_STATE
        if s == SUBDIVISIONS_DOCS:
          if hasContent(ld.docs) or hasContent(l):
            ld.docs.add(l)
        else:
          var lm = newLanguageItem(s)
          if not lm.read(l):
            return errors.WRONGLY_DEFINED(WORDS_ITEM)
          if not isValidNimIdentifier(lm.name):
            return errors.INVALID_IDENTIFIER
          if lm.kind == SUBDIVISIONS_FIELDS:
            if lm.public and d == DIVISIONS_RECORD:
              return errors.RECORDS_DONT_ASTERISK
            if ls.hasField(ld, lm.name):
              return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
            if ls.hasMethod(ld, lm.name, (item: LanguageItem) => not item.data_constructor and not item.data_getter and not item.data_setter and item.data_sealed):
              return errors.ALREADY_DEFINED(spaced(WORDS_SEALED, WORDS_METHOD, apostrophe(lm.name)))
          else:
            if (lm.data_getter or lm.data_setter) and ls.hasField(ld, lm.name):
              return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
          ld.items.add(lm)

let ppTranslater: PreprodTranslater = proc (state: var PreprodState, r: PreprodResult): PreprodResult =
  result = r
  if hasText(r.output):
    if state.hasPropertyValue(KEY_DIVISION):
      let d = state.getPropertyValue(KEY_DIVISION)
      let s = state.getPropertyValue(KEY_SUBDIVISION)
      let ls = loadUbernimStatus(state)
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
              if not ls.files.exported.contains(item):
                ls.files.exported.add(item)
              elif state.getPropertyValue(FREQ_EXPORTING_KEY) == FREQUENCY_ONCE:
                return OK
              return GOOD(CODEGEN_EXPORT & STRINGS_SPACE & item)
            else: # d == DIVISIONS_IMPORTS
              if not ls.files.imported.contains(item):
                ls.files.imported.add(item)
              elif state.getPropertyValue(FREQ_IMPORTING_KEY) == FREQUENCY_ONCE:
                return OK
              if r.output.find(STRINGS_PERIOD) > -1:
                let p = item.split(STRINGS_PERIOD)
                return GOOD(spaced(CODEGEN_FROM, strip(p[0]), CODEGEN_IMPORT, strip(p[1])))
              else:
                return GOOD(spaced(CODEGEN_IMPORT, item))
      elif s == SUBDIVISIONS_DOCS:
        let lm = ls.language.currentImplementation
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
  result = newPreprodPreprocessor(filename, ppOptions, ppCommands, ppTranslater, ppPreviewer)
  result.state.setPropertyValue(UNIM_FILE_KEY, filename.changeFileExt(NIM_EXTENSION))
  result.state.setPropertyValue(UNIM_FLUSH_KEY, FLAG_YES)
  result.state.setPropertyValue(UNIM_MODE_KEY, MODE_FREE)
  result.state.setPropertyValue(UNIM_CLEANUP_KEY, VALUE_IGNORED)
  result.state.setPropertyValue(FREQ_IMPORTING_KEY, FREQUENCY_ALWAYS)
  result.state.setPropertyValue(FREQ_EXPORTING_KEY, FREQUENCY_ALWAYS)
