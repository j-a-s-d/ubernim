# ubernim / COMPILATION #
#-----------------------#

import
  xam, preprod,
  constants

use os,execShellCmd

func buildCommandLineDefines*(state: PreprodState): StringSeq =
  result.add(if state.hasPropertyValue(NIMC_TARGET_KEY): state.getPropertyValue(NIMC_TARGET_KEY) else: TARGET_CC)
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      result.add(NIMC_DEFINE & define)

func buildCommandLineSwitches*(state: PreprodState): StringSeq =
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    result.add(state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY))

let SimpleCompilerInvoker* = proc (project: string, defines: StringSeq): int =
  let cmd = spaced(NIMC_INVOKATION, spaced(defines), project)
  #let cres = execCmdEx(cmd, options = {poStdErrToStdOut})
  #echo cres.output
  #return cres.exitCode
  return execShellCmd(cmd)
