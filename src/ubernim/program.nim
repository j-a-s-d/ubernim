# ubernim / PROGRAM #
#-------------------#

import
  rodster, xam, preprod,
  performers, preprocessing, rendering, errors, constants, compilation,
  language / [header, division, state]

use os,paramCount
use os,paramStr
use os,changeFileExt
use os,execShellCmd

const
  APP_VERSION_KEY = "app:version"
  APP_INPUT_KEY = "app:input"
  APP_ERRORLEVEL_KEY = "app:errorlevel"

proc showHelp(app: RodsterApplication) =
  let kvm = app.getKvm()
  echo kvm[APP_VERSION_KEY]
  echo ""
  echo "usage"
  echo "-----"
  echo ""
  echo "  ubernim <input.file>"
  echo "    -- example: ubernim myfile.unim"
  echo ""
  halt()

template err(msg: string) = die(ansiRed("* [ERROR] ") & msg)

template done(errorlevel: int) = quit(ansiGreen("* DONE " & parenthesize($errorlevel)), errorlevel)

errorHandler = (msg: string) => err msg

preprocessDoer = proc (filename: string, ls: LanguageState): var PreprodState =
  # setup preprocessor
  var pp = makePreprocessor(filename)
  storeLanguageState(pp.state, ls)
  pp.state.setPropertyValue(NIMC_PROJECT_KEY, filename.changeFileExt(NIM_EXTENSION))
  pp.state.setPropertyValue(UNIM_FLUSH_KEY, WORDS_YES)
  pp.state.setPropertyValue(UNIM_MODE_KEY, MODE_FREE)
  # run preprocessor
  var r = pp.run()
  if not r.ok:
    errorHandler(r.output)
  # emit output
  if pp.state.getPropertyValue(UNIM_FLUSH_KEY) == WORDS_YES:
    if not writeToFile(pp.state.getPropertyValue(NIMC_PROJECT_KEY), renderVersion(spaced(ls.unit, ls.signature)) & r.output):
      errorHandler(errors.CANT_WRITE_OUTPUT.output)
  pp.state

compilerInvoker = proc (project: string, defines: StringSeq): int =
  let cmd = spaced(NIMC_INVOKATION, spaced(defines), project)
  #let cres = execCmdEx(cmd, options = {poStdErrToStdOut})
  #echo cres.output
  #return cres.exitCode
  return execShellCmd(cmd)

# EVENTS

var appEvents*: RodsterAppEvents = DEFAULT_APPEVENTS

appEvents.initializer = (app: RodsterApplication) => (if paramCount() != 1: app.showHelp() else: app.getKvm[APP_INPUT_KEY] = paramStr(1))

appEvents.main = proc (app: RodsterApplication) =
  let kvm = app.getKvm()
  let nfo = app.getInformation()
  kvm[APP_VERSION_KEY] = spaced(nfo.getTitle(), STRINGS_LOWERCASE_V & $nfo.getVersion())
  var ls = makeLanguageState()
  ls.semver = nfo.getVersion()
  ls.signature = spaced(WORDS_GENERATED, WORDS_WITH, kvm[APP_VERSION_KEY])
  ls.unit = kvm[APP_INPUT_KEY]
  ls.main = ls.unit
  var state = preprocessDoer(ls.unit, ls)
  try:
    kvm[APP_ERRORLEVEL_KEY] = $compilationPerformer(state)
  finally:
    freeLanguageState(state)

appEvents.finalizer = (app: RodsterApplication) => done tryParseInt(app.getKvm[APP_ERRORLEVEL_KEY], -1)
