# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

import
  rodster, xam,
  ubernim / [errors, performers, preprocessing, compilation, cleanup],
  ubernim / language / [header, division, state]

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

use os,paramCount
use os,paramStr

const
  APP_NAME = "ubernim"
  APP_VERSION = "0.4.3"
  APP_COPYRIGHT = "copyright (c) 2021-2022 by Javier Santo Domingo"
  APP_VERSION_KEY = "app:version"
  APP_INPUT_KEY = "app:input"
  APP_ERRORLEVEL_KEY = "app:errorlevel"
  APP_REPORT_KEY = "app:report"
  APP_USAGE_LINE = spaced(STRINGS_MINUS, "usage" & STRINGS_COLON, APP_NAME, chevronize("input.file"))
  APP_EXAMPLE_LINE = spaced(STRINGS_MINUS, "example" & STRINGS_COLON, APP_NAME, "myfile.unim")
  APP_ERROR_MSG = spaced(STRINGS_ASTERISK, bracketize("ERROR"))
  APP_DONE_MSG = spaced(STRINGS_ASTERISK, bracketize("DONE"))
  APP_VERSION_MSG = spaced(APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION)
  APP_TITLE_MSG = ansiMagenta(spaced(STRINGS_ASTERISK, APP_VERSION_MSG))
  APP_HELP_MSG = lined(APP_VERSION_MSG, STRINGS_EMPTY, APP_USAGE_LINE, STRINGS_EMPTY, APP_EXAMPLE_LINE, STRINGS_EMPTY)
  APP_ERROR_HANDLER = (msg: string) => die(spaced(ansiRed(APP_ERROR_MSG), msg))
  APP_CLEANUP_FORMATTER = proc (action, file: string): string = spaced(STRINGS_ASTERISK, parenthesize(action), file) & STRINGS_EOL

let events = (
  initializer: RodsterAppEvent (app: RodsterApplication) => (
    # setup kvm
    let kvm = app.getKvm();
    kvm[APP_VERSION_KEY] = APP_VERSION_MSG;
    if paramCount() == 1: kvm[APP_INPUT_KEY] = paramStr(1) else: die APP_HELP_MSG;
    if kvm[APP_INPUT_KEY] in ["-v", "--v", "/v", "-version", "--version", "/version"]: die lined(APP_VERSION_MSG, APP_COPYRIGHT);
    # setup performers
    UbernimPerformers.preprocessDoer = DefaultPreprocessDoer;
    UbernimPerformers.compilerInvoker = DefaultCompilerInvoker;
    UbernimPerformers.errorHandler = APP_ERROR_HANDLER
  ),
  main: RodsterAppEvent (app: RodsterApplication) => (
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    let ls = makeLanguageState();
    ls.semver = nfo.getVersion();
    ls.signature = spaced(WORDS_GENERATED, WORDS_WITH, kvm[APP_VERSION_KEY]);
    ls.callstack.add(kvm[APP_INPUT_KEY]);
    ls.divisions.add(makeDefaultDivisions());
    var state = UbernimPerformers.preprocessDoer(kvm[APP_INPUT_KEY], ls);
    silent () => (kvm[APP_ERRORLEVEL_KEY] = $compilationPerformer(state));
    kvm[APP_REPORT_KEY] = cleanupPerformer(state, APP_CLEANUP_FORMATTER);
    freeLanguageState(state)
  ),
  finalizer: RodsterAppEvent (app: RodsterApplication) => (
    let kvm = app.getKvm();
    # inform result
    let errorlevel = tryParseInt(kvm[APP_ERRORLEVEL_KEY], -1);
    let donemsg = spaced(APP_DONE_MSG, parenthesize($errorlevel));
    let output = kvm[APP_REPORT_KEY] & spaced(if errorlevel == 0: ansiGreen(donemsg) else: ansiBlue(donemsg));
    quit(lined(APP_TITLE_MSG, output), errorlevel)
  )
)

run newRodsterApplication(APP_NAME, APP_VERSION, events)
