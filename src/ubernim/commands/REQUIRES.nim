# ubernim / REQUIRES FEATURE #
#----------------------------#

import
  xam, preprod,
  commands,
  ../errors, ../performers, ../constants, ../status,
  ../language / [header, division]

use strutils,toLower

# CALLBACKS

topCallback doRequire:
  result = OK
  if state.isPreviewing():
    let ls = loadUbernimStatus(state)
    if ls.isMainFile(parameters[0]):
      return errors.CANT_BE_REQUIRED
    if ls.isCurrentFile(parameters[0]):
      return errors.NO_RECURSIVE_REQUIRE
    if ls.isCircularReference(parameters[0]):
      return errors.NO_CIRCULAR_REFERENCE
    var rls = makeUbernimStatus()
    rls.info.semver = ls.info.semver
    rls.info.signature = ls.info.signature
    rls.files.callstack.add(ls.files.callstack & parameters[0])
    rls.language.divisions.add(makeDefaultDivisions())
    var rstate = UbernimPerformers.preprocessDoer(parameters[0], rls)
    ls.files.generated.add(rls.files.generated)
    rls.language.divisions.each d:
      if d.public and not d.imported:
        let p = ls.getDivision(d.name)
        if assigned(p):
          result = errors.ALREADY_DEFINED(apostrophe(d.name))
          break
        d.imported = true
        ls.language.divisions.add(d)
    freeUbernimStatus(rstate)
    reset(rstate)

topCallback doRequirable:
  if state.isPreviewing():
    let flag = parameters[0].toLower()
    if flag notin [FLAG_YES, FLAG_NO]:
      return errors.BAD_FLAG
    let ls = loadUbernimStatus(state)
    if not ls.inMainFile() and flag == FLAG_NO:
      return errors.CANT_BE_REQUIRED
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "REQUIRES":
    cmd("require", PreprodArguments.uaOne, doRequire)
    cmd("requirable", PreprodArguments.uaOne, doRequirable)
