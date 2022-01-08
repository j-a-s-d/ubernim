# ubernim / ERRORS #
#------------------#

import
  xam, preprod

const
  WORDS_AT* = "at"
  WORDS_NO* = "no"
  WORDS_YES* = "yes"
  WORDS_FOR* = "for"
  WORDS_WITH* = "with"
  WORDS_FIELD* = "field"
  WORDS_GETTER* = "getter"
  WORDS_SETTER* = "setter"
  WORDS_METHOD* = "method"
  WORDS_MEMBER* = "member"
  WORDS_SEALED* = "sealed"
  WORDS_PRAGMAS* = "pragmas"
  WORDS_ROUTINE* = "routine"
  WORDS_TEMPLATE* = "template"
  WORDS_GENERATED* = "generated"
  WORDS_CONSTRUCTOR* = "constructor"

template error(id: untyped, msg: string): untyped =
  template id*(extra: string = STRINGS_EMPTY): PreprodResult {.inject.} = BAD(spaced(msg, extra))

error UNEXPECTED, "an unexpected error occurred"
error BAD_VERSION, "a newer version is required"
error BAD_STATE, "bad state"
error BAD_STATE_IN_PREVIEW, "bad state in preview"
error BAD_FLAG, "only yes/no values allowed"
error ONLY_TOP_LEVEL, "this can only be defined in the top level"
error DONT_TOP_LEVEL, "this can not be defined in the top level"
error CANT_CREATE_DIRECTORY, "can not create directory"
error CANT_APPEND_FILE, "can not append file"
error CANT_WRITE_FILE, "can not write file"
error CANT_REMOVE_FILE, "can not remove file"
error CANT_BE_REQUIRED, "this can not be required"
error NO_RECURSIVE_REQUIRE, "recursive require is not allowed"
error INVALID_IDENTIFIER, "invalid identifier"
error UNDEFINED_REFERENCE, "undefined reference"
error ALREADY_DEFINED, "already defined"
error NEVER_DEFINED, "never defined"
error WRONGLY_DEFINED, "wrongly defined"
error CANT_HAVE_FIELDS, "this can not have fields"
error CANT_HAVE_METHODS, "this can not have methods"
error CANT_HAVE_TEMPLATES, "this can not have templates"
error CANT_HAVE_PRAGMAS, "this can not have pragmas"
error CANT_OUTPUT_DOCS, "this can not output documentation"
error CANT_OUTPUT_CODE, "this can not output code"
error NOT_APPLICABLE, "only a compound, an interface or a protocol can be applied to something else"
error NOT_IMPLIABLE, "only same type can be implied"
error ALREADY_APPLYING, "this is already applying"
error ALREADY_IMPLYING, "this is already implying"
error ALREADY_EXTENDING, "this is already extending"
error CANT_EXTEND_INEXISTENT, "can not extend from inexistent"
error CANT_EXTEND_SEALED, "can not extend from sealed"
error RECORDS_CANT_EXTEND, "records can not be extended, try to imply if it's possible"
error RECORDS_DONT_ASTERISK,  "the * modifier is not allowed in record fields"
error VISIBILITY_DOESNT_MATCH, "visibility does not match definition"
error CANT_WRITE_CONFIG, "can not write configuration file"
error CANT_WRITE_OUTPUT, "can not write output file"
