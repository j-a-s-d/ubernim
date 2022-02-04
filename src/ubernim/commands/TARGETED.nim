# ubernim / TARGETED FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../constants, ../errors, ../status, ../rendering

use strutils,toLower

template targetedSection(section: string) =
  if state.getPropertyValue(KEY_DIVISION) == DIVISIONS_TARGETED:
    let ls = loadUbernimStatus(state)
    if state.getPropertyValue(NIMC_TARGET_KEY) == ls.preprocessing.target:
      let wasEmitting = state.hasPropertyValue(KEY_SUBDIVISION) and
        state.getPropertyValue(KEY_SUBDIVISION) == SUBDIVISIONS_TARGETED_EMIT
      state.setPropertyValue(KEY_SUBDIVISION, section)
      if wasEmitting:
        return GOOD(CODEGEN_EMIT_CLOSE)

# CALLBACKS

topCallback doTargeted:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_TARGETED)
  if state.isTranslating():
    let target = parameters[0].toLower()
    if target notin NIMC_TARGETS:
      return errors.BAD_TARGET
    let ls = loadUbernimStatus(state)
    ls.preprocessing.target = target
  return OK

childCallback doTargetedPass:
  if state.isTranslating():
    targetedSection(SUBDIVISIONS_TARGETED_PASS)
  return OK

childCallback doTargetedCompile:
  if state.isTranslating():
    targetedSection(SUBDIVISIONS_TARGETED_COMPILE)
  return OK

childCallback doTargetedLink:
  if state.isTranslating():
    targetedSection(SUBDIVISIONS_TARGETED_LINK)
  return OK

childCallback doTargetedEmit:
  if state.isTranslating():
    targetedSection(SUBDIVISIONS_TARGETED_EMIT)
    return GOOD(CODEGEN_EMIT_OPEN)
  return OK

childCallback doTargetedEnd:
  if state.isTranslating():
    if state.getPropertyValue(KEY_DIVISION) == DIVISIONS_TARGETED:
      let r = if state.getPropertyValue(KEY_SUBDIVISION) == SUBDIVISIONS_TARGETED_EMIT:
        CODEGEN_EMIT_CLOSE
      else:
        STRINGS_EMPTY
      state.removePropertyValue(KEY_SUBDIVISION)
      state.removePropertyValue(KEY_DIVISION)
      let ls = loadUbernimStatus(state)
      ls.preprocessing.target = STRINGS_EMPTY
      return GOOD(r)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "TARGETED":
    cmd("targeted", PreprodArguments.uaOne, doTargeted)
    cmd("targeted:pass", PreprodArguments.uaNone, doTargetedPass)
    cmd("targeted:compile", PreprodArguments.uaNone, doTargetedCompile)
    cmd("targeted:link", PreprodArguments.uaNone, doTargetedLink)
    cmd("targeted:emit", PreprodArguments.uaNone, doTargetedEmit)
    cmd("targeted:end", PreprodArguments.uaNone, doTargetedEnd)
