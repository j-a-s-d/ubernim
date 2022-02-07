# ubernim / REQUIRES FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../errors, ../constants, ../status

use strutils,toLower

# CALLBACKS

topCallback doRequire:
  result = OK
  if state.isPreviewing():
    let status = loadUbernimStatus(state)
    if status.isMainFile(parameters[0]):
      return errors.CANT_BE_REQUIRED
    if status.isCurrentFile(parameters[0]):
      return errors.NO_RECURSIVE_REQUIRE
    if status.isCircularReference(parameters[0]):
      return errors.NO_CIRCULAR_REFERENCE
    var rls = makeUbernimStatus(status.info.semver, status.info.signature)
    rls.files.callstack.add(status.files.callstack & parameters[0])
    rls.preprocessing.defines = status.preprocessing.defines
    rls.preprocessing.performingHandler = status.preprocessing.performingHandler
    rls.preprocessing.errorHandler = status.preprocessing.errorHandler
    var rstate = status.preprocessing.performingHandler(rls)
    status.files.generated.add(rls.files.generated)
    rls.language.divisions.each d:
      if d.public and not d.imported:
        let p = status.getDivision(d.name)
        if assigned(p):
          result = errors.ALREADY_DEFINED(apostrophe(d.name))
          break
        d.imported = true
        status.language.divisions.add(d)
    freeUbernimStatus(rstate)
    reset(rstate)

topCallback doRequirable:
  if state.isPreviewing():
    let flag = parameters[0].toLower()
    if flag notin [FLAG_YES, FLAG_NO]:
      return errors.BAD_FLAG
    let status = loadUbernimStatus(state)
    if not status.inMainFile() and flag == FLAG_NO:
      return errors.CANT_BE_REQUIRED
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "REQUIRES":
    cmd("require", PreprodArguments.uaOne, doRequire)
    cmd("requirable", PreprodArguments.uaOne, doRequirable)
