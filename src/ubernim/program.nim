# ubernim / PROGRAM #
#-------------------#

import
  rodster, xam, preprod,
  common, core, preprocessing, errors,
  language / [header, division, state]

use os,changeFileExt
use os,paramCount
use os,paramStr

# STEPS

preprocess = proc (filename: string, ls: LanguageState): var PreprodState =
  # setup preprocessor
  var pp = makePreprocessor(filename)
  storeLanguageState(pp.state, ls)
  pp.state.setPropertyValue(NIMC_PROJECT_KEY, filename.changeFileExt(NIM_EXTENSION))
  # run preprocessor
  var r = pp.run()
  if not r.ok:
    err r.output
  # emit output
  let ver = if hasText(ls.version): renderVersion(ls.version) else: STRINGS_EMPTY
  if not writeToFile(pp.state.getPropertyValue(NIMC_PROJECT_KEY), ver & r.output):
    err errors.CANT_WRITE_OUTPUT.output
  pp.state

compile = proc (state: var PreprodState): int =
  # setup defines
  var clDefs = newStringSeq()
  if state.hasPropertyValue(NIMC_DEFINES_KEY):
    for define in state.retrievePropertyValueAsSequence(NIMC_DEFINES_KEY):
      clDefs.add(NIM_DEFINE & define)
  # setup switches
  var nimcSwitches = newStringSeq()
  if state.hasPropertyValue(NIMC_SWITCHES_KEY):
    nimcSwitches = state.retrievePropertyValueAsSequence(NIMC_SWITCHES_KEY)
  # emit config and compile
  if state.hasPropertyValue(NIMC_CFGFILE_KEY):
    if not writeToFile(state.getPropertyValue(NIMC_CFGFILE_KEY), lined(nimcSwitches)):
      err errors.CANT_WRITE_CONFIG.output
  else:
    clDefs &= nimcSwitches
  return invokeCompiler(state.getPropertyValue(NIMC_PROJECT_KEY), clDefs)

# EVENTS

var appEvents*: RodsterAppEvents = DEFAULT_APPEVENTS

appEvents.initializer = proc (app: RodsterApplication) =
  if paramCount() != 1:
    app.showHelp()
    halt()
  let nfo = app.getInformation()
  let kvm = app.getKvm()
  kvm[APP_VERSION_KEY] = spaced(nfo.getTitle(), STRINGS_LOWERCASE_V & $nfo.getVersion())
  kvm[APP_INPUT_KEY] = paramStr(1)

appEvents.main = proc (app: RodsterApplication) =
  let kvm = app.getKvm()
  var ls = makeLanguageState()
  ls.version = kvm[APP_VERSION_KEY]
  ls.unit = kvm[APP_INPUT_KEY]
  var state = preprocess(ls.unit, ls)
  try:
    kvm[APP_ERRORLEVEL_KEY] = $compile(state)
  finally:
    freeLanguageState(state)

appEvents.finalizer = (app: RodsterApplication) => done tryParseInt(app.getKvm[APP_ERRORLEVEL_KEY], -1)
