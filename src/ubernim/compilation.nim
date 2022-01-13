# ubernim / COMPILATION #
#-----------------------#

import
  xam, preprod,
  performers, constants, errors,
  language / state

func buildCommandLineDefines(state: PreprodState): StringSeq =
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      result.add(NIMC_DEFINE & define)

func buildCommandLineSwitches(state: PreprodState): StringSeq =
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    result = state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY)

let compilationPerformer* = proc (state: var PreprodState): int =
  result = low(int)
  # setup defines
  var clDefs = buildCommandLineDefines(state)
  # setup switches
  var nimcSwitches = buildCommandLineSwitches(state)
  # setup config
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    let ls = loadLanguageState(state)
    let cfg = state.getPropertyValue(NIMC_CFGFILE_KEY)
    if not writeToFile(cfg, lined(spaced(STRINGS_NUMERAL, cfg, ls.signature) & nimcSwitches)):
      errorHandler(errors.CANT_WRITE_CONFIG.output)
  else:
    clDefs &= nimcSwitches
  # compile
  return compilerInvoker(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)