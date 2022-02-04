# ubernim / COMMANDS COMMON #
#---------------------------#

import
  xam, preprod,
  ../constants, ../errors

# FEATURES

type
  UbernimFeature* = tuple
    name: string
    commands: PreprodCommands

template initFeature*(feature: string, code: untyped): untyped =
  var r = UbernimFeature (name: feature, commands: @[])
  let cmd {.inject.} = (n: string, args: PreprodArguments, cb: PreprodCallback) =>
    r.commands.add(makeCommand(feature, n, args, cb))
  code
  r

# CALLBACKS

template callback(name, code: untyped): untyped =
  let name {.inject.}: PreprodCallback = proc (ustate: var PreprodState, params: StringSeq): PreprodResult =
    var state {.inject, used.} = ustate
    let parameters {.inject, used.} = params
    try:
      code
    except:
      return errors.UNEXPECTED(getCurrentExceptionMsg())

template topCallback*(name, code: untyped): untyped =
  callback name:
    if state.hasPropertyValue(KEY_DIVISION):
      return errors.ONLY_TOP_LEVEL
    code

template childCallback*(name, code: untyped): untyped =
  callback name:
    if not state.hasPropertyValue(KEY_DIVISION):
      return errors.DONT_TOP_LEVEL
    code

