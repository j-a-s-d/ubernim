# ubernim / UNIMCMDS FEATURE #
#----------------------------#

import
  xam, preprod,
  commands,
  ../errors, ../constants,
  ../language / [header, state]

use strutils,toLower

# CALLBACKS

topCallback doVersion:
  if state.isPreviewing():
    let ls = loadLanguageState(state)
    if newSemanticVersion(parameters[0]).isNewerThan(ls.semver):
      return errors.BAD_VERSION(parenthesize(parameters[0]))
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

topCallback doImporting:
  if state.isTranslating():
    let frequency = parameters[0].toLower()
    if frequency notin [FREQUENCY_ALWAYS, FREQUENCY_ONCE]:
      return errors.BAD_FREQUENCY
    state.setPropertyValue(UNIM_IMPORTING_KEY, frequency)
  return OK

topCallback doExporting:
  if state.isTranslating():
    let frequency = parameters[0].toLower()
    if frequency notin [FREQUENCY_ALWAYS, FREQUENCY_ONCE]:
      return errors.BAD_FREQUENCY
    state.setPropertyValue(UNIM_EXPORTING_KEY, frequency)
  return OK

# INITIALIZATION

proc initUNIMCMDS*(): UbernimFeature =
  initFeature "UNIMCMDS":
    cmd("unim:version", PreprodArguments.uaOne, doVersion)
    cmd("unim:flush", PreprodArguments.uaOne, doFlush)
    cmd("unim:importing", PreprodArguments.uaOne, doImporting)
    cmd("unim:exporting", PreprodArguments.uaOne, doExporting)
    cmd("unim:mode", PreprodArguments.uaOne, doMode)
