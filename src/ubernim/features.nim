# ubernim / FEATURES #
#--------------------#

import
  xam, preprod,
  callbacks

type
  UbernimFeature = tuple
    name: string
    commands: PreprodCommands

proc initUNIMCMDS(): UbernimFeature =
  const FEATURE = "UNIMCMDS"
  (
    name: FEATURE,
    commands: @[
      makeCommand(FEATURE, "unim:version", PreprodArguments.uaOne, doVersion),
      makeCommand(FEATURE, "unim:flush", PreprodArguments.uaOne, doFlush)
    ]
  )

proc initSWITCHES(): UbernimFeature =
  const FEATURE = "SWITCHES"
  (
    name: FEATURE,
    commands: @[
      makeCommand(FEATURE, "nimc:project", PreprodArguments.uaOne, doProject),
      makeCommand(FEATURE, "nimc:config", PreprodArguments.uaOne, doConfig),
      makeCommand(FEATURE, "nimc:define", PreprodArguments.uaOne, doDefine),
      makeCommand(FEATURE, "nimc:switch", PreprodArguments.uaOne, doSwitch)
    ]
  )

proc initSHELLCMD(): UbernimFeature =
  const FEATURE = "SHELLCMD"
  (
    name: FEATURE,
    commands: @[
      makeCommand(FEATURE, "exec", PreprodArguments.uaNonZero, doExec)
    ]
  )

proc initFSACCESS(): UbernimFeature =
  const FEATURE = "FSACCESS"
  (
    name: FEATURE,
    commands: @[
      makeCommand(FEATURE, "copy", PreprodArguments.uaTwo, doCopy),
      makeCommand(FEATURE, "move", PreprodArguments.uaTwo, doMove),
      makeCommand(FEATURE, "remove", PreprodArguments.uaOne, doRemove),
      makeCommand(FEATURE, "write", PreprodArguments.uaNonZero, doWrite),
      makeCommand(FEATURE, "append", PreprodArguments.uaNonZero, doAppend),
      makeCommand(FEATURE, "mkdir", PreprodArguments.uaOne, doMkDir),
      makeCommand(FEATURE, "chdir", PreprodArguments.uaOne, doChDir),
      makeCommand(FEATURE, "cpdir", PreprodArguments.uaTwo, doCpDir),
      makeCommand(FEATURE, "rmdir", PreprodArguments.uaOne, doRmDir)
    ]
  )

proc initREQUIRES(): UbernimFeature =
  const FEATURE = "REQUIRES"
  (
    name: FEATURE,
    commands: @[
      makeCommand(FEATURE, "require", PreprodArguments.uaOne, doRequire),
      makeCommand(FEATURE, "requirable", PreprodArguments.uaOne, doRequirable)
    ]
  )

proc initLANGUAGE(): UbernimFeature =
  const FEATURE = "LANGUAGE"
  (
    name: FEATURE,
    commands: @[
      makeCommand(FEATURE, "note", PreprodArguments.uaNone, doNote),
      makeCommand(FEATURE, "push", PreprodArguments.uaNonZero, doPush),
      makeCommand(FEATURE, "pop", PreprodArguments.uaNone, doPop),
      makeCommand(FEATURE, "pragmas", PreprodArguments.uaNonZero, doPragmas),
      makeCommand(FEATURE, "class", PreprodArguments.uaNonZero, doClass),
      makeCommand(FEATURE, "record", PreprodArguments.uaOne, doRecord),
      makeCommand(FEATURE, "compound", PreprodArguments.uaOne, doCompound),
      makeCommand(FEATURE, "interface", PreprodArguments.uaOne, doInterface),
      makeCommand(FEATURE, "protocol", PreprodArguments.uaOne, doProtocol),
      makeCommand(FEATURE, "applies", PreprodArguments.uaOne, doApplies),
      makeCommand(FEATURE, "implies", PreprodArguments.uaOne, doImplies),
      makeCommand(FEATURE, "extends", PreprodArguments.uaOne, doExtends),
      makeCommand(FEATURE, "fields", PreprodArguments.uaNone, doFields),
      makeCommand(FEATURE, "methods", PreprodArguments.uaNone, doMethods),
      makeCommand(FEATURE, "templates", PreprodArguments.uaNone, doTemplates),
      makeCommand(FEATURE, "docs", PreprodArguments.uaNone, doDocs),
      makeCommand(FEATURE, "constructor", PreprodArguments.uaNonZero, doConstructor),
      makeCommand(FEATURE, "getter", PreprodArguments.uaNonZero, doGetter),
      makeCommand(FEATURE, "setter", PreprodArguments.uaNonZero, doSetter),
      makeCommand(FEATURE, "method", PreprodArguments.uaNonZero, doMethod),
      makeCommand(FEATURE, "template", PreprodArguments.uaNonZero, doTemplate),
      makeCommand(FEATURE, "routine", PreprodArguments.uaNonZero, doRoutine),
      makeCommand(FEATURE, "code", PreprodArguments.uaNone, doCode),
      makeCommand(FEATURE, "end", PreprodArguments.uaNone, doEnd)
    ]
  )

let
  UbernimFeatures* = (
    UNIMCMDS: initUNIMCMDS(), # ubernim general commands
    SWITCHES: initSWITCHES(), # nim compiler command line switches
    SHELLCMD: initSHELLCMD(), # os shell commands execution
    FSACCESS: initFSACCESS(), # os filesystem access
    REQUIRES: initREQUIRES(), # ubernim external files requirement (differs from INCLUDE in that the required modules are preprocessed separatelly)
    LANGUAGE: initLANGUAGE()  # ubernim language extensions
  )
