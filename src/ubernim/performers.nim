# ubernim / PERFORMERS #
#----------------------#

import
  xam, preprod,
  status

type
  TUbernimPerformers = tuple
    preprocessDoer: SingleArgProc[UbernimStatus, var PreprodState]
    errorHandler: SingleArgVoidProc[string]

# CONFIGURABLE

var
  UbernimPerformers*: TUbernimPerformers = (
    preprocessDoer: nil,
    errorHandler: nil
  )