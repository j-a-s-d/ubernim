# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

# IMPORTS

import
  rodster, xam,
  ubernim / [errors, engine]

use strutils,split
use strutils,join
use strutils,replace

# CONSTANTS

const
  APP_NAME = "ubernim"
  APP_VERSION = "0.5.0"
  APP_VERSION_TEXT = spaced(APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION)
  APP_SIGNATURE_TEXT = spaced(WORDS_GENERATED, WORDS_WITH, APP_VERSION_TEXT)
  APP_COPYRIGHT_TEXT = "copyright (c) 2021-2022 by Javier Santo Domingo"
  APP_KEYS = (
    INPUT: "app:input",
    DEFINES: "app:defines",
    ERRORLEVEL: "app:errorlevel",
    REPORT: "app:report"
  )
  APP_ERROR_MSG = spaced(STRINGS_ASTERISK, bracketize("ERROR"))
  APP_DONE_MSG = spaced(STRINGS_ASTERISK, bracketize("DONE"))
  APP_TITLE_MSG = ansiMagenta(spaced(STRINGS_ASTERISK, APP_VERSION_TEXT))
  APP_PERFORMERS = (
    ERROR_HANDLER: (msg: string) => quit(spaced(ansiRed(APP_ERROR_MSG), msg), 0),
    CLEANUP_FORMATTER: proc (action, file: string): string = spaced(STRINGS_ASTERISK, parenthesize(action), file) & STRINGS_EOL
  )
  APP_SWITCHES = (
    DEFINE: [STRINGS_MINUS & STRINGS_LOWERCASE_D & STRINGS_COLON, STRINGS_MINUS & STRINGS_MINUS & WORDS_DEFINE & STRINGS_COLON],
    VERSION: [STRINGS_MINUS & STRINGS_LOWERCASE_V, STRINGS_MINUS & STRINGS_MINUS & WORDS_VERSION],
    HELP: [STRINGS_MINUS & STRINGS_LOWERCASE_H, STRINGS_MINUS & STRINGS_MINUS & WORDS_HELP, STRINGS_MINUS & STRINGS_QUESTION, STRINGS_SLASH & STRINGS_QUESTION, STRINGS_QUESTION]
  )
  APP_FLAGS_LINE = spaced(STRINGS_MINUS, lined(
    WORDS_FLAGS & STRINGS_COLON,
    spaced(STRINGS_TAB, WORDS_DEFINE),
    spaced(STRINGS_TAB, STRINGS_TAB, APP_SWITCHES.DEFINE.join(STRINGS_COMMA & STRINGS_SPACE).replace(STRINGS_COLON, STRINGS_EMPTY)),
    spaced(STRINGS_TAB, WORDS_VERSION),
    spaced(STRINGS_TAB, STRINGS_TAB, APP_SWITCHES.VERSION.join(STRINGS_COMMA & STRINGS_SPACE)),
    spaced(STRINGS_TAB, WORDS_HELP),
    spaced(STRINGS_TAB, STRINGS_TAB, APP_SWITCHES.HELP.join(STRINGS_COMMA & STRINGS_SPACE))
  ))
  APP_USAGE_LINE = spaced(STRINGS_MINUS, lined(
    WORDS_USAGES & STRINGS_COLON,
    spaced(STRINGS_TAB, APP_NAME, bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv")), chevronize("input.file")),
    spaced(STRINGS_TAB, APP_NAME, chevronize("input.file"), bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv"))),
    spaced(STRINGS_TAB, APP_NAME, chevronize("version-flag")),
    spaced(STRINGS_TAB, APP_NAME, bracketize(chevronize("help-flag")))
  ))
  APP_EXAMPLE_LINE = spaced(STRINGS_MINUS, lined(
    WORDS_EXAMPLES & STRINGS_COLON,
    spaced(STRINGS_TAB, APP_NAME, "myfile.unim"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim"),
    spaced(STRINGS_TAB, APP_NAME, "myfile.unim", "-d:MYDEF1,MYDEF2"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim with conditional defines MYDEF1 and MYDEF2"),
    spaced(STRINGS_TAB, APP_NAME, "-d:BLAH,FOO,BAR", "myfile.unim"),
    spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim with conditional defines BLAH, FOO and BAR"),
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
    # load parameters
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    let args = nfo.getArguments();
    if args.len == 0 or args.len > 2 or nfo.hasArgument(APP_SWITCHES.HELP): quit(APP_HELP_MSG, 0);
    if nfo.hasArgument(APP_SWITCHES.VERSION): quit(APP_VERSION_MSG, 0);
    let idxs = nfo.findArgumentsWithPrefix(APP_SWITCHES.DEFINE);
    if idxs.len == 0: (
      kvm[APP_KEYS.INPUT] = args[0];
      kvm[APP_KEYS.DEFINES] = STRINGS_EMPTY
    ) else: (
      kvm[APP_KEYS.INPUT] = args[if idxs[0] == 0: 1 else: 0];
      kvm[APP_KEYS.DEFINES] = nfo.getArgumentWithoutPrefix(idxs[0], APP_SWITCHES.DEFINE)
    )
  ),
  main: RodsterAppEvent (app: RodsterApplication) => (
    # use engine
    let kvm = app.getKvm();
    let engine = newUbernimEngine(app.getInformation().getVersion(), APP_SIGNATURE_TEXT);
    engine.setupPerformers(APP_PERFORMERS.ERROR_HANDLER, APP_PERFORMERS.CLEANUP_FORMATTER);
    withIt engine.run(kvm[APP_KEYS.INPUT], kvm[APP_KEYS.DEFINES].split(STRINGS_COMMA)): (
      kvm[APP_KEYS.ERRORLEVEL] = $it.compilationErrorlevel;
      kvm[APP_KEYS.REPORT] = it.cleanupReport
    )
  ),
  finalizer: RodsterAppEvent (app: RodsterApplication) => (
    # inform result
    let kvm = app.getKvm();
    let errorlevel = tryParseInt(kvm[APP_KEYS.ERRORLEVEL], -1);
    let donemsg = spaced(APP_DONE_MSG, parenthesize($errorlevel));
    let highlighter = if errorlevel == 0: ansiGreen else: ansiBlue;
    let output = kvm[APP_KEYS.REPORT] & highlighter(donemsg);
    quit(lined(APP_TITLE_MSG, output), errorlevel)
  )
)

# MAIN

run newRodsterApplication(APP_NAME, APP_VERSION, events)
