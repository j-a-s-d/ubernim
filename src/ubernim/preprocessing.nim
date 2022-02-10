# ubernim / PREPROCESSING #
#-------------------------#

import
  xam, preprod,
  errors, constants, rendering, status,
  commands / [UNIMPRJS, UNIMCMDS, SWITCHES, SHELLCMD, FSACCESS, REQUIRES, LANGUAGE, TARGETED],
  language / [header, implementation]

use os,changeFileExt
use strutils,find
use strutils,split
use strutils,strip
use strutils,replace
use strutils,endsWith

# FEATURES

let DEFAULT_FEATURES = @[
  UNIMCMDS.initialize(), # ubernim general commands
  SWITCHES.initialize(), # nim compiler command line switches
  SHELLCMD.initialize(), # os shell commands execution
  FSACCESS.initialize(), # os filesystem access
  REQUIRES.initialize() # ubernim external files requirement (differs from INCLUDE in that the required modules are preprocessed separatelly)
]

let ppUnimFeatures = DEFAULT_FEATURES & @[
  LANGUAGE.initialize(), # ubernim language extensions
  TARGETED.initialize()  # target dependant language extension
]

let ppUnimpFeatures = DEFAULT_FEATURES & @[
  UNIMPRJS.initialize() # ubernim project extension
]

# OPTIONS

let getOptions = proc (isProject: bool): PreprodOptions =
  result = PREPROD_DEFAULT_OPTIONS
  result.keepBlankLines = false
  (if isProject: ppUnimpFeatures else: ppUnimFeatures).each x:
    result.initialEnabledFeatures &= x.name

# COMMANDS

let getCommands = proc (isProject: bool): PreprodCommands =
  var cmds: PreprodCommands = @[]
  (if isProject: ppUnimpFeatures else: ppUnimFeatures).each x:
    cmds &= x.commands
  cmds

# PREVIEWING

const
  DIVISIONS_NOT_PREVIEWING = [DIVISIONS_NOTE, DIVISIONS_IMPORTS, DIVISIONS_EXPORTS, DIVISIONS_TARGETED]
  SEALED_EXAMINER = (item: LanguageItem) => not item.data_constructor and not item.data_getter and not item.data_setter and item.data_sealed

func previewItem(status: UbernimStatus, ld: LanguageDivision, lm: LanguageItem, inRecord: bool, line: string, original: PreprodResult): PreprodResult =
  if not lm.read(line):
    return errors.WRONGLY_DEFINED(WORDS_ITEM)
  if not lm.hasValidIdentifier():
    return errors.INVALID_IDENTIFIER
  if lm.kind == SUBDIVISIONS_FIELDS:
    if lm.public and inRecord:
      return errors.RECORDS_DONT_ASTERISK
    if status.hasField(ld, lm.name):
      return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
    if status.hasMethod(ld, lm.name, SEALED_EXAMINER):
      return errors.ALREADY_DEFINED(spaced(WORDS_SEALED, WORDS_METHOD, apostrophe(lm.name)))
  else:
    if (lm.data_getter or lm.data_setter) and status.hasField(ld, lm.name):
      return errors.ALREADY_DEFINED(spaced(WORDS_FIELD, apostrophe(lm.name)))
  ld.items.add(lm)
  return original

let ppPreviewer: PreprodPreviewer = proc (state: var PreprodState, original: PreprodResult): PreprodResult =
  result = original
  if hasContent(original.output) and state.hasPropertyValue(KEY_DIVISION):
    let division = state.getPropertyValue(KEY_DIVISION)
    if division notin DIVISIONS_NOT_PREVIEWING:
      let subdivision = state.getPropertyValue(KEY_SUBDIVISION)
      let line = if subdivision == SUBDIVISIONS_DOCS: original.output else: removeComments(state, original.output)
      if hasContent(line) and division notin DIVISIONS_WITH_CODE and subdivision != SUBDIVISIONS_CLAUSES:
        let status = loadUbernimStatus(state)
        var ld = status.getDivision(status.language.currentName)
        if not assigned(ld):
          return errors.BAD_STATE
        if subdivision == SUBDIVISIONS_DOCS:
          if hasContent(ld.docs) or hasContent(line):
            ld.docs.add(line)
        else:
          return previewItem(status, ld, newLanguageItem(subdivision), division == DIVISIONS_RECORD, line, original)

let ppDummyPreviewer: PreprodPreviewer = proc (state: var PreprodState, original: PreprodResult): PreprodResult =
  result = original

let getPreviewer = proc (isProject: bool): PreprodPreviewer =
  if isProject: ppDummyPreviewer else: ppPreviewer

# TRANSLATING

func translateTargeted(original: PreprodResult, subdivision: string): PreprodResult =
  let l = strip(original.output)
  case subdivision:
  of SUBDIVISIONS_TARGETED_PASS:
    let p = l.split(STRINGS_SPACE)
    if p.len > 1:
      template makePassLine(name: string): string =
        let value: string = spaced(p[1..^1])
        if value.replace(STRINGS_QUOTE, STRINGS_EMPTY).len > 0:
          renderPragmas(name & STRINGS_COLON & STRINGS_SPACE & value, false)
        else:
          STRINGS_EMPTY
      return GOOD(
        case p[0]:
        of TO_COMPILER: makePassLine(PASS_COMPILER)
        of TO_LOCAL: makePassLine(PASS_LOCAL) # NOTE: supported in nim 1.2.0+
        of TO_LINKER: makePassLine(PASS_LINK)
        else: STRINGS_EMPTY
      )
  of SUBDIVISIONS_TARGETED_COMPILE:
    let p = l.split(STRINGS_SPACE)
    let v = if p.len > 1:
        parenthesize(quote(p[0]) & STRINGS_COMMA & STRINGS_SPACE & quote(spaced(p[1..^1]))) # NOTE: supported in nim 1.4.0+
      else:
        STRINGS_COLON & STRINGS_SPACE & quote(l)
    return GOOD(renderPragmas(CODEGEN_COMPILE & v, false))
  of SUBDIVISIONS_TARGETED_LINK:
    return GOOD(renderPragmas(CODEGEN_LINK & STRINGS_COLON & STRINGS_SPACE & quote(l), false))
  return original

func translateDocs(original: PreprodResult, lm: LanguageItem): PreprodResult =
  if assigned(lm) and (hasContent(lm.docs) or hasContent(original.output)):
    lm.docs.add(original.output)
  return OK

func translateExports(original: PreprodResult, state: PreprodState, status: UbernimStatus, once: bool): PreprodResult =
  let item = strip(original.output)
  if not status.files.exported.contains(item):
    status.files.exported.add(item)
  elif once:
    return OK
  return GOOD(CODEGEN_EXPORT & STRINGS_SPACE & item)

func translateImports(original: PreprodResult, state: PreprodState, status: UbernimStatus, once: bool): PreprodResult =
  let item = strip(original.output)
  if not status.files.imported.contains(item):
    status.files.imported.add(item)
  elif once:
    return OK
  if original.output.find(STRINGS_PERIOD) > -1:
    let p = item.split(STRINGS_PERIOD)
    return GOOD(spaced(CODEGEN_FROM, strip(p[0]), CODEGEN_IMPORT, strip(p[1])))
  else:
    return GOOD(spaced(CODEGEN_IMPORT, item))

let ppTranslator: PreprodTranslator = proc (state: var PreprodState, original: PreprodResult): PreprodResult =
  result = original
  if hasText(original.output):
    if state.hasPropertyValue(KEY_DIVISION):
      let division = state.getPropertyValue(KEY_DIVISION)
      let subdivision = state.getPropertyValue(KEY_SUBDIVISION)
      let status = loadUbernimStatus(state)
      if division == DIVISIONS_TARGETED:
        if original.output != CODEGEN_EMIT_CLOSE:
          return translateTargeted(original, subdivision)
      elif division == DIVISIONS_NOTE or division == DIVISIONS_IMPORTS or division == DIVISIONS_EXPORTS:
        if subdivision == SUBDIVISIONS_BODY:
          state.setPropertyValue(KEY_SUBDIVISION, STRINGS_EMPTY)
          return OK
        else:
          if division == DIVISIONS_NOTE:
            return GOOD(STRINGS_NUMERAL & STRINGS_SPACE & original.output)
          else:
            template isOnce(state: PreprodState, key: string): bool =
              state.hasPropertyValue(key) and state.getPropertyValue(key) == FREQUENCY_ONCE
            if division == DIVISIONS_EXPORTS:
              return translateExports(original, state, status, isOnce(state, FREQ_EXPORTING_KEY))
            else: # d == DIVISIONS_IMPORTS
              return translateImports(original, state, status, isOnce(state, FREQ_IMPORTING_KEY))
      elif subdivision == SUBDIVISIONS_DOCS:
        return translateDocs(original, status.language.currentImplementation)
      elif subdivision != SUBDIVISIONS_CLAUSES and subdivision != SUBDIVISIONS_BODY:
        return OK
      else:
        state.setPropertyValue(PREPROD_LINE_APPENDIX_KEY, STRINGS_EOL)
    elif state.getPropertyValue(UNIM_MODE_KEY) == MODE_STRICT:
      return errors.STRICT_MODE

let ppDummyTranslator: PreprodTranslator = proc (state: var PreprodState, original: PreprodResult): PreprodResult =
  result = original

let getTranslator = proc (isProject: bool): PreprodTranslator =
  if isProject: ppDummyTranslator else: ppTranslator

# PREPROCESSOR

proc makePreprocessor*(filename: string, defines: StringSeq = newStringSeq()): PreprodPreprocessor =
  let isProject = filename.endsWith(UNIM_PROJECT_EXTENSION)
  result = newPreprodPreprocessor(filename, defines, getOptions(isProject), getCommands(isProject), getTranslator(isProject), getPreviewer(isProject))
  result.state.setPropertyValue(UNIM_FILE_KEY, filename.changeFileExt(NIM_EXTENSION))
  result.state.setPropertyValue(UNIM_FLUSH_KEY, if isProject: FLAG_NO else: FLAG_YES)
  result.state.setPropertyValue(UNIM_MODE_KEY, if isProject: MODE_STRICT else: MODE_FREE)
  result.state.setPropertyValue(UNIM_CLEANUP_KEY, VALUE_IGNORED)
  result.state.setPropertyValue(FREQ_IMPORTING_KEY, FREQUENCY_ALWAYS)
  result.state.setPropertyValue(FREQ_EXPORTING_KEY, FREQUENCY_ALWAYS)
