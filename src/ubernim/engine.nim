# ubernim / ENGINE #
#------------------#

import
  xam, preprod,
  performers, status, preprocessing, compilation

proc setupPerformers*(errorHandler: SingleArgVoidProc[string], compilerInvoker: DoubleArgsProc[string, StringSeq, int] = SimpleCompilerInvoker, preprocessDoer: DoubleArgsProc[string, UbernimStatus, var PreprodState] = SimplePreprocessDoer) =
  UbernimPerformers.preprocessDoer = preprocessDoer
  UbernimPerformers.compilerInvoker = compilerInvoker
  UbernimPerformers.errorHandler = errorHandler

type
  UbernimInvokation* = tuple
    compilationErrorlevel: int
    cleanupReport: string

proc invokePerformers*(status: UbernimStatus, main: string, defines: StringSeq, cleanupFormatter: proc (action, file: string): string): UbernimInvokation =
  var res: UbernimInvokation
  status.defines = defines
  status.files.callstack.add(main)
  var state = UbernimPerformers.preprocessDoer(main, status);
  silent () => (res.compilationErrorlevel = compilationPerformer(state));
  res.cleanupReport = cleanupPerformer(state, cleanupFormatter);
  freeUbernimStatus(state)
  return res
