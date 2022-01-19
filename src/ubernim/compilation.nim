# ubernim / COMPILATION #
#-----------------------#

import
  xam, preprod,
  performers, constants, errors, status

use os,execShellCmd

func buildCommandLineDefines(state: PreprodState): StringSeq =
  result.add(if state.hasPropertyValue(NIMC_TARGET_KEY): state.getPropertyValue(NIMC_TARGET_KEY) else: TARGET_CC)
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      result.add(NIMC_DEFINE & define)

func buildCommandLineSwitches(state: PreprodState): StringSeq =
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    result.add(state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY))

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
    if writeToFile(cfg, lined(spaced(STRINGS_NUMERAL, cfg, ls.info.signature) & nimcSwitches)):
      ls.files.generated.add(cfg)
    else:
      UbernimPerformers.errorHandler(errors.CANT_WRITE_CONFIG.output)
  else:
    clDefs &= nimcSwitches
  # compile
  return UbernimPerformers.compilerInvoker(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)

let DefaultCompilerInvoker* = proc (project: string, defines: StringSeq): int =
  let cmd = spaced(NIMC_INVOKATION, spaced(defines), project)
  #let cres = execCmdEx(cmd, options = {poStdErrToStdOut})
  #echo cres.output
  #return cres.exitCode
  return execShellCmd(cmd)
