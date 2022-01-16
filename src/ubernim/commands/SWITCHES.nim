# ubernim / SWITCHES FEATURE #
#----------------------------#

import
  xam, preprod,
  commands,
  ../constants, ../errors

# CALLBACKS

topCallback doProject:
  if state.isTranslating():
    state.setPropertyValue(NIMC_PROJECT_KEY, parameters[0])
  return OK

topCallback doConfig:
  if state.isTranslating():
    state.setPropertyValue(NIMC_CFGFILE_KEY, parameters[0])
  return OK

topCallback doSwitch:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_SWITCHES_KEY, parameters[0])
  return OK

topCallback doDefine:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_DEFINES_KEY, parameters[0])
  return OK

topCallback doMinimum:
  if state.isPreviewing():
    if newSemanticVersion(NimMajor, NimMinor, NimPatch).isOlderThan(newSemanticVersion(parameters[0])):
      return errors.MINIMUM_NIM_VERSION
  return OK

# INITIALIZATION

proc initSWITCHES*(): UbernimFeature =
  initFeature "SWITCHES":
    cmd("nimc:project", PreprodArguments.uaOne, doProject)
    cmd("nimc:config", PreprodArguments.uaOne, doConfig)
    cmd("nimc:define", PreprodArguments.uaOne, doDefine)
    cmd("nimc:switch", PreprodArguments.uaOne, doSwitch)
    cmd("nimc:minimum", PreprodArguments.uaOne, doMinimum)
