# ubernim / FSACCESS FEATURE #
#----------------------------#

import
  xam, preprod,
  common,
  ../status

use os,setCurrentDir
use os,dirExists
use os,createDir
use os,copyDir
use os,removeDir
use os,copyFile
use os,moveFile
use os,tryRemoveFile

# CALLBACKS

topCallback doChDir:
  if state.isTranslating():
    setCurrentDir(parameters[0])
  return OK

topCallback doMkDir:
  if state.isTranslating():
    # NOTE: avoid using existsOrCreateDir
    if not dirExists(parameters[0]):
      createDir(parameters[0])
    if not dirExists(parameters[0]):
      let status = loadUbernimStatus(state)
      return status.getError("errors.CANT_CREATE_DIRECTORY", apostrophe(parameters[0]))
  return OK

topCallback doCpDir:
  if state.isTranslating():
    copyDir(parameters[0], parameters[1])
  return OK

topCallback doRmDir:
  if state.isTranslating():
    removeDir(parameters[0])
  return OK

topCallback doCopy:
  if state.isTranslating():
    copyFile(parameters[0], parameters[1])
  return OK

topCallback doMove:
  if state.isTranslating():
    moveFile(parameters[0], parameters[1])
  return OK

topCallback doAppend:
  if state.isTranslating():
    if not appendToFile(parameters[0], if parameters.len == 1: STRINGS_EMPTY else: spaced(parameters[1..^1])):
      let status = loadUbernimStatus(state)
      return status.getError("errors.CANT_APPEND_FILE", apostrophe(parameters[0]))
  return OK

topCallback doWrite:
  if state.isTranslating():
    if not writeToFile(parameters[0], if parameters.len == 1: STRINGS_EMPTY else: spaced(parameters[1..^1])):
      let status = loadUbernimStatus(state)
      return status.getError("errors.CANT_WRITE_FILE", apostrophe(parameters[0]))
  return OK

topCallback doRemove:
  if state.isTranslating():
    if not tryRemoveFile(parameters[0]):
      let status = loadUbernimStatus(state)
      return status.getError("errors.CANT_REMOVE_FILE", apostrophe(parameters[0]))
  return OK

# INITIALIZATION

proc initialize*(): UbernimFeature =
  initFeature "FSACCESS":
    cmd("copy", PreprodArguments.uaTwo, doCopy)
    cmd("move", PreprodArguments.uaTwo, doMove)
    cmd("remove", PreprodArguments.uaOne, doRemove)
    cmd("write", PreprodArguments.uaNonZero, doWrite)
    cmd("append", PreprodArguments.uaNonZero, doAppend)
    cmd("mkdir", PreprodArguments.uaOne, doMkDir)
    cmd("chdir", PreprodArguments.uaOne, doChDir)
    cmd("cpdir", PreprodArguments.uaTwo, doCpDir)
    cmd("rmdir", PreprodArguments.uaOne, doRmDir)
