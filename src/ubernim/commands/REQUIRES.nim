# ubernim / REQUIRES FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../constants, ../status

use strutils,toLower

# CALLBACKS

topCallback doRequire:
  result = OK
  if state.isPreviewing():
    let status = loadUbernimStatus(state)
    if checkFileExtension(parameters[0], UNIM_PROJECT_EXTENSION):
      return status.getError(errors.CANT_BE_REQUIRED)
    let fn = if extractFileExtension(parameters[0]) == STRINGS_EMPTY: parameters[0] & UNIM_EXTENSION else: parameters[0]
    if filesDontExist(fn):
      return status.getError(errors.INEXISTENT_FILE_REQUIRED, fn)
    if status.isMainFile(fn):
      return status.getError(errors.CANT_BE_REQUIRED)
    if status.isCurrentFile(fn):
      return status.getError(errors.NO_RECURSIVE_REQUIRE)
    if status.isCircularReference(fn):
      return status.getError(errors.NO_CIRCULAR_REFERENCE)
    var rls = makeUbernimStatus(status.info.semver, status.info.signature)
    rls.preprocessing.defines = status.preprocessing.defines
    rls.preprocessing.preprodFormatter = status.preprocessing.preprodFormatter
    rls.preprocessing.performingHandler = status.preprocessing.performingHandler
    rls.preprocessing.errorHandler = status.preprocessing.errorHandler
    rls.preprocessing.errorGetter = status.preprocessing.errorGetter
    rls.files.callstack.add(status.files.callstack & fn)
    var rstate = status.preprocessing.performingHandler(rls)
    status.files.generated.add(rls.files.generated)
    rls.language.divisions.each d:
      if d.public and not d.imported:
        let p = status.getDivision(d.name)
        if assigned(p):
          result = status.getError(errors.ALREADY_DEFINED, apostrophe(d.name))
          break
        d.imported = true
        status.language.divisions.add(d)
    freeUbernimStatus(rstate)
    reset(rstate)

topCallback doRequirable:
  if state.isPreviewing():
    let status = loadUbernimStatus(state)
    let flag = parameters[0].toLower()
    if flag notin [FLAG_YES, FLAG_NO]:
      return status.getError(errors.BAD_FLAG)
    if not status.inMainFile() and flag == FLAG_NO:
      return status.getError(errors.CANT_BE_REQUIRED)
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "REQUIRES":
    cmd("require", PreprodArguments.uaOne, doRequire)
    cmd("requirable", PreprodArguments.uaOne, doRequirable)
