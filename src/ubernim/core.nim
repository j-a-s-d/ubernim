# ubernim / CORE #
#----------------#

import
  xam, preprod,
  errors,
  language / [header, state]

reexport(rendering, rendering)

# CONSTANTS

const
  UNIM_FLUSH_KEY* = "UNIM_FLUSH"
  NIMC_DEFINES_KEY* = "NIMC_DEFINES"
  NIMC_SWITCHES_KEY* = "NIMC_SWITCHES"
  NIMC_CFGFILE_KEY* = "NIMC_CFGFILE"
  NIMC_PROJECT_KEY* = "NIMC_PROJECT"
  NIMC_INVOKATION* = "nim c"
  NIMC_DEFINE* = "--define:"

# GLOBALS

var
  preprocessPerformer*: DoubleArgsProc[string, LanguageState, var PreprodState]
  errorHandler*: SingleArgVoidProc[string]
  compilerInvoker*: DoubleArgsProc[string, StringSeq, int]

let compilationPerformer* = proc (state: var PreprodState): int =
  result = low(int)
  # setup defines
  var clDefs = newStringSeq()
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      clDefs.add(NIMC_DEFINE & define)
  # setup switches
  var nimcSwitches = newStringSeq()
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    nimcSwitches = state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY)
  # emit config and compile
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    let ls = loadLanguageState(state)
    let cfg = state.getPropertyValue(NIMC_CFGFILE_KEY)
    if not writeToFile(cfg, lined(spaced(STRINGS_NUMERAL, cfg, ls.signature) & nimcSwitches)):
      errorHandler(errors.CANT_WRITE_CONFIG.output)
  else:
    clDefs &= nimcSwitches
  return compilerInvoker(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)
