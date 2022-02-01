# ubernim / ENGINE #
#------------------#

import
  xam, preprod,
  performers, status, preprocessing, compilation

type
  UbernimEngine* = ref object
    version: SemanticVersion
    signature: string
  UbernimResult* = tuple
    compilationErrorlevel: int
    cleanupReport: string

proc invokePerformers(status: UbernimStatus): UbernimResult =
  var state = UbernimPerformers.preprocessDoer(status)
  result.compilationErrorlevel = compilationPerformer(state)
  result.cleanupReport = cleanupPerformer(state)
  freeUbernimStatus(state)

proc newUbernimEngine*(version: SemanticVersion, signature: string): UbernimEngine =
  result = new UbernimEngine
  result.version = version
  result.signature = signature

proc setupPerformers*(engine: UbernimEngine, errorHandler: SingleArgVoidProc[string], cleanupFormatter: DoubleArgsProc[string, string, string], compilerInvoker: DoubleArgsProc[string, StringSeq, int] = SimpleCompilerInvoker, preprocessDoer: SingleArgProc[UbernimStatus, var PreprodState] = SimplePreprocessDoer) =
  UbernimPerformers.preprocessDoer = preprocessDoer
  UbernimPerformers.compilerInvoker = compilerInvoker
  UbernimPerformers.errorHandler = errorHandler
  UbernimPerformers.cleanupFormatter = cleanupFormatter

proc run*(engine: UbernimEngine, main: string, defines: StringSeq): UbernimResult =
  let status = makeUbernimStatus(engine.version, engine.signature)
  status.defines = defines
  status.files.callstack.add(main)
  invokePerformers(status)
