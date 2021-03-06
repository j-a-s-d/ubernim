# ubernim / UNIMPRJS FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../constants, ../status

use strutils,join
use strutils,split
use strutils,strip
use sequtils,filter

# CALLBACKS

topCallback doProject:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_PROJECT)
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    let name = strip(parameters[0])
    if not isValidNimIdentifier(name):
      return status.getError(errors.INVALID_IDENTIFIER)
    status.openProject(name)
  return OK

childCallback doDefines:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    if fetchDivision(state) != DIVISIONS_PROJECT:
      return status.getError(errors.NOT_IN_PROJECT)
    if not status.inProject():
      return status.getError(errors.BAD_STATE)
    parameters.join(STRINGS_SPACE).split(STRINGS_COMMA).each u:
      status.addDefineToCurrentProject(strip(u))
  return OK

childCallback doUndefines:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    if fetchDivision(state) != DIVISIONS_PROJECT:
      return status.getError(errors.NOT_IN_PROJECT)
    if not status.inProject():
      return status.getError(errors.BAD_STATE)
    parameters.join(STRINGS_SPACE).split(STRINGS_COMMA).each u:
      status.addUndefineToCurrentProject(strip(u))
  return OK

childCallback doMain:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    if fetchDivision(state) != DIVISIONS_PROJECT:
      return status.getError(errors.NOT_IN_PROJECT)
    if not status.inProject():
      return status.getError(errors.BAD_STATE)
    status.setMainToCurrentProject(strip(parameters[0]))
  return OK

childCallback doEnd:
  let d = fetchDivision(state)
  unsetDivision(state)
  unsetSubdivision(state)
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    if d != DIVISIONS_PROJECT:
      return status.getError(errors.NOT_IN_PROJECT)
    status.closeProject()
  return OK

topCallback doMake:
  if state.isTranslating():
    let status = loadUbernimStatus(state)
    let name = strip(parameters[0])
    status.projecting.projects.each prj:
      if prj.name == name:
        var defines = status.preprocessing.defines
        prj.defines.each define: defines.add(define)
        prj.undefines.each define: defines.remove(define)
        if status.preprocessing.executableInvoker(defines.filter((it) => it != STRINGS_EMPTY).join(STRINGS_COMMA), prj.main):
          return status.getError(errors.FAILURE_PROCESSING, prj.name)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "UNIMPRJS":
    cmd("project", PreprodArguments.uaOne, doProject)
    cmd("defines", PreprodArguments.uaNonZero, doDefines)
    cmd("undefines", PreprodArguments.uaNonZero, doUndefines)
    cmd("main", PreprodArguments.uaOne, doMain)
    cmd("end", PreprodArguments.uaNone, doEnd)
    cmd("make", PreprodArguments.uaOne, doMake)
