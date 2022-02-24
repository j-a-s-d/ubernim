# ubernim / UNIMCMDS FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../constants, ../status

use strutils,toLower

# CALLBACKS

topCallback doVersion:
  if state.isPreviewing():
    let status = loadUbernimStatus(state)
    if not isValidSemanticVersionString(parameters[0]):
      return status.getError(errors.BAD_VERSION)
    if newSemanticVersion(parameters[0]).isNewerThan(status.info.semver):
      return status.getError(errors.OLD_VERSION, parenthesize(parameters[0]))
  return OK

topCallback doCleanup:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    let value = parameters[0].toLower()
    if value notin [VALUE_IGNORED, VALUE_INFORMED, VALUE_PERFORMED]:
      return status.getError(errors.BAD_CLEANUP)
    state.setPropertyValue(UNIM_CLEANUP_KEY, value)
  return OK

topCallback doFlush:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    let flag = parameters[0].toLower()
    if flag notin [FLAG_YES, FLAG_NO]:
      return status.getError(errors.BAD_FLAG)
    state.setPropertyValue(UNIM_FLUSH_KEY, flag)
  return OK

topCallback doMode:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    let mode = parameters[0].toLower()
    if mode notin [MODE_FREE, MODE_STRICT]:
      return status.getError(errors.BAD_MODE)
    state.setPropertyValue(UNIM_MODE_KEY, mode)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "UNIMCMDS":
    cmd("unim:version", PreprodArguments.uaOne, doVersion)
    cmd("unim:cleanup", PreprodArguments.uaOne, doCleanup)
    cmd("unim:flush", PreprodArguments.uaOne, doFlush)
    cmd("unim:mode", PreprodArguments.uaOne, doMode)
