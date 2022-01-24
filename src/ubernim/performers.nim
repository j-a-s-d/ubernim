# ubernim / PERFORMERS #
#----------------------#

import
  xam, preprod,
  constants, errors, status, compilation, cleanup

type
  TUbernimPerformers = tuple
    preprocessDoer: DoubleArgsProc[string, UbernimStatus, var PreprodState]
    errorHandler: SingleArgVoidProc[string]
    compilerInvoker: DoubleArgsProc[string, StringSeq, int]

# CONFIGURABLE

var
  UbernimPerformers*: TUbernimPerformers = (
    preprocessDoer: nil,
    errorHandler: nil,
    compilerInvoker: nil
  )

# FIXED

let generationPerformer* = proc (filename, content, error: string, ls: UbernimStatus) =
  if writeToFile(filename, content):
    ls.files.generated.add(filename)
  else:
    UbernimPerformers.errorHandler(error)

let compilationPerformer* = proc (state: var PreprodState): int =
  result = low(int)
  # setup defines
  var clDefs = buildCommandLineDefines(state)
  # setup switches
  var nimcSwitches = buildCommandLineSwitches(state)
  # setup config
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    let ls = loadUbernimStatus(state)
    let cfg = state.getPropertyValue(NIMC_CFGFILE_KEY)
    generationPerformer(cfg, lined(spaced(STRINGS_NUMERAL, cfg, ls.info.signature) & nimcSwitches), errors.CANT_WRITE_CONFIG.output, ls)
  else:
    clDefs &= nimcSwitches
  # compile
  return UbernimPerformers.compilerInvoker(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)

let cleanupPerformer* = proc (state: var PreprodState, formatter: DoubleArgsProc[string, string, string]): string =
  let ls = loadUbernimStatus(state)
  let value = state.getPropertyValue(UNIM_CLEANUP_KEY)
  if value != VALUE_IGNORED:
    if value == VALUE_PERFORMED:
      return removeGeneratedFiles(ls, formatter)
    else: # value == VALUE_INFORMED
      return informGeneratedFiles(ls, formatter)
