# ubernim / PERFORMERS #
#----------------------#

import
  xam, preprod,
  status

type
  TUbernimPerformers = tuple
    preprocessDoer: DoubleArgsProc[string, UbernimStatus, var PreprodState]
    errorHandler: SingleArgVoidProc[string]
    compilerInvoker: DoubleArgsProc[string, StringSeq, int]

var
  UbernimPerformers*: TUbernimPerformers = (
    preprocessDoer: nil,
    errorHandler: nil,
    compilerInvoker: nil
  )
