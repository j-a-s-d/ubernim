# ubernim / SWITCHES FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../constants, ../status

use strutils,toLower

# CALLBACKS

topCallback doNimcTarget:
  if state.isTranslating():
    let target = parameters[0].toLower()
    if target notin NIMC_TARGETS:
      let status = loadUbernimStatus(state)
      return status.getError(errors.BAD_TARGET)
    state.setPropertyValue(NIMC_TARGET_KEY, target)
  return OK

topCallback doNimcProject:
  if state.isTranslating():
    state.setPropertyValue(NIMC_PROJECT_KEY, parameters[0])
  return OK

topCallback doNimcConfig:
  if state.isTranslating():
    state.setPropertyValue(NIMC_CFGFILE_KEY, parameters[0])
  return OK

topCallback doNimcSwitch:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_SWITCHES_KEY, parameters[0])
  return OK

topCallback doNimcDefine:
  if state.isTranslating():
    state.appendPropertyValueAsSequence(NIMC_DEFINES_KEY, parameters[0])
  return OK

topCallback doNimcMinimum:
  if state.isPreviewing():
    if newSemanticVersion(NimMajor, NimMinor, NimPatch).isOlderThan(newSemanticVersion(parameters[0])):
      let status = loadUbernimStatus(state)
      return status.getError(errors.MINIMUM_NIM_VERSION)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "SWITCHES":
    cmd("nimc:target", PreprodArguments.uaOne, doNimcTarget)
    cmd("nimc:project", PreprodArguments.uaOne, doNimcProject)
    cmd("nimc:config", PreprodArguments.uaOne, doNimcConfig)
    cmd("nimc:define", PreprodArguments.uaOne, doNimcDefine)
    cmd("nimc:switch", PreprodArguments.uaOne, doNimcSwitch)
    cmd("nimc:minimum", PreprodArguments.uaOne, doNimcMinimum)
