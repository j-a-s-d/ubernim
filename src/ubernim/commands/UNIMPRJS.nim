# ubernim / UNIMPRJS FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../errors, ../constants, ../status

use strutils,join
use strutils,split
use strutils,strip
use sequtils,filter
use os,execShellCmd

# CALLBACKS

topCallback doProject:
  state.setPropertyValue(KEY_DIVISION, DIVISIONS_PROJECT)
  if state.isTranslating():
    let name = strip(parameters[0])
    if not isValidNimIdentifier(name):
      return errors.INVALID_IDENTIFIER
    let status = loadUbernimStatus(state)
    status.openProject(name)
  return OK

childCallback doDefines:
  if state.isTranslating():
    if fetchDivision(state) != DIVISIONS_PROJECT:
      return errors.NOT_IN_PROJECT
    let status = loadUbernimStatus(state)
    if not status.inProject():
      return errors.BAD_STATE
    parameters.join(STRINGS_SPACE).split(STRINGS_COMMA).each u:
      status.addDefineToCurrentProject(strip(u))
  return OK

childCallback doUndefines:
  if state.isTranslating():
    if fetchDivision(state) != DIVISIONS_PROJECT:
      return errors.NOT_IN_PROJECT
    let status = loadUbernimStatus(state)
    if not status.inProject():
      return errors.BAD_STATE
    parameters.join(STRINGS_SPACE).split(STRINGS_COMMA).each u:
      status.addUndefineToCurrentProject(strip(u))
  return OK

childCallback doMain:
  if state.isTranslating():
    if fetchDivision(state) != DIVISIONS_PROJECT:
      return errors.NOT_IN_PROJECT
    let status = loadUbernimStatus(state)
    if not status.inProject():
      return errors.BAD_STATE
    status.setMainToCurrentProject(strip(parameters[0]))
  return OK

childCallback doEnd:
  let d = fetchDivision(state)
  unsetDivision(state)
  unsetSubdivision(state)
  if state.isTranslating():
    if d != DIVISIONS_PROJECT:
      return errors.NOT_IN_PROJECT
    let status = loadUbernimStatus(state)
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
        if execShellCmd(spaced(status.files.executable, prj.main, NIMC_DEFINE & defines.filter((it) => it != STRINGS_EMPTY).join(STRINGS_COMMA))) != 0:
          return errors.FAILURE_PROCESSING(prj.name)
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
