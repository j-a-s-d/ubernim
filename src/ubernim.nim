# ubernim by Javier Santo Domingo
#-------------------------------------------------------------#
# "Striving to better, oft we mar what's well." - Shakespeare

when defined(js):
  {.error: "This application needs to be compiled with a c/cpp-like backend".}

# IMPORTS

import
  rodster, xam, preprod,
  ubernim / [constants, engine]

use strutils,toLowerAscii
use strutils,split
use strutils,join
use strutils,replace
use os,execShellCmd

# CONSTANTS

const
  APP = (
    NAME: "ubernim",
    VERSION: "0.7.5",
    COPYRIGHT: "copyright (c) 2021-2022 by Javier Santo Domingo",
    LANGUAGES: [LANGUAGE_CODES.EN, LANGUAGE_CODES.ES, LANGUAGE_CODES.PT]
  )
  TITLE = spaced(APP.NAME, STRINGS_LOWERCASE_V & APP.VERSION)
  KEYS = (
    INPUT: "app:input",
    DEFINES: "app:defines",
    ERRORLEVEL: "app:errorlevel",
    REPORT: "app:report"
  )
  COMMANDS = (
    HELP: "help",
    DEFINE: "define",
    LANGUAGE: "language",
    VERSION: "version"
  )
  SWITCHES = (
    DEFINE: [STRINGS_MINUS & STRINGS_LOWERCASE_D & STRINGS_COLON, STRINGS_MINUS & STRINGS_MINUS & COMMANDS.DEFINE & STRINGS_COLON],
    LANGUAGE: [STRINGS_MINUS & STRINGS_LOWERCASE_L & STRINGS_COLON, STRINGS_MINUS & STRINGS_MINUS & COMMANDS.LANGUAGE & STRINGS_COLON],
    VERSION: [STRINGS_MINUS & STRINGS_LOWERCASE_V, STRINGS_MINUS & STRINGS_MINUS & COMMANDS.VERSION],
    HELP: [STRINGS_MINUS & STRINGS_LOWERCASE_H, STRINGS_MINUS & STRINGS_MINUS & COMMANDS.HELP, STRINGS_MINUS & STRINGS_QUESTION, STRINGS_SLASH & STRINGS_QUESTION, STRINGS_QUESTION]
  )

# MESSAGES

let captions = (
  COMMANDS: "captions.COMMANDS",
  HELP: "captions.HELP",
  DEFINE: "captions.DEFINE",
  LANGUAGE: "captions.LANGUAGE",
  VERSION: "captions.VERSION",
  FLAGS: "captions.FLAGS",
  USAGE: "captions.USAGE",
  SUPPORTED: "captions.SUPPORTED",
  EXAMPLES: "captions.EXAMPLES"
)

let texts = (
  GENERATED_WITH: "texts.GENERATED_WITH",
  PREPROCESS_FILE: "texts.PREPROCESS_FILE",
  PREPROCESS_DEFINES: "texts.PREPROCESS_DEFINES",
  PREPROCESS_LANGUAGE: "texts.PREPROCESS_LANGUAGE",
  PREPROCESS_DEFINES_AND_LANGUAGE: "texts.PREPROCESS_DEFINES_AND_LANGUAGE",
  VERSION_INFO: "texts.VERSION_INFO",
  SHOW_MESSAGE: "texts.SHOW_MESSAGE"
)

let preprods = (
  UNCLOSED_BRANCH: "preprods.UNCLOSED_BRANCH",
  INEXISTENT_FILE: "preprods.INEXISTENT_FILE",
  INEXISTENT_INCLUDE: "preprods.INEXISTENT_INCLUDE",
  UNEXPECTED_COMMAND: "preprods.UNEXPECTED_COMMAND",
  NO_PREFIX: "preprods.NO_PREFIX",
  PREFIX_LENGTH: "preprods.PREFIX_LENGTH",
  UNDEFERRABLE_COMMAND: "preprods.UNDEFERRABLE_COMMAND",
  MANDATORY_STANDARD: "preprods.MANDATORY_STANDARD",
  BOOLEAN_ONLY: "preprods.BOOLEAN_ONLY",
  UNKNOWN_FEATURE: "preprods.UNKNOWN_FEATURE",
  ARGUMENTS_COUNT: "preprods.ARGUMENTS_COUNT",
  NO_ARGUMENTS: "preprods.NO_ARGUMENTS",
  DISABLED_COMMAND: "preprods.DISABLED_COMMAND",
  UNKNOWN_COMMAND: "preprods.UNKNOWN_COMMAND"
)

template addMessage(builder: JArrayBuilder, code, message: string): JArrayBuilder =
  builder.add(newJObjectBuilder().set("code", code).set("message", message).getAsJObject())

template getENMessages(): JArrayBuilder =
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
    .addMessage(messages.GENERATED_FILE, "GENERATED FILE")
    .addMessage(messages.GENERATED_DIRECTORY, "GENERATED DIRECTORY")
    .addMessage(messages.REMOVED_FILE, "REMOVED FILE")
    .addMessage(messages.UNREMOVABLE_FILE, "UNREMOVABLE FILE")
    .addMessage(messages.REMOVED_DIRECTORY, "REMOVED DIRECTORY")
    .addMessage(messages.UNREMOVABLE_DIRECTORY, "UNREMOVABLE DIRECTORY")
    .addMessage(captions.COMMANDS, "commands")
    .addMessage(captions.HELP, "help")
    .addMessage(captions.DEFINE, "define")
    .addMessage(captions.LANGUAGE, "language")
    .addMessage(captions.VERSION, "version")
    .addMessage(captions.FLAGS, "flags")
    .addMessage(captions.USAGE, "usage")
    .addMessage(captions.SUPPORTED, "supported")
    .addMessage(captions.EXAMPLES, "examples")
    .addMessage(texts.GENERATED_WITH, "generated with $1")
    .addMessage(texts.PREPROCESS_FILE, "preprocess $1")
    .addMessage(texts.PREPROCESS_DEFINES, "preprocess $1 with conditional defines $2, $3 and $4")
    .addMessage(texts.PREPROCESS_LANGUAGE, "preprocess $1 using $2 as the language to display errors")
    .addMessage(texts.PREPROCESS_DEFINES_AND_LANGUAGE, "preprocess $1 with conditional defines $2 and $3 using $4 as the language to display errors")
    .addMessage(texts.VERSION_INFO, "get version info")
    .addMessage(texts.SHOW_MESSAGE, "show this message")
    .addMessage(preprods.UNCLOSED_BRANCH, "this branch was not closed")
    .addMessage(preprods.INEXISTENT_FILE, "the file '$1' does not exist")
    .addMessage(preprods.INEXISTENT_INCLUDE, "the included file '$1' does not exist")
    .addMessage(preprods.UNEXPECTED_COMMAND, "unexpected '$1' command")
    .addMessage(preprods.NO_PREFIX, "no comment prefix supplied")
    .addMessage(preprods.PREFIX_LENGTH, "the comment prefix must be only one character long")
    .addMessage(preprods.UNDEFERRABLE_COMMAND, "can not defer a '$1' command")
    .addMessage(preprods.MANDATORY_STANDARD, "the STANDARD feature commands can not be disabled")
    .addMessage(preprods.BOOLEAN_ONLY, "only on/off values are valid")
    .addMessage(preprods.UNKNOWN_FEATURE, "feature '$1' is unknown")
    .addMessage(preprods.ARGUMENTS_COUNT, "arguments expected: $1")
    .addMessage(preprods.NO_ARGUMENTS, "no arguments supplied")
    .addMessage(preprods.DISABLED_COMMAND, "command '$1' belongs to a disabled feature")
    .addMessage(preprods.UNKNOWN_COMMAND,"command '$1' is unknown")

template getESMessages(): JArrayBuilder =
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
    .addMessage(messages.GENERATED_FILE, "ARCHIVO GENERADO")
    .addMessage(messages.GENERATED_DIRECTORY, "DIRECTORIO GENERADO")
    .addMessage(messages.REMOVED_FILE, "ARCHIVO REMOVIDO")
    .addMessage(messages.UNREMOVABLE_FILE, "ARCHIVO IRREMOVIBLE")
    .addMessage(messages.REMOVED_DIRECTORY, "DIRECTORIO REMOVIDO")
    .addMessage(messages.UNREMOVABLE_DIRECTORY, "DIRECTORIO IRREMOVIBLE")
    .addMessage(captions.COMMANDS, "comandos")
    .addMessage(captions.HELP, "ayuda")
    .addMessage(captions.DEFINE, "definir")
    .addMessage(captions.LANGUAGE, "languaje")
    .addMessage(captions.VERSION, "versión")
    .addMessage(captions.FLAGS, "banderas")
    .addMessage(captions.USAGE, "uso")
    .addMessage(captions.SUPPORTED, "soportado")
    .addMessage(captions.EXAMPLES, "ejemplos")
    .addMessage(texts.GENERATED_WITH, "generado con $1")
    .addMessage(texts.PREPROCESS_FILE, "preprocesar $1")
    .addMessage(texts.PREPROCESS_DEFINES, "preprocesar $1 con definiciones conditionales $2, $3 y $4")
    .addMessage(texts.PREPROCESS_LANGUAGE, "preprocesar $1 usando $2 como language para mostrar errores")
    .addMessage(texts.PREPROCESS_DEFINES_AND_LANGUAGE, "preprocesar $1 con definiciones conditionales $2 y $3 usando $4 como language para mostrar errores")
    .addMessage(texts.VERSION_INFO, "obtener información de la versión")
    .addMessage(texts.SHOW_MESSAGE, "mostrar este mensaje")
    .addMessage(preprods.UNCLOSED_BRANCH, "esta rama no ha sido cerrada")
    .addMessage(preprods.INEXISTENT_FILE, "el archivo '$1' no existe")
    .addMessage(preprods.INEXISTENT_INCLUDE, "el archivo incluído '$1' no existe")
    .addMessage(preprods.UNEXPECTED_COMMAND, "comando '$1' inesperado")
    .addMessage(preprods.NO_PREFIX, "prefijo de comentario no suministrado")
    .addMessage(preprods.PREFIX_LENGTH, "el prefijo de comentario debe ser sólo de un caracter de largo")
    .addMessage(preprods.UNDEFERRABLE_COMMAND, "no se puede diferir un comando '$1'")
    .addMessage(preprods.MANDATORY_STANDARD, "los comandos del feature STANDARD no se pueden deshabilitar")
    .addMessage(preprods.BOOLEAN_ONLY, "sólo valores on/off son válidos")
    .addMessage(preprods.UNKNOWN_FEATURE, "el feature '$1' es desconocido")
    .addMessage(preprods.ARGUMENTS_COUNT, "argumentos esperados: $1")
    .addMessage(preprods.NO_ARGUMENTS, "sin argumentos suministrados")
    .addMessage(preprods.DISABLED_COMMAND, "el comando '$1' pertenece a un feature deshabilitado")
    .addMessage(preprods.UNKNOWN_COMMAND,"el comando '$1' es desconocido")

template getPTMessages(): JArrayBuilder =
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
    .addMessage(messages.GENERATED_FILE, "ARQUIVO GERADO")
    .addMessage(messages.GENERATED_DIRECTORY, "DIRECTORIO GERADO")
    .addMessage(messages.REMOVED_FILE, "ARQUIVO REMOVIDO")
    .addMessage(messages.UNREMOVABLE_FILE, "ARQUIVO IRREMOVIBLE")
    .addMessage(messages.REMOVED_DIRECTORY, "DIRECTORIO REMOVIDO")
    .addMessage(messages.UNREMOVABLE_DIRECTORY, "DIRECTORIO IRREMOVIBLE")
    .addMessage(captions.COMMANDS, "comandos")
    .addMessage(captions.HELP, "ajuda")
    .addMessage(captions.DEFINE, "definir")
    .addMessage(captions.LANGUAGE, "linguagem")
    .addMessage(captions.VERSION, "versão")
    .addMessage(captions.FLAGS, "bandeiras")
    .addMessage(captions.USAGE, "uso")
    .addMessage(captions.SUPPORTED, "suportado")
    .addMessage(captions.EXAMPLES, "exemplos")
    .addMessage(texts.GENERATED_WITH, "gerado com $1")
    .addMessage(texts.PREPROCESS_FILE, "preprocessar $1")
    .addMessage(texts.PREPROCESS_DEFINES, "preprocessar $1 com definições condicionais $2, $3 e $4")
    .addMessage(texts.PREPROCESS_LANGUAGE, "preprocessar $1 usando $2 como linguagem para mostrar erros")
    .addMessage(texts.PREPROCESS_DEFINES_AND_LANGUAGE, "preprocessar $1 com definições condicionais $2 e $3 usando $4 como linguagem para mostrar erros")
    .addMessage(texts.VERSION_INFO, "obter informação da versão")
    .addMessage(texts.SHOW_MESSAGE, "mostrar esta mensagem")
    .addMessage(preprods.UNCLOSED_BRANCH, "este ramo não foi fechado")
    .addMessage(preprods.INEXISTENT_FILE, "o arquivo '$1' não existe")
    .addMessage(preprods.INEXISTENT_INCLUDE, "o arquivo incluído '$1' não existe")
    .addMessage(preprods.UNEXPECTED_COMMAND, "comando '$1' inesperado")
    .addMessage(preprods.NO_PREFIX, "prefixo de comentário não fornecido")
    .addMessage(preprods.PREFIX_LENGTH, "o prefixo de comentário deve ser só de um caractere de comprimento")
    .addMessage(preprods.UNDEFERRABLE_COMMAND, "não se pode adiar um comando '$1'")
    .addMessage(preprods.MANDATORY_STANDARD, "os comandos do feature STANDARD não podem ser desabilitados")
    .addMessage(preprods.BOOLEAN_ONLY, "só valores on/off são válidos")
    .addMessage(preprods.UNKNOWN_FEATURE, "o feature '$1' é desconhecido")
    .addMessage(preprods.ARGUMENTS_COUNT, "argumentos esperados: $1")
    .addMessage(preprods.NO_ARGUMENTS, "sem argumentos fornecidos")
    .addMessage(preprods.DISABLED_COMMAND, "o comando '$1' pertence a um feature desabilitado")
    .addMessage(preprods.UNKNOWN_COMMAND,"o comando '$1' é desconhecido")

# EVENTS

template loadParameters(kvm: RodsterAppKvm, nfo: RodsterAppInformation, loc: RodsterAppI18n) =
  const HELP_BUILDERS = (
    example: func (parameters: openarray[string], description: string): string = lined(
      spaced(STRINGS_TAB, APP.NAME, spaced(parameters)),
      spaced(STRINGS_TAB, STRINGS_MINUS & STRINGS_MINUS, description)
    ),
    detail: func (name: string, items: openarray[string]): string = spaced(
      name & STRINGS_COLON, spaced(items)
    ),
    command: func (name: string, lines: openarray[string]): string = (
      result = spaced(STRINGS_TAB, name);
      for line in lines:
        result &= STRINGS_EOL & spaced(STRINGS_TAB, STRINGS_TAB, line)
    ),
    section: func (name: string, lines: openarray[string]): string = lined(
      spaced(STRINGS_MINUS, name & STRINGS_COLON), lined(lines)
    ),
    content: func (parts: varargs[string]): string = (
      result = lined(TITLE, APP.COPYRIGHT, STRINGS_EMPTY);
      for part in parts:
        result &= enclose(part, STRINGS_EOL)
    )
  )
  template showHelp() =
    withIt HELP_BUILDERS:
      quit(it.content(it.section(loc.getText(captions.COMMANDS), [
        it.command(loc.getText(captions.DEFINE), [
          it.detail(loc.getText(captions.FLAGS), [SWITCHES.DEFINE.join(STRINGS_COMMA & STRINGS_SPACE).replace(STRINGS_COLON, STRINGS_EMPTY)]),
          it.detail(loc.getText(captions.USAGE), [APP.NAME, bracketize(chevronize("define-flag") & STRINGS_COLON & chevronize("defines.csv"))])
        ]),
        it.command(loc.getText(captions.LANGUAGE), [
          it.detail(loc.getText(captions.FLAGS), [SWITCHES.LANGUAGE.join(STRINGS_COMMA & STRINGS_SPACE)]),
          it.detail(loc.getText(captions.USAGE), [APP.NAME, bracketize(chevronize("language-flag") & STRINGS_COLON & chevronize("language"))]),
          it.detail(loc.getText(captions.SUPPORTED), [APP.LANGUAGES.join(STRINGS_COMMA & STRINGS_SPACE)])
        ]),
        it.command(loc.getText(captions.VERSION), [
          it.detail(loc.getText(captions.FLAGS), [SWITCHES.VERSION.join(STRINGS_COMMA & STRINGS_SPACE)]),
          it.detail(loc.getText(captions.USAGE), [APP.NAME, chevronize("version-flag")])
        ]),
        it.command(loc.getText(captions.HELP), [
          it.detail(loc.getText(captions.FLAGS), [SWITCHES.HELP.join(STRINGS_COMMA & STRINGS_SPACE)]),
          it.detail(loc.getText(captions.USAGE), [APP.NAME, bracketize(chevronize("help-flag"))])
        ])
      ]), it.section(loc.getText(captions.EXAMPLES), [
        it.example(["myfile.unim"], loc.getText(texts.PREPROCESS_FILE, @["myfile.unim"])),
        it.example(["-d:BLAH,FOO,BAR", "myfile.unim"], loc.getText(texts.PREPROCESS_DEFINES, @["myfile.unim", "BLAH", "FOO", "BAR"])),
        it.example(["-l:es", "myfile.unim"], loc.getText(texts.PREPROCESS_LANGUAGE, @["myfile.unim", "Spanish"])),
        it.example(["-l:PT", "-d:DEF1,DEF2", "myfile.unim"], loc.getText(texts.PREPROCESS_DEFINES_AND_LANGUAGE, @["myfile.unim", "DEF1", "DEF2", "Portuguese"])),
        it.example(["-v"], loc.getText(texts.VERSION_INFO)),
        it.example(["-h"], loc.getText(texts.SHOW_MESSAGE))
      ])), 0)
  template getSwitchValue(switch: openarray[string], default: string): string =
    let idxs = nfo.findArgumentsWithPrefix(switch)
    if idxs.len > 1: showHelp()
    elif idxs.len == 0: default
    else: nfo.getArgumentWithoutPrefix(idxs[0], switch)
  template loadLanguageMessages(language: string, builder: JArrayBuilder) =
    discard loc.loadTextsFromJArray(language, builder.getAsJArray())
  loadLanguageMessages(LANGUAGE_CODES.EN, getENMessages())
  loadLanguageMessages(LANGUAGE_CODES.ES, getESMessages())
  loadLanguageMessages(LANGUAGE_CODES.PT, getPTMessages())
  let lang = toLowerAscii(getSwitchValue(SWITCHES.LANGUAGE, LANGUAGE_CODES.EN))
  if lang notin APP.LANGUAGES:
    showHelp()
  loc.setCurrentLocale(lang)
  let args = nfo.getArguments()
  if args.len == 0 or nfo.hasArgument(SWITCHES.HELP):
    showHelp()
  if nfo.hasArgument(SWITCHES.VERSION):
    quit(lined(TITLE, APP.COPYRIGHT), 0)
  let input = args[^1]
  if filesDontExist(input):
    showHelp()
  kvm[KEYS.INPUT] = input
  kvm[KEYS.DEFINES] = getSwitchValue(SWITCHES.DEFINE, STRINGS_EMPTY)

template useEngine(kvm: RodsterAppKvm, nfo: RodsterAppInformation, loc: RodsterAppI18n) =
  let engine = newUbernimEngine(nfo.getVersion(), spaced(loc.getText(texts.GENERATED_WITH, @[TITLE])))
  engine.setExecutableInvoker proc (definesCsv, file: string): bool =
    execShellCmd(spaced(nfo.getFilename(), STRINGS_MINUS & STRINGS_LOWERCASE_L & STRINGS_COLON & loc.getCurrentLocale(), NIMC_DEFINE & definesCsv, file)) != 0
  engine.setErrorGetter proc (msg: string, values: varargs[string]): string =
    loc.getText(msg, newStringSeq(values))
  engine.setErrorHandler proc (msg: string) =
    quit(spaced(ansiRed(spaced(STRINGS_ASTERISK, bracketize("ERROR"))), msg), -1)
  engine.setCleanupFormatter proc (action, file: string): string =
    spaced(STRINGS_ASTERISK, parenthesize(loc.getText(action)), file) & STRINGS_EOL
  engine.setPreprodFormatter proc (code: PreprodError, argument: string = STRINGS_EMPTY): string =
    case code:
      of peUnknownError: argument
      of peUnclosedBranch: loc.getText(preprods.UNCLOSED_BRANCH, @[argument])
      of peInexistentFile: loc.getText(preprods.INEXISTENT_FILE, @[argument])
      of peInexistentInclude: loc.getText(preprods.INEXISTENT_INCLUDE, @[argument])
      of peUnexpectedCommand: loc.getText(preprods.UNEXPECTED_COMMAND, @[argument])
      of peNoPrefix: loc.getText(preprods.NO_PREFIX, @[argument])
      of pePrefixLength: loc.getText(preprods.PREFIX_LENGTH, @[argument])
      of peUndeferrableCommand: loc.getText(preprods.UNDEFERRABLE_COMMAND, @[argument])
      of peMandatoryStandard: loc.getText(preprods.MANDATORY_STANDARD, @[argument])
      of peBooleanOnly: loc.getText(preprods.BOOLEAN_ONLY, @[argument])
      of peUnknownFeature: loc.getText(preprods.UNKNOWN_FEATURE, @[argument])
      of peArgumentsCount: loc.getText(preprods.ARGUMENTS_COUNT, @[argument])
      of peNoArguments: loc.getText(preprods.NO_ARGUMENTS, @[argument])
      of peDisabledCommand: loc.getText(preprods.DISABLED_COMMAND, @[argument])
      of peUnknownCommand: loc.getText(preprods.UNKNOWN_COMMAND, @[argument])
  withIt engine.run(kvm[KEYS.INPUT], kvm[KEYS.DEFINES].split(STRINGS_COMMA)):
    kvm[KEYS.ERRORLEVEL] = $(if it.isProject: 0 else: it.compilationErrorlevel)
    kvm[KEYS.REPORT] = it.cleanupReport

template informResult(kvm: RodsterAppKvm) =
  let errorlevel = tryParseInt(kvm[KEYS.ERRORLEVEL], -1)
  let highlighter = if errorlevel == 0: ansiGreen else: ansiBlue
  let report = kvm[KEYS.REPORT] & highlighter(spaced(spaced(STRINGS_ASTERISK, bracketize("OK")), parenthesize($errorlevel)))
  let heading = ansiMagenta(spaced(STRINGS_ASTERISK, TITLE, parenthesize(kvm[KEYS.INPUT])))
  quit(lined(heading, report), errorlevel)

let events = (
  initializer: RodsterAppEvent (app: RodsterApplication) => loadParameters(app.getKvm(), app.getInformation(), app.getI18n()),
  main: RodsterAppEvent (app: RodsterApplication) => useEngine(app.getKvm(), app.getInformation(), app.getI18n()),
  finalizer: RodsterAppEvent (app: RodsterApplication) => informResult(app.getKvm())
)

# MAIN

run newRodsterApplication(APP.NAME, APP.VERSION, events)
