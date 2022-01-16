# ubernim / SHELLCMD FEATURE #
#----------------------------#

import
  xam, preprod,
  commands

use os,execShellCmd

# CALLBACKS

topCallback doExec:
  if state.isTranslating():
    discard execShellCmd(spaced(parameters))
  return OK

# INITIALIZATION

proc initSHELLCMD*(): UbernimFeature =
  initFeature "SHELLCMD":
    cmd("exec", PreprodArguments.uaNonZero, doExec)
