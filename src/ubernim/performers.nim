# ubernim / PERFORMERS #
#----------------------#

import
  xam, preprod,
  language / header

var
  preprocessDoer*: DoubleArgsProc[string, LanguageState, var PreprodState]
  errorHandler*: SingleArgVoidProc[string]
  compilerInvoker*: DoubleArgsProc[string, StringSeq, int]
