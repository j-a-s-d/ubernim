# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

# IMPORTS

import
  rodster, xam,
  ubernim / [constants, engine]

use strutils,split
use strutils,join
use strutils,replace
use json,JsonNode

# CONSTANTS

const
  APP_NAME = "ubernim"
  APP_VERSION = "0.5.5"
  APP_COPYRIGHT = "copyright (c) 2021-2022 by Javier Santo Domingo"
  APP_KEYS = (
    INPUT: "app:input",
    DEFINES: "app:defines",
    ERRORLEVEL: "app:errorlevel",
    REPORT: "app:report"
  )
  APP_SWITCHES = (
    DEFINE: [STRINGS_MINUS & STRINGS_LOWERCASE_D & STRINGS_COLON, STRINGS_MINUS & STRINGS_MINUS & WORDS_DEFINE & STRINGS_COLON],
    VERSION: [STRINGS_MINUS & STRINGS_LOWERCASE_V, STRINGS_MINUS & STRINGS_MINUS & WORDS_VERSION],
    HELP: [STRINGS_MINUS & STRINGS_LOWERCASE_H, STRINGS_MINUS & STRINGS_MINUS & WORDS_HELP, STRINGS_MINUS & STRINGS_QUESTION, STRINGS_SLASH & STRINGS_QUESTION, STRINGS_QUESTION]
  )
  APP_TEXTS = (
    VERSION: spaced(APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION),
    SIGNATURE: spaced(WORDS_GENERATED, WORDS_WITH, APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION),
    FLAGS_LINES: spaced(STRINGS_MINUS, lined(
      WORDS_FLAGS & STRINGS_COLON,
      spaced(STRINGS_TAB, WORDS_DEFINE),
      spaced(STRINGS_TAB, STRINGS_TAB, APP_SWITCHES.DEFINE.join(STRINGS_COMMA & STRINGS_SPACE).replace(STRINGS_COLON, STRINGS_EMPTY)),
      spaced(STRINGS_TAB, WORDS_VERSION),
      spaced(STRINGS_TAB, STRINGS_TAB, APP_SWITCHES.VERSION.join(STRINGS_COMMA & STRINGS_SPACE)),
      spaced(STRINGS_TAB, WORDS_HELP),
      spaced(STRINGS_TAB, STRINGS_TAB, APP_SWITCHES.HELP.join(STRINGS_COMMA & STRINGS_SPACE))
    )),
    USAGES_LINES: spaced(STRINGS_MINUS, lined(
      WORDS_USAGES & STRINGS_COLON,
      spaced(STRINGS_TAB, APP_NAME, bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv")), chevronize("input.file")),
      spaced(STRINGS_TAB, APP_NAME, chevronize("input.file"), bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv"))),
      spaced(STRINGS_TAB, APP_NAME, chevronize("version-flag")),
      spaced(STRINGS_TAB, APP_NAME, bracketize(chevronize("help-flag")))
    )),
    EXAMPLES_LINES: spaced(STRINGS_MINUS, lined(
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
    )),
  )
  APP_MSGS = (
    VERSION: lined(APP_TEXTS.VERSION, APP_COPYRIGHT),
    HELP: lined(APP_TEXTS.VERSION, APP_COPYRIGHT, STRINGS_EMPTY, APP_TEXTS.FLAGS_LINES, STRINGS_EMPTY, APP_TEXTS.USAGES_LINES, STRINGS_EMPTY, APP_TEXTS.EXAMPLES_LINES, STRINGS_EMPTY),
    ERROR: spaced(STRINGS_ASTERISK, bracketize("ERROR")),
    DONE: spaced(STRINGS_ASTERISK, bracketize("DONE")),
    TITLE: ansiMagenta(spaced(STRINGS_ASTERISK, APP_TEXTS.VERSION))
  )
  APP_PERFORMERS = (
    ERROR_HANDLER: (msg: string) => quit(spaced(ansiRed(APP_MSGS.ERROR), msg), -1),
    CLEANUP_FORMATTER: proc (action, file: string): string = spaced(STRINGS_ASTERISK, parenthesize(action), file) & STRINGS_EOL
  )

# ERRORS

template makeText(code, message: string): JsonNode =
  newJObjectBuilder().set("code", code).set("message", message).getAsJObject()

proc getENErrorMessages(): JsonNode =
  wrapInJArray(
    makeText(errors.UNEXPECTED, "an unexpected error occurred"),
    makeText(errors.BAD_STATE, "bad state"),
    makeText(errors.BAD_VERSION, "a newer version is required"),
    makeText(errors.BAD_FLAG, "only yes/no values allowed"),
    makeText(errors.BAD_MODE, "only free/strict values allowed"),
    makeText(errors.BAD_FREQUENCY, "only always/once values allowed"),
    makeText(errors.BAD_CLEANUP, "only ignored/informed/performed values allowed"),
    makeText(errors.BAD_TARGET, "only cc/cpp/objc/js values allowed"),
    makeText(errors.STRICT_MODE, "only ubernim code is allowed in strict mode"),
    makeText(errors.ONLY_TOP_LEVEL, "this can only be defined in the top level"),
    makeText(errors.DONT_TOP_LEVEL, "this can not be defined in the top level"),
    makeText(errors.CANT_BE_REQUIRED, "this can not be required"),
    makeText(errors.NO_RECURSIVE_REQUIRE, "recursive require is not allowed"),
    makeText(errors.NO_CIRCULAR_REFERENCE, "circular references are not allowed"),
    makeText(errors.INVALID_IDENTIFIER, "invalid identifier"),
    makeText(errors.UNDEFINED_REFERENCE, "undefined reference"),
    makeText(errors.ALREADY_DEFINED, "already defined"),
    makeText(errors.NEVER_DEFINED, "never defined"),
    makeText(errors.WRONGLY_DEFINED, "wrongly defined"),
    makeText(errors.CANT_HOLD_FIELDS, "this can not hold fields"),
    makeText(errors.CANT_HOLD_METHODS, "this can not hold methods"),
    makeText(errors.CANT_HOLD_TEMPLATES, "this can not hold templates"),
    makeText(errors.CANT_HOLD_PRAGMAS, "this can not hold pragmas"),
    makeText(errors.CANT_HOLD_VALUE, "this can not hold value"),
    makeText(errors.CANT_OUTPUT_DOCS, "this can not output documentation"),
    makeText(errors.CANT_OUTPUT_CODE, "this can not output code"),
    makeText(errors.UNDEFINED_MEMBER_VALUE, "undefined value for immutable member"),
    makeText(errors.DEFINE_BEFORE_VALUE, "this must be defined before code or value"),
    makeText(errors.ALREADY_RENDERED, "this is already rendered"),
    makeText(errors.NOT_APPLIABLE, "only a compound, an interface or a protocol can be applied to something else"),
    makeText(errors.ALREADY_APPLYING, "this is already applying"),
    makeText(errors.ALREADY_EXTENDING, "this is already extending"),
    makeText(errors.CANT_EXTEND_INEXISTENT, "can not extend from inexistent"),
    makeText(errors.CANT_EXTEND_DIFFERENT, "can not extend from a different type"),
    makeText(errors.CANT_EXTEND_SEALED, "can not extend from sealed"),
    makeText(errors.RECORDS_CANT_EXTEND, "records can not be extended"),
    makeText(errors.RECORDS_DONT_ASTERISK,  "the * modifier is not allowed in record fields"),
    makeText(errors.VISIBILITY_DOESNT_MATCH, "visibility does not match definition"),
    makeText(errors.NOT_IN_TARGETED, "not in a targeted block"),
    makeText(errors.NOT_IN_PROJECT, "not in a project block"),
    makeText(errors.CANT_CREATE_DIRECTORY, "can not create directory"),
    makeText(errors.CANT_APPEND_FILE, "can not append file"),
    makeText(errors.CANT_WRITE_FILE, "can not write file"),
    makeText(errors.CANT_REMOVE_FILE, "can not remove file"),
    makeText(errors.CANT_WRITE_CONFIG, "can not write configuration file"),
    makeText(errors.CANT_WRITE_OUTPUT, "can not write output file"),
    makeText(errors.FAILURE_PROCESSING, "a failure ocurred when processing"),
    makeText(errors.MINIMUM_NIM_VERSION, "the installed nim version does not met the specified minimum")
  )

# EVENTS

let events = (
  initializer: RodsterAppEvent (app: RodsterApplication) => (
    # load parameters
    let kvm = app.getKvm();
    let loc = app.getI18n();
    discard loc.loadTextsFromJArray("EN", getENErrorMessages());
    let nfo = app.getInformation();
    let args = nfo.getArguments();
    if args.len notin [1, 2] or nfo.hasArgument(APP_SWITCHES.HELP): quit(APP_MSGS.HELP, 0);
    if nfo.hasArgument(APP_SWITCHES.VERSION): quit(APP_MSGS.VERSION, 0);
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
    let nfo = app.getInformation();
    let loc = app.getI18n();
    let engine = newUbernimEngine(nfo.getFilename(), nfo.getVersion(), APP_TEXTS.SIGNATURE);
    engine.setErrorGetter(proc (msg: string, values: StringSeq): string = loc.getText(msg, values));
    engine.setErrorHandler(APP_PERFORMERS.ERROR_HANDLER);
    engine.setCleanupFormatter(APP_PERFORMERS.CLEANUP_FORMATTER);
    withIt engine.run(kvm[APP_KEYS.INPUT], kvm[APP_KEYS.DEFINES].split(STRINGS_COMMA)): (
      kvm[APP_KEYS.ERRORLEVEL] = $it.compilationErrorlevel;
      kvm[APP_KEYS.REPORT] = it.cleanupReport
    )
  ),
  finalizer: RodsterAppEvent (app: RodsterApplication) => (
    # inform result
    let kvm = app.getKvm();
    let errorlevel = tryParseInt(kvm[APP_KEYS.ERRORLEVEL], -1);
    let donemsg = spaced(APP_MSGS.DONE, parenthesize($errorlevel));
    let highlighter = if errorlevel == 0: ansiGreen else: ansiBlue;
    let output = kvm[APP_KEYS.REPORT] & highlighter(donemsg);
    quit(lined(APP_MSGS.TITLE, output), errorlevel)
  )
)

# MAIN

run newRodsterApplication(APP_NAME, APP_VERSION, events)
