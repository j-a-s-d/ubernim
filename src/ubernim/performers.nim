# ubernim / PERFORMERS #
#----------------------#

import
  xam, preprod,
  language / header

type
  TUbernimPerformers = tuple
    preprocessDoer: DoubleArgsProc[string, LanguageState, var PreprodState]
    errorHandler: SingleArgVoidProc[string]
    compilerInvoker: DoubleArgsProc[string, StringSeq, int]

var
  UbernimPerformers*: TUbernimPerformers = (
    preprocessDoer: nil,
    errorHandler: nil,
    compilerInvoker: nil
  )
