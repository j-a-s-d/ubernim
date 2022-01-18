# ubernim / REQUIRES FEATURE #
#----------------------------#

import
  xam, preprod,
  commands,
  ../errors, ../performers, ../constants,
  ../language / [header, division, state]

use strutils,toLower

# CALLBACKS

topCallback doRequire:
  result = OK
  if state.isPreviewing():
    let ls = loadLanguageState(state)
    if ls.isMainFile(parameters[0]):
      return errors.CANT_BE_REQUIRED
    if ls.isCurrentFile(parameters[0]):
      return errors.NO_RECURSIVE_REQUIRE
    if ls.isCircularReference(parameters[0]):
      return errors.NO_CIRCULAR_REFERENCE
    var rls = makeLanguageState()
    rls.semver = ls.semver
    rls.signature = ls.signature
    rls.callstack.add(ls.callstack & parameters[0])
    rls.divisions.add(makeDefaultDivisions())
    var rstate = UbernimPerformers.preprocessDoer(parameters[0], rls)
    ls.generated.add(rls.generated)
    rls.divisions.each d:
      if d.public and not d.imported:
        let p = ls.getDivision(d.name)
        if assigned(p):
          result = errors.ALREADY_DEFINED(apostrophe(d.name))
          break
        d.imported = true
        ls.divisions.add(d)
    freeLanguageState(rstate)
    reset(rstate)

topCallback doRequirable:
  if state.isPreviewing():
    let flag = parameters[0].toLower()
    if flag notin [FLAG_YES, FLAG_NO]:
      return errors.BAD_FLAG
    let ls = loadLanguageState(state)
    if not ls.inMainFile() and flag == FLAG_NO:
      return errors.CANT_BE_REQUIRED
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "REQUIRES":
    cmd("require", PreprodArguments.uaOne, doRequire)
    cmd("requirable", PreprodArguments.uaOne, doRequirable)
