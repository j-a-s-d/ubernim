# ubernim / UNIMCMDS FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../errors, ../constants, ../status

use strutils,toLower

# CALLBACKS

topCallback doVersion:
  if state.isPreviewing():
    let ls = loadUbernimStatus(state)
    if newSemanticVersion(parameters[0]).isNewerThan(ls.info.semver):
      return errors.BAD_VERSION(parenthesize(parameters[0]))
  return OK

topCallback doCleanup:
  if state.isTranslating():
    let value = parameters[0].toLower()
    if value notin [VALUE_IGNORED, VALUE_INFORMED, VALUE_PERFORMED]:
      return errors.BAD_CLEANUP
    state.setPropertyValue(UNIM_CLEANUP_KEY, value)
  return OK

topCallback doFlush:
  if state.isTranslating():
    let flag = parameters[0].toLower()
    if flag notin [FLAG_YES, FLAG_NO]:
      return errors.BAD_FLAG
    state.setPropertyValue(UNIM_FLUSH_KEY, flag)
  return OK

topCallback doMode:
  if state.isTranslating():
    let mode = parameters[0].toLower()
    if mode notin [MODE_FREE, MODE_STRICT]:
      return errors.BAD_MODE
    state.setPropertyValue(UNIM_MODE_KEY, mode)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "UNIMCMDS":
    cmd("unim:version", PreprodArguments.uaOne, doVersion)
    cmd("unim:cleanup", PreprodArguments.uaOne, doCleanup)
    cmd("unim:flush", PreprodArguments.uaOne, doFlush)
    cmd("unim:mode", PreprodArguments.uaOne, doMode)
