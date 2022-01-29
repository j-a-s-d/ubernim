# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

# IMPORTS

import
  rodster, xam,
  ubernim / [errors, performers, status, preprocessing, compilation],
  ubernim / language / implementation

use strutils,split
use strutils,join
use strutils,replace

# CONSTANTS

const
  APP_NAME = "ubernim"
  APP_VERSION = "0.5.0"
  APP_VERSION_TEXT = spaced(APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION)
  APP_COPYRIGHT_TEXT = "copyright (c) 2021-2022 by Javier Santo Domingo"
  APP_VERSION_KEY = "app:version"
  APP_INPUT_KEY = "app:input"
  APP_DEFINES_KEY = "app:defines"
  APP_ERRORLEVEL_KEY = "app:errorlevel"
  APP_REPORT_KEY = "app:report"
  APP_ERROR_MSG = spaced(STRINGS_ASTERISK, bracketize("ERROR"))
  APP_DONE_MSG = spaced(STRINGS_ASTERISK, bracketize("DONE"))
  APP_TITLE_MSG = ansiMagenta(spaced(STRINGS_ASTERISK, APP_VERSION_TEXT))
  APP_ERROR_HANDLER = (msg: string) => quit(spaced(ansiRed(APP_ERROR_MSG), msg), 0)
  APP_CLEANUP_FORMATTER = proc (action, file: string): string = spaced(STRINGS_ASTERISK, parenthesize(action), file) & STRINGS_EOL
  APP_DEFINE_SWITCHES = ["-d:", "--define:"]
  APP_VERSION_SWITCHES = ["-v", "--version"]
  APP_HELP_SWITCHES = ["-h", "--help", "-?", "/?", "?"]
  APP_FLAGS_LINE = spaced(STRINGS_MINUS, lined(
    "flags" & STRINGS_COLON,
    spaced(STRINGS_TAB, "define"),
    spaced(STRINGS_TAB, STRINGS_TAB, APP_DEFINE_SWITCHES.join(STRINGS_COMMA & STRINGS_SPACE).replace(STRINGS_COLON, STRINGS_EMPTY)),
    spaced(STRINGS_TAB, "version"),
    spaced(STRINGS_TAB, STRINGS_TAB, APP_VERSION_SWITCHES.join(STRINGS_COMMA & STRINGS_SPACE)),
    spaced(STRINGS_TAB, "help"),
    spaced(STRINGS_TAB, STRINGS_TAB, APP_HELP_SWITCHES.join(STRINGS_COMMA & STRINGS_SPACE))
  ))
  APP_USAGE_LINE = spaced(STRINGS_MINUS, lined(
    "usages" & STRINGS_COLON,
    spaced(STRINGS_TAB, APP_NAME, bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv")), chevronize("input.file")),
    spaced(STRINGS_TAB, APP_NAME, chevronize("input.file"), bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv"))),
    spaced(STRINGS_TAB, APP_NAME, chevronize("version-flag")),
    spaced(STRINGS_TAB, APP_NAME, bracketize(chevronize("help-flag")))
  ))
  APP_EXAMPLE_LINE = spaced(STRINGS_MINUS, lined(
    "examples" & STRINGS_COLON,
    spaced(STRINGS_TAB, APP_NAME, "myfile.unim"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "transpile myfile.unim"),
    spaced(STRINGS_TAB, APP_NAME, "myfile.unim", "-d:MYDEF1,MYDEF2"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "transpile myfile.unim with conditional defines MYDEF1 and MYDEF2"),
    spaced(STRINGS_TAB, APP_NAME, "-d:BLAH,FOO,BAR", "myfile.unim"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "transpile myfile.unim with conditional defines BLAH, FOO and BAR"),
    spaced(STRINGS_TAB, APP_NAME, "-v"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "get version info"),
    spaced(STRINGS_TAB, APP_NAME, "-h"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "show this message")
  ))
  APP_VERSION_MSG = lined(APP_VERSION_TEXT, APP_COPYRIGHT_TEXT)
  APP_HELP_MSG = lined(APP_VERSION_MSG, STRINGS_EMPTY, APP_FLAGS_LINE, STRINGS_EMPTY, APP_USAGE_LINE, STRINGS_EMPTY, APP_EXAMPLE_LINE, STRINGS_EMPTY)

# EVENTS

let events = (
  initializer: RodsterAppEvent (app: RodsterApplication) => (
    # setup kvm
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    let args = nfo.getArguments();
    if args.len == 0 or nfo.hasArgument(APP_HELP_SWITCHES): quit(APP_HELP_MSG, 0);
    if nfo.hasArgument(APP_VERSION_SWITCHES): quit(APP_VERSION_MSG, 0);
    kvm[APP_VERSION_KEY] = APP_VERSION_TEXT;
    let idxs = nfo.findArgumentsWithPrefix(APP_DEFINE_SWITCHES);
    if idxs.len == 0: (
      kvm[APP_INPUT_KEY] = args[0];
      kvm[APP_DEFINES_KEY] = STRINGS_EMPTY
    ) else: (
      if args.len != 2: quit(APP_HELP_MSG, 0);
      let didx = idxs[0];
      kvm[APP_DEFINES_KEY] = nfo.getArgumentWithoutPrefix(didx, APP_DEFINE_SWITCHES);
      kvm[APP_INPUT_KEY] = args[if didx == 0: 1 else: 0]
    );
    # setup performers
    UbernimPerformers.preprocessDoer = SimplePreprocessDoer;
    UbernimPerformers.compilerInvoker = SimpleCompilerInvoker;
    UbernimPerformers.errorHandler = APP_ERROR_HANDLER
  ),
  main: RodsterAppEvent (app: RodsterApplication) => (
    # setup status
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    let ls = makeUbernimStatus();
    ls.info.semver = nfo.getVersion();
    ls.info.signature = spaced(WORDS_GENERATED, WORDS_WITH, kvm[APP_VERSION_KEY]);
    ls.files.callstack.add(kvm[APP_INPUT_KEY]);
    ls.defines = kvm[APP_DEFINES_KEY].split(STRINGS_COMMA);
    ls.language.divisions.add(makeDefaultDivisions());
    # invoke performers
    var state = UbernimPerformers.preprocessDoer(kvm[APP_INPUT_KEY], ls);
    silent () => (kvm[APP_ERRORLEVEL_KEY] = $compilationPerformer(state));
    kvm[APP_REPORT_KEY] = cleanupPerformer(state, APP_CLEANUP_FORMATTER);
    freeUbernimStatus(state)
  ),
  finalizer: RodsterAppEvent (app: RodsterApplication) => (
    # inform result
    let kvm = app.getKvm();
    let errorlevel = tryParseInt(kvm[APP_ERRORLEVEL_KEY], -1);
    let donemsg = spaced(APP_DONE_MSG, parenthesize($errorlevel));
    let output = kvm[APP_REPORT_KEY] & spaced(if errorlevel == 0: ansiGreen(donemsg) else: ansiBlue(donemsg));
    quit(lined(APP_TITLE_MSG, output), errorlevel)
  )
)

# MAIN

run newRodsterApplication(APP_NAME, APP_VERSION, events)
