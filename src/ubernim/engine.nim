# ubernim / ENGINE #
#------------------#

import
  xam, preprod,
  constants, errors, status, preprocessing, compilation, cleanup, rendering

type
  UbernimCompilerInvoker* = DoubleArgsProc[string, StringSeq, int]
  UbernimCleanupFormatter* = DoubleArgsProc[string, string, string]
  UbernimErrorHandler* = SingleArgVoidProc[string]
  UbernimPreprocessingHandler* = SingleArgProc[UbernimStatus, var PreprodState]
  UbernimResult* = tuple
    compilationErrorlevel: int
    cleanupReport: string
  UbernimEngine* = ref object
    version: SemanticVersion
    signature: string
    compilerInvoker: UbernimCompilerInvoker
    cleanupFormatter: UbernimCleanupFormatter
    errorHandler: UbernimErrorHandler
    preprocessingHandler: UbernimPreprocessingHandler

# DEFAULTS

use os,execShellCmd

let DefaultCompilerInvoker: UbernimCompilerInvoker = proc (project: string, defines: StringSeq): int =
  execShellCmd(spaced(NIMC_INVOKATION, spaced(defines), project))

let DefaultCleanupFormatter: UbernimCleanupFormatter = proc (action, file: string): string =
  spaced(parenthesize(action), file)

let DefaultErrorHandler: UbernimErrorHandler = proc (msg: string) =
  quit(msg, 0)

let DefaultPreprocessingHandler: UbernimPreprocessingHandler = proc (status: UbernimStatus): var PreprodState =
  # setup preprocessor
  var pp = makePreprocessor(status.getCurrentFile(), status.preprocessing.defines)
  pp.state.storeUbernimStatus(status)
  # run preprocessor
  var r = pp.run()
  if not r.ok:
    status.preprocessing.errorHandler(r.output)
  # emit output
  if pp.state.getPropertyValue(UNIM_FLUSH_KEY) == FLAG_YES:
    let uf = pp.state.getPropertyValue(UNIM_FILE_KEY)
    let txt = renderSignature(uf, status.info.signature) & r.output
    status.generateFile(uf, txt, errors.CANT_WRITE_OUTPUT.output)
  pp.state

# ENGINE

proc newUbernimEngine*(version: SemanticVersion, signature: string): UbernimEngine =
  result = new UbernimEngine
  result.version = version
  result.signature = signature
  result.compilerInvoker = DefaultCompilerInvoker
  result.cleanupFormatter = DefaultCleanupFormatter
  result.preprocessingHandler = DefaultPreprocessingHandler
  result.errorHandler = DefaultErrorHandler

proc setErrorHandler*(engine: UbernimEngine, handler: UbernimErrorHandler) =
  engine.errorHandler = handler

proc setPreprocessingHandler*(engine: UbernimEngine, handler: UbernimPreprocessingHandler) =
  engine.preprocessingHandler = handler

proc setCompilerInvoker*(engine: UbernimEngine, invoker: UbernimCompilerInvoker) =
  engine.compilerInvoker = invoker

proc setCleanupFormatter*(engine: UbernimEngine, formatter: UbernimCleanupFormatter) =
  engine.cleanupFormatter = formatter

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
    let txt = lined(spaced(STRINGS_NUMERAL, cfg, status.info.signature) & nimcSwitches)
    status.generateFile(cfg, txt, errors.CANT_WRITE_CONFIG.output)
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
