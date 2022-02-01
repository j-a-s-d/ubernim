# ubernim / ENGINE #
#------------------#

import
  xam, preprod,
  constants, errors, status, preprocessing, compilation, cleanup, rendering

use os,execShellCmd

# FIXED

proc performGeneration(status: UbernimStatus, filename, content, error: string) =
  if writeToFile(filename, content):
    status.files.generated.add(filename)
  else:
    status.preprocessing.errorHandler(error)

# OVERRIDABLE

let DefaultPreprocessingHandler = proc (status: UbernimStatus): var PreprodState =
  # setup preprocessor
  var pp = makePreprocessor(status.getCurrentFile())
  pp.state.defines = status.preprocessing.defines
  pp.state.storeUbernimStatus(status)
  # run preprocessor
  var r = pp.run()
  if not r.ok:
    status.preprocessing.errorHandler(r.output)
  # emit output
  if pp.state.getPropertyValue(UNIM_FLUSH_KEY) == FLAG_YES:
    let uf = pp.state.getPropertyValue(UNIM_FILE_KEY)
    performGeneration(status, uf, renderSignature(uf, status.info.signature) & r.output, errors.CANT_WRITE_OUTPUT.output)
  pp.state

# ENGINE

type
  UbernimEngine* = ref object
    version: SemanticVersion
    signature: string
    compilerInvoker: DoubleArgsProc[string, StringSeq, int]
    cleanupFormatter: DoubleArgsProc[string, string, string]
    errorHandler: SingleArgVoidProc[string]
    preprocessingHandler: SingleArgProc[UbernimStatus, var PreprodState]
  UbernimResult* = tuple
    compilationErrorlevel: int
    cleanupReport: string

proc newUbernimEngine*(version: SemanticVersion, signature: string): UbernimEngine =
  result = new UbernimEngine
  result.version = version
  result.signature = signature
  result.compilerInvoker = proc (project: string, defines: StringSeq): int = execShellCmd(spaced(NIMC_INVOKATION, spaced(defines), project))
  result.cleanupFormatter = proc (action, file: string): string = spaced(parenthesize(action), file)
  result.preprocessingHandler = DefaultPreprocessingHandler
  result.errorHandler = (msg: string) => quit(msg, 0)

proc setErrorHandler*(engine: UbernimEngine, errorHandler: SingleArgVoidProc[string]) =
  engine.errorHandler = errorHandler

proc setPreprocessingHandler*(engine: UbernimEngine, preprocessingHandler: SingleArgProc[UbernimStatus, var PreprodState]) =
  engine.preprocessingHandler = preprocessingHandler

proc setCompilerInvoker*(engine: UbernimEngine, compilerInvoker: DoubleArgsProc[string, StringSeq, int]) =
  engine.compilerInvoker = compilerInvoker

proc setCleanupFormatter*(engine: UbernimEngine, cleanupFormatter: DoubleArgsProc[string, string, string]) =
  engine.cleanupFormatter = cleanupFormatter

proc performCompilation(engine: UbernimEngine, state: var PreprodState): int =
  result = low(int)
  # setup defines
  var clDefs = buildCommandLineDefines(state)
  # setup switches
  var nimcSwitches = buildCommandLineSwitches(state)
  # setup config
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    let status = loadUbernimStatus(state)
    let cfg = state.getPropertyValue(NIMC_CFGFILE_KEY)
    performGeneration(status, cfg, lined(spaced(STRINGS_NUMERAL, cfg, status.info.signature) & nimcSwitches), errors.CANT_WRITE_CONFIG.output)
  else:
    clDefs &= nimcSwitches
  # compile
  return engine.compilerInvoker(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)

proc performCleanup(engine: UbernimEngine, state: var PreprodState): string =
  let value = state.getPropertyValue(UNIM_CLEANUP_KEY)
  if value != VALUE_IGNORED:
    let status = loadUbernimStatus(state)
    if value == VALUE_PERFORMED:
      return removeGeneratedFiles(status, engine.cleanupFormatter)
    else: # value == VALUE_INFORMED
      return informGeneratedFiles(status)

proc invokePerformers(engine: UbernimEngine, status: UbernimStatus): UbernimResult =
  var state = status.preprocessing.performingHandler(status)
  result.compilationErrorlevel = engine.performCompilation(state)
  result.cleanupReport = engine.performCleanup(state)
  freeUbernimStatus(state)

proc run*(engine: UbernimEngine, main: string, defines: StringSeq): UbernimResult =
  let status = makeUbernimStatus(engine.version, engine.signature)
  status.preprocessing.performingHandler = engine.preprocessingHandler
  status.preprocessing.errorHandler = engine.errorHandler
  status.preprocessing.defines = defines
  status.files.callstack.add(main)
  engine.invokePerformers(status)
