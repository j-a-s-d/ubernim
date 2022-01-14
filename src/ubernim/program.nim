# ubernim / PROGRAM #
#-------------------#

import
  rodster, xam,
  errors, performers, preprocessing, compilation,
  language / [header, division, state]

use os,paramCount
use os,paramStr

const
  APP_VERSION_KEY = "app:version"
  APP_INPUT_KEY = "app:input"
  APP_ERRORLEVEL_KEY = "app:errorlevel"
  APP_USAGE_LINE = spaced(STRINGS_MINUS, "usage" & STRINGS_COLON, "ubernim", chevronize("input.file"))
  APP_EXAMPLE_LINE = spaced(STRINGS_MINUS, "example" & STRINGS_COLON, "ubernim", "myfile.unim")

let appEvents* = (
  initializer: RodsterAppEvent (app: RodsterApplication) => (
    # setup kvm
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    kvm[APP_VERSION_KEY] = spaced(nfo.getTitle(), STRINGS_LOWERCASE_V & $nfo.getVersion());
    if paramCount() == 1: kvm[APP_INPUT_KEY] = paramStr(1) else: die lined(kvm[APP_VERSION_KEY], STRINGS_EMPTY, APP_USAGE_LINE, STRINGS_EMPTY, APP_EXAMPLE_LINE, STRINGS_EMPTY);
    # setup performers
    UbernimPerformers.preprocessDoer = DefaultPreprocessDoer;
    UbernimPerformers.compilerInvoker = DefaultCompilerInvoker;
    UbernimPerformers.errorHandler = (msg: string) => die(spaced(ansiRed(spaced(STRINGS_ASTERISK, bracketize("ERROR"))), msg))
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
    freeLanguageState(state)
  ),
  finalizer: RodsterAppEvent (app: RodsterApplication) => (
    # inform result
    let errorlevel = tryParseInt(app.getKvm[APP_ERRORLEVEL_KEY], -1);
    let msg = spaced(STRINGS_ASTERISK, bracketize("DONE"), parenthesize($errorlevel));
    quit(spaced(if errorlevel == 0: ansiGreen(msg) else: ansiBlue(msg)), errorlevel)
  )
)
