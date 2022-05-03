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
use os,fileExists

# CONSTANTS

const
  APP_NAME = "ubernim"
  APP_VERSION = "0.7.3"
  APP_COPYRIGHT = "copyright (c) 2021-2022 by Javier Santo Domingo"
  LANGUAGE_CODES = (
    EN: "EN",
    ES: "ES",
    PT: "PT"
  )
  APP_LANGUAGES = [LANGUAGE_CODES.EN, LANGUAGE_CODES.ES, LANGUAGE_CODES.PT]
  APP_SWITCHES = (
    DEFINE: [STRINGS_MINUS & STRINGS_LOWERCASE_D & STRINGS_COLON, STRINGS_MINUS & STRINGS_MINUS & COMMANDS_DEFINE & STRINGS_COLON],
    LANGUAGE: [STRINGS_MINUS & STRINGS_LOWERCASE_L & STRINGS_COLON, STRINGS_MINUS & STRINGS_MINUS & COMMANDS_LANGUAGE & STRINGS_COLON],
    VERSION: [STRINGS_MINUS & STRINGS_LOWERCASE_V, STRINGS_MINUS & STRINGS_MINUS & COMMANDS_VERSION],
    HELP: [STRINGS_MINUS & STRINGS_LOWERCASE_H, STRINGS_MINUS & STRINGS_MINUS & COMMANDS_HELP, STRINGS_MINUS & STRINGS_QUESTION, STRINGS_SLASH & STRINGS_QUESTION, STRINGS_QUESTION]
  )
  APP_TEXTS = (
    VERSION: spaced(APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION),
    SIGNATURE: spaced("generated", "with", APP_NAME, STRINGS_LOWERCASE_V & APP_VERSION),
    FLAGS_LINES: spaced(STRINGS_MINUS, lined(
      "commands" & STRINGS_COLON,
      spaced(STRINGS_TAB, COMMANDS_DEFINE),
      spaced(STRINGS_TAB, STRINGS_TAB, "flags" & STRINGS_COLON, APP_SWITCHES.DEFINE.join(STRINGS_COMMA & STRINGS_SPACE).replace(STRINGS_COLON, STRINGS_EMPTY)),
      spaced(STRINGS_TAB, STRINGS_TAB, "usage" & STRINGS_COLON, APP_NAME, bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv"))),
      spaced(STRINGS_TAB, COMMANDS_LANGUAGE),
      spaced(STRINGS_TAB, STRINGS_TAB, "flags" & STRINGS_COLON, APP_SWITCHES.LANGUAGE.join(STRINGS_COMMA & STRINGS_SPACE)),
      spaced(STRINGS_TAB, STRINGS_TAB, "usage" & STRINGS_COLON, APP_NAME, bracketize(chevronize("language-flag") & STRINGS_COLON & chevronize("language"))),
      spaced(STRINGS_TAB, STRINGS_TAB, "supported" & STRINGS_COLON, APP_LANGUAGES.join(STRINGS_COMMA & STRINGS_SPACE)),
      spaced(STRINGS_TAB, COMMANDS_VERSION),
      spaced(STRINGS_TAB, STRINGS_TAB, "flags" & STRINGS_COLON, APP_SWITCHES.VERSION.join(STRINGS_COMMA & STRINGS_SPACE)),
      spaced(STRINGS_TAB, STRINGS_TAB, "usage" & STRINGS_COLON, APP_NAME, chevronize("version-flag")),
      spaced(STRINGS_TAB, COMMANDS_HELP),
      spaced(STRINGS_TAB, STRINGS_TAB, "flags" & STRINGS_COLON, APP_SWITCHES.HELP.join(STRINGS_COMMA & STRINGS_SPACE)),
      spaced(STRINGS_TAB, STRINGS_TAB, "usage" & STRINGS_COLON, APP_NAME, bracketize(chevronize("help-flag")))
    )),
    EXAMPLES_LINES: spaced(STRINGS_MINUS, lined(
      "examples" & STRINGS_COLON,
      spaced(STRINGS_TAB, APP_NAME, "myfile.unim"),
      spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim"),
      spaced(STRINGS_TAB, APP_NAME, "-d:BLAH,FOO,BAR", "myfile.unim"),
      spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim with conditional defines BLAH, FOO and BAR"),
      spaced(STRINGS_TAB, APP_NAME, "-l:ES", "myfile.unim"),
      spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim using Spanish as the language to display errors"),
      spaced(STRINGS_TAB, APP_NAME, "-l:ES", "-d:DEF1,DEF2", "myfile.unim"),
      spaced(STRINGS_TAB, STRINGS_MINUS, "preprocess myfile.unim with conditional defines DEF1 and DEF2 using Spanish as the language to display errors"),
      spaced(STRINGS_TAB, APP_NAME, "-v"),
      spaced(STRINGS_TAB, STRINGS_MINUS, "get version info"),
      spaced(STRINGS_TAB, APP_NAME, "-h"),
      spaced(STRINGS_TAB, STRINGS_MINUS, "show this message")
    )),
  )
  APP_MSGS = (
    VERSION: lined(APP_TEXTS.VERSION, APP_COPYRIGHT),
    HELP: lined(APP_TEXTS.VERSION, APP_COPYRIGHT, STRINGS_EMPTY, APP_TEXTS.FLAGS_LINES, STRINGS_EMPTY, APP_TEXTS.EXAMPLES_LINES, STRINGS_EMPTY),
    ERROR: spaced(STRINGS_ASTERISK, bracketize("ERROR")),
    DONE: spaced(STRINGS_ASTERISK, bracketize("DONE")),
    TITLE: ansiMagenta(spaced(STRINGS_ASTERISK, APP_TEXTS.VERSION))
  )
  APP_KEYS = (
    INPUT: "app:input",
    DEFINES: "app:defines",
    ERRORLEVEL: "app:errorlevel",
    REPORT: "app:report"
  )

# ERRORS

template addMessage(builder: JArrayBuilder, code, message: string): JArrayBuilder =
  builder.add(newJObjectBuilder().set("code", code).set("message", message).getAsJObject())

template getENErrorMessages(): JArrayBuilder =
  newJArrayBuilder()
    .addMessage(errors.UNEXPECTED, "an unexpected error occurred $1")
    .addMessage(errors.BAD_STATE, "incorrect internal state")
    .addMessage(errors.OLD_VERSION, "a newer version is required: $1")
    .addMessage(errors.BAD_VERSION, "only semantic version values are allowed")
    .addMessage(errors.BAD_FLAG, "only yes/no values are allowed")
    .addMessage(errors.BAD_MODE, "only free/strict values are allowed")
    .addMessage(errors.BAD_FREQUENCY, "only always/once values are allowed")
    .addMessage(errors.BAD_CLEANUP, "only ignored/informed/performed values are allowed")
    .addMessage(errors.BAD_TARGET, "only cc/cpp/objc/js values are allowed")
    .addMessage(errors.STRICT_MODE, "only ubernim code is allowed in strict mode")
    .addMessage(errors.ONLY_TOP_LEVEL, "this can only be defined in the top level")
    .addMessage(errors.DONT_TOP_LEVEL, "this can not be defined in the top level")
    .addMessage(errors.INEXISTENT_FILE_REQUIRED, "inexistent file '$1' can not be required")
    .addMessage(errors.CANT_BE_REQUIRED, "this file can not be required")
    .addMessage(errors.NO_RECURSIVE_REQUIRE, "recursive require is not allowed")
    .addMessage(errors.NO_CIRCULAR_REFERENCE, "circular references are not allowed")
    .addMessage(errors.INVALID_IDENTIFIER, "invalid identifier")
    .addMessage(errors.UNDEFINED_REFERENCE, "undefined reference $1")
    .addMessage(errors.ALREADY_DEFINED, "already defined $1")
    .addMessage(errors.NEVER_DEFINED, "never defined $1")
    .addMessage(errors.WRONGLY_DEFINED, "wrongly defined $1")
    .addMessage(errors.CANT_HOLD_FIELDS, "this element can not hold fields")
    .addMessage(errors.CANT_HOLD_METHODS, "this element can not hold methods")
    .addMessage(errors.CANT_HOLD_TEMPLATES, "this element can not hold templates")
    .addMessage(errors.CANT_HOLD_PRAGMAS, "this element can not hold pragmas")
    .addMessage(errors.CANT_HOLD_VALUE, "this element can not hold value")
    .addMessage(errors.CANT_OUTPUT_DOCS, "this element can not output documentation")
    .addMessage(errors.CANT_OUTPUT_CODE, "this element can not output code")
    .addMessage(errors.MISSING_MEMBER, "missing $1 from $2 at $3")
    .addMessage(errors.UNDEFINED_MEMBER_VALUE, "undefined value for immutable member")
    .addMessage(errors.DEFINE_BEFORE_VALUE, "this must be defined before code or value")
    .addMessage(errors.NOT_APPLIABLE, "only a compound, an interface or a protocol can be applied to something else")
    .addMessage(errors.ALREADY_APPLYING, "this is already applying $1")
    .addMessage(errors.ALREADY_RENDERED, "this is already rendered")
    .addMessage(errors.ALREADY_EXTENDING, "this is already extending $1")
    .addMessage(errors.CANT_EXTEND_INEXISTENT, "can not extend from inexistent $1")
    .addMessage(errors.CANT_EXTEND_DIFFERENT, "can not extend from a different kind of type")
    .addMessage(errors.CANT_EXTEND_SEALED, "can not extend from sealed $1")
    .addMessage(errors.RECORDS_CANT_EXTEND, "records can not be extended")
    .addMessage(errors.RECORDS_DONT_ASTERISK,  "the * modifier is not allowed in record fields")
    .addMessage(errors.VISIBILITY_DOESNT_MATCH, "visibility does not match definition for $1")
    .addMessage(errors.NOT_IN_TARGETED, "not in a targeted block")
    .addMessage(errors.NOT_IN_PROJECT, "not in a project block")
    .addMessage(errors.CANT_CREATE_DIRECTORY, "can not create directory $1")
    .addMessage(errors.CANT_APPEND_FILE, "can not append file $1")
    .addMessage(errors.CANT_WRITE_FILE, "can not write file $1")
    .addMessage(errors.CANT_REMOVE_FILE, "can not remove file $1")
    .addMessage(errors.CANT_WRITE_CONFIG, "can not write configuration file")
    .addMessage(errors.CANT_WRITE_OUTPUT, "can not write output file")
    .addMessage(errors.FAILURE_PROCESSING, "a failure ocurred when processing $1")
    .addMessage(errors.MINIMUM_NIM_VERSION, "the installed nim version does not met the specified minimum")

template getESErrorMessages(): JArrayBuilder =
  newJArrayBuilder()
    .addMessage(errors.UNEXPECTED, "un error inesperado ha ocurrido $1")
    .addMessage(errors.BAD_STATE, "estado interno incorrecto")
    .addMessage(errors.OLD_VERSION, "una versión más nueva es requerida: $1")
    .addMessage(errors.BAD_VERSION, "sólo valores de semantic version son permitidos")
    .addMessage(errors.BAD_FLAG, "sólo los valores yes/no son permitidos")
    .addMessage(errors.BAD_MODE, "sólo los valores free/strict son permitidos")
    .addMessage(errors.BAD_FREQUENCY, "sólo los valores always/once son permitidos")
    .addMessage(errors.BAD_CLEANUP, "sólo los valores ignored/informed/performed son permitidos")
    .addMessage(errors.BAD_TARGET, "sólo los valores cc/cpp/objc/js son permitidos")
    .addMessage(errors.STRICT_MODE, "sólo código ubernim es permitido en modo strict")
    .addMessage(errors.ONLY_TOP_LEVEL, "esto sólo puede ser definido en el nivel tope")
    .addMessage(errors.DONT_TOP_LEVEL, "esto no puede ser definido en el nivel tope")
    .addMessage(errors.INEXISTENT_FILE_REQUIRED, "archivo inexistente '$1' no puede ser requerido")
    .addMessage(errors.CANT_BE_REQUIRED, "este archivo no puede ser requerido")
    .addMessage(errors.NO_RECURSIVE_REQUIRE, "requerimientos recursivos no permitidos")
    .addMessage(errors.NO_CIRCULAR_REFERENCE, "referencias circulares no permitidas")
    .addMessage(errors.INVALID_IDENTIFIER, "identificador inválido")
    .addMessage(errors.UNDEFINED_REFERENCE, "referencia indefinida $1")
    .addMessage(errors.ALREADY_DEFINED, "ya definido $1")
    .addMessage(errors.NEVER_DEFINED, "nunca definido $1")
    .addMessage(errors.WRONGLY_DEFINED, "mal definido $1")
    .addMessage(errors.CANT_HOLD_FIELDS, "este elemento no puede contener fields")
    .addMessage(errors.CANT_HOLD_METHODS, "este elemento no puede contener methods")
    .addMessage(errors.CANT_HOLD_TEMPLATES, "este elemento no puede contener templates")
    .addMessage(errors.CANT_HOLD_PRAGMAS, "este elemento no puede contener pragmas")
    .addMessage(errors.CANT_HOLD_VALUE, "este elemento no puede contener value")
    .addMessage(errors.CANT_OUTPUT_DOCS, "este elemento no puede emitir documentación")
    .addMessage(errors.CANT_OUTPUT_CODE, "este elemento no puede emitir código")
    .addMessage(errors.MISSING_MEMBER, "falta $1 de $2 en $3")
    .addMessage(errors.UNDEFINED_MEMBER_VALUE, "valor indefinido para miembro inmutable")
    .addMessage(errors.DEFINE_BEFORE_VALUE, "esto debe ser definido antes del code o value")
    .addMessage(errors.NOT_APPLIABLE, "sólo un compound, una interface o un protocol puede ser aplicado a algo más")
    .addMessage(errors.ALREADY_APPLYING, "esto ya está aplicando $1")
    .addMessage(errors.ALREADY_RENDERED, "esto ya está renderizado")
    .addMessage(errors.ALREADY_EXTENDING, "esto ya está extendiendo $1")
    .addMessage(errors.CANT_EXTEND_INEXISTENT, "no se puede extender del inexistente $1")
    .addMessage(errors.CANT_EXTEND_DIFFERENT, "no se puede extender de una especie de tipo diferente")
    .addMessage(errors.CANT_EXTEND_SEALED, "no se puede extender del sellado $1")
    .addMessage(errors.RECORDS_CANT_EXTEND, "los records no se pueden extender")
    .addMessage(errors.RECORDS_DONT_ASTERISK,  "el modificador * no está permitido en fields de records")
    .addMessage(errors.VISIBILITY_DOESNT_MATCH, "la visibilidad no coincide con la definición para $1")
    .addMessage(errors.NOT_IN_TARGETED, "no se está en un bloque targeted")
    .addMessage(errors.NOT_IN_PROJECT, "no se está en un bloque project")
    .addMessage(errors.CANT_CREATE_DIRECTORY, "no se puede crear el directorio $1")
    .addMessage(errors.CANT_APPEND_FILE, "no se puede agregar al archivo $1")
    .addMessage(errors.CANT_WRITE_FILE, "no se puede escribir el archivo $1")
    .addMessage(errors.CANT_REMOVE_FILE, "no se puede remover el archivo $1")
    .addMessage(errors.CANT_WRITE_CONFIG, "no se puede escribir el archivo de configuración")
    .addMessage(errors.CANT_WRITE_OUTPUT, "no se puede escribir el archivo de salida")
    .addMessage(errors.FAILURE_PROCESSING, "una falla ha ocurrido cuando se procesaba $1")
    .addMessage(errors.MINIMUM_NIM_VERSION, "la versión instalada de nim no alcanza el mínimo especificado")

template getPTErrorMessages(): JArrayBuilder =
  newJArrayBuilder()
    .addMessage(errors.UNEXPECTED, "um erro inesperado ocorreu $1")
    .addMessage(errors.BAD_STATE, "estado interno incorreto")
    .addMessage(errors.OLD_VERSION, "uma versão mais nova é requerida: $1")
    .addMessage(errors.BAD_VERSION, "só valores de semantic version são permitidos")
    .addMessage(errors.BAD_FLAG, "só os valores yes/no são permitidos")
    .addMessage(errors.BAD_MODE, "só os valores free/strict são permitidos")
    .addMessage(errors.BAD_FREQUENCY, "só os valores always/once são permitidos")
    .addMessage(errors.BAD_CLEANUP, "só os valores ignored/informed/performed são permitidos")
    .addMessage(errors.BAD_TARGET, "só os valores cc/cpp/objc/js são permitidos")
    .addMessage(errors.STRICT_MODE, "só código ubernim é permitido em modo strict")
    .addMessage(errors.ONLY_TOP_LEVEL, "isso só pode ser definido no nível superior")
    .addMessage(errors.DONT_TOP_LEVEL, "isso não pode ser definido no nível superior")
    .addMessage(errors.INEXISTENT_FILE_REQUIRED, "arquivo inexistente '$1' não pode ser requerido")
    .addMessage(errors.CANT_BE_REQUIRED, "este arquivo não pode ser requerido")
    .addMessage(errors.NO_RECURSIVE_REQUIRE, "requerimentos recursivos não permitidos")
    .addMessage(errors.NO_CIRCULAR_REFERENCE, "referências circulares não permitidas")
    .addMessage(errors.INVALID_IDENTIFIER, "identificador inválido")
    .addMessage(errors.UNDEFINED_REFERENCE, "referência indefinida $1")
    .addMessage(errors.ALREADY_DEFINED, "já definido $1")
    .addMessage(errors.NEVER_DEFINED, "nunca definido $1")
    .addMessage(errors.WRONGLY_DEFINED, "mal definido $1")
    .addMessage(errors.CANT_HOLD_FIELDS, "este elemento não pode conter fields")
    .addMessage(errors.CANT_HOLD_METHODS, "este elemento não pode conter methods")
    .addMessage(errors.CANT_HOLD_TEMPLATES, "este elemento não pode conter templates")
    .addMessage(errors.CANT_HOLD_PRAGMAS, "este elemento não pode conter pragmas")
    .addMessage(errors.CANT_HOLD_VALUE, "este elemento não pode conter value")
    .addMessage(errors.CANT_OUTPUT_DOCS, "este elemento não pode emitir documentação")
    .addMessage(errors.CANT_OUTPUT_CODE, "este elemento não pode emitir código")
    .addMessage(errors.MISSING_MEMBER, "falta $1 de $2 em $3")
    .addMessage(errors.UNDEFINED_MEMBER_VALUE, "valor indefinido para membro imutável")
    .addMessage(errors.DEFINE_BEFORE_VALUE, "isso deve ser definido antes do code ou value")
    .addMessage(errors.NOT_APPLIABLE, "só um compound, uma interface ou um protocol pode ser aplicado a algo mais")
    .addMessage(errors.ALREADY_APPLYING, "isso já está aplicando $1")
    .addMessage(errors.ALREADY_RENDERED, "isso já está renderizado")
    .addMessage(errors.ALREADY_EXTENDING, "isso já está estendendo $1")
    .addMessage(errors.CANT_EXTEND_INEXISTENT, "não se pode estender do inexistente $1")
    .addMessage(errors.CANT_EXTEND_DIFFERENT, "não se pode estender de uma espécie de tipo diferente")
    .addMessage(errors.CANT_EXTEND_SEALED, "não se pode estender do selado $1")
    .addMessage(errors.RECORDS_CANT_EXTEND, "os records não se podem estender")
    .addMessage(errors.RECORDS_DONT_ASTERISK,  "o modificador * não está permitido em fields de records")
    .addMessage(errors.VISIBILITY_DOESNT_MATCH, "a visibilidade não coincide com a definição para $1")
    .addMessage(errors.NOT_IN_TARGETED, "não se está num bloco targeted")
    .addMessage(errors.NOT_IN_PROJECT, "não se está num bloco project")
    .addMessage(errors.CANT_CREATE_DIRECTORY, "não se pode criar o diretório $1")
    .addMessage(errors.CANT_APPEND_FILE, "não se pode adicionar ao arquivo $1")
    .addMessage(errors.CANT_WRITE_FILE, "não se pode escrever o arquivo $1")
    .addMessage(errors.CANT_REMOVE_FILE, "não se pode remover o arquivo $1")
    .addMessage(errors.CANT_WRITE_CONFIG, "não se pode escrever o arquivo de configuração")
    .addMessage(errors.CANT_WRITE_OUTPUT, "não se pode escrever o arquivo de saída")
    .addMessage(errors.FAILURE_PROCESSING, "uma falha ocorreu quando foi processado $1")
    .addMessage(errors.MINIMUM_NIM_VERSION, "à versão instalada de nim não atinge o mínimo especificado")

# EVENTS

template getUbernimSwitchValue(nfo: RodsterAppInformation, switch: openarray[string], default: string): string =
  let idxs = nfo.findArgumentsWithPrefix(switch)
  if idxs.len > 1: quit(APP_MSGS.HELP, 0)
  elif idxs.len == 0: default
  else: nfo.getArgumentWithoutPrefix(idxs[0], switch)

let events = (
  initializer: RodsterAppEvent (app: RodsterApplication) => (
    # load messages
    let loc = app.getI18n();
    let loadLanguageErrorMessages = proc (language: string, builder: JArrayBuilder) = (discard loc.loadTextsFromJArray(language, builder.getAsJArray()));
    loadLanguageErrorMessages(LANGUAGE_CODES.EN, getENErrorMessages());
    loadLanguageErrorMessages(LANGUAGE_CODES.ES, getESErrorMessages());
    loadLanguageErrorMessages(LANGUAGE_CODES.PT, getPTErrorMessages());
    # load parameters
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    let args = nfo.getArguments();
    if args.len == 0 or nfo.hasArgument(APP_SWITCHES.HELP): quit(APP_MSGS.HELP, 0);
    if nfo.hasArgument(APP_SWITCHES.VERSION): quit(APP_MSGS.VERSION, 0);
    let lang = nfo.getUbernimSwitchValue(APP_SWITCHES.LANGUAGE, LANGUAGE_CODES.EN);
    if lang notin APP_LANGUAGES: quit(APP_MSGS.HELP, 0);
    loc.setCurrentLocale(lang);
    kvm[APP_KEYS.DEFINES] = nfo.getUbernimSwitchValue(APP_SWITCHES.DEFINE, STRINGS_EMPTY);
    let input = args[^1];
    if not fileExists(input): quit(APP_MSGS.HELP, 0);
    kvm[APP_KEYS.INPUT] = input;
  ),
  main: RodsterAppEvent (app: RodsterApplication) => (
    # use engine
    let kvm = app.getKvm();
    let nfo = app.getInformation();
    let loc = app.getI18n();
    let engine = newUbernimEngine(nfo.getFilename(), nfo.getVersion(), APP_TEXTS.SIGNATURE);
    engine.setErrorGetter(proc (msg: string, values: varargs[string]): string = loc.getText(msg, newStringSeq(values)));
    engine.setErrorHandler((msg: string) => quit(spaced(ansiRed(APP_MSGS.ERROR), msg), -1));
    engine.setCleanupFormatter(proc (action, file: string): string = spaced(STRINGS_ASTERISK, parenthesize(action), file) & STRINGS_EOL);
    withIt engine.run(kvm[APP_KEYS.INPUT], kvm[APP_KEYS.DEFINES].split(STRINGS_COMMA)): (
      kvm[APP_KEYS.ERRORLEVEL] = $(if it.isProject: 0 else: it.compilationErrorlevel);
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
