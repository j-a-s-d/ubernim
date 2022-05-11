# ubernim / ENGINE #
#------------------#

import
  xam, preprod,
  constants, status, preprocessing, compilation, cleanup, rendering

export
  UbernimErrorHandler,
  UbernimErrorGetter,
  UbernimPreprocessingHandler

# TYPES

type
  UbernimCompilerInvoker* = DoubleArgsProc[string, StringSeq, int]
  UbernimCleanupFormatter* = DoubleArgsProc[string, string, string]
  UbernimEngine* = ref object
    version: SemanticVersion
    signature: string
    compilerInvoker: UbernimCompilerInvoker
    cleanupFormatter: UbernimCleanupFormatter
    errorGetter: UbernimErrorGetter
    errorHandler: UbernimErrorHandler
    executableInvoker: UbernimExecutableInvoker
    preprocessingHandler: UbernimPreprocessingHandler

# DEFAULTS

use os,execShellCmd
use os,getCurrentDir
use os,setCurrentDir
use strutils,endsWith

proc getDestinationDirectory(status: UbernimStatus, state: PreprodState): string =
  result = STRINGS_EMPTY
  if state.hasPropertyValue(UNIM_DESTINATION_KEY):
    let value = state.getPropertyValue(UNIM_DESTINATION_KEY)
    if value != DEFAULT_DIR:
      status.generateDirectory(value)
      return value

let DefaultCompilerInvoker: UbernimCompilerInvoker = proc (project: string, defines: StringSeq): int =
  execShellCmd(spaced(NIMC_INVOKATION, spaced(defines), project))

let DefaultCleanupFormatter: UbernimCleanupFormatter = proc (action, file: string): string =
  spaced(parenthesize(action), file)

let DefaultErrorHandler: UbernimErrorHandler = proc (msg: string) =
  quit(msg, -1)

let DefaultErrorGetter: UbernimErrorGetter = proc (msg: string, values: varargs[string]): string =
  msg

let DefaultExecutableInvoker: UbernimExecutableInvoker = proc (definesCsv, file: string): bool =
  execShellCmd(spaced(UNIM_INVOKATION, NIMC_DEFINE & definesCsv, file)) != 0

let DefaultPreprocessingHandler: UbernimPreprocessingHandler = proc (status: UbernimStatus): var PreprodState =
  # setup preprocessor
  var pp = makePreprocessor(status.projecting.isUnimp, status.getCurrentFile(), status.preprocessing.defines)
  pp.state.storeUbernimStatus(status)
  # run preprocessor
  var r = pp.run()
  if not r.ok:
    status.preprocessing.errorHandler(r.output)
  # emit output
  if pp.state.getPropertyValue(UNIM_FLUSH_KEY) == FLAG_YES:
    let destination = getDestinationDirectory(status, pp.state)
    let uf = destination & pp.state.getPropertyValue(UNIM_FILE_KEY)
    let txt = renderSignature(uf, status.info.signature) & r.output
    status.generateFile(uf, txt, "errors.CANT_WRITE_OUTPUT")
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
  result.errorGetter = DefaultErrorGetter
  result.executableInvoker = DefaultExecutableInvoker

proc setExecutableInvoker*(engine: UbernimEngine, handler: UbernimExecutableInvoker) =
  engine.executableInvoker = handler

proc setErrorGetter*(engine: UbernimEngine, handler: UbernimErrorGetter) =
  engine.errorGetter = handler

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
  let status = loadUbernimStatus(state)
  let destination = getDestinationDirectory(status, state)
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    let cfg = destination & state.getPropertyValue(NIMC_CFGFILE_KEY)
    let txt = lined(spaced(STRINGS_NUMERAL, cfg, status.info.signature) & nimcSwitches)
    status.generateFile(cfg, txt, "errors.CANT_WRITE_CONFIG")
  else:
    clDefs &= nimcSwitches
  # compile
  if state.hasPropertyValue(NIMC_PROJECT_KEY):
    return engine.compilerInvoker(destination & state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)

proc performCleanup(engine: UbernimEngine, state: var PreprodState): string =
  withIt state.getPropertyValue(UNIM_CLEANUP_KEY):
    if it != VALUE_IGNORED:
      let status = loadUbernimStatus(state)
      return if it == VALUE_PERFORMED:
        removeGeneratedFiles(status, engine.cleanupFormatter)
      else: # value == VALUE_INFORMED
        informGeneratedFiles(status, engine.cleanupFormatter)

proc invokePerformers(engine: UbernimEngine, status: UbernimStatus): UbernimResult =
  let dir = getCurrentDir()
  var state = status.preprocessing.performingHandler(status)
  setCurrentDir(dir)
  result.isProject = status.projecting.isUnimp
  result.compilationErrorlevel = engine.performCompilation(state)
  result.cleanupReport = if result.compilationErrorlevel == 0: engine.performCleanup(state) else: STRINGS_EMPTY
  freeUbernimStatus(state)

proc run*(engine: UbernimEngine, main: string, defines: StringSeq): UbernimResult =
  var status = makeUbernimStatus(engine.version, engine.signature)
  status.preprocessing.performingHandler = engine.preprocessingHandler
  status.preprocessing.errorHandler = engine.errorHandler
  status.preprocessing.errorGetter = engine.errorGetter
  status.preprocessing.executableInvoker = engine.executableInvoker
  status.preprocessing.defines = defines
  status.projecting.isUnimp = main.endsWith(UNIM_PROJECT_EXTENSION)
  status.files.callstack.add(main)
  engine.invokePerformers(status)
