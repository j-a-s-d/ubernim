# ubernim / ERRORS #
#------------------#

import
  xam, preprod

const
  WORDS_AT* = "at"
  WORDS_FOR* = "for"
  WORDS_WITH* = "with"
  WORDS_ITEM* = "item"
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
error BAD_STATE, "bad state"
error BAD_STATE_IN_PREVIEW, "bad state in preview"
error BAD_VERSION, "a newer version is required"
error BAD_FLAG, "only yes/no values allowed"
error BAD_MODE, "only free/strict values allowed"
error BAD_FREQUENCY, "only always/once values allowed"
error BAD_CLEANUP, "only ignored/informed/performed values allowed"
error BAD_TARGET, "only cc/cpp/objc/js values allowed"
error STRICT_MODE, "only ubernim code is allowed in strict mode"
error ONLY_TOP_LEVEL, "this can only be defined in the top level"
error DONT_TOP_LEVEL, "this can not be defined in the top level"
error CANT_CREATE_DIRECTORY, "can not create directory"
error CANT_APPEND_FILE, "can not append file"
error CANT_WRITE_FILE, "can not write file"
error CANT_REMOVE_FILE, "can not remove file"
error CANT_BE_REQUIRED, "this can not be required"
error NO_RECURSIVE_REQUIRE, "recursive require is not allowed"
error NO_CIRCULAR_REFERENCE, "circular references are not allowed"
error INVALID_IDENTIFIER, "invalid identifier"
error UNDEFINED_REFERENCE, "undefined reference"
error ALREADY_DEFINED, "already defined"
error NEVER_DEFINED, "never defined"
error WRONGLY_DEFINED, "wrongly defined"
error CANT_HOLD_FIELDS, "this can not hold fields"
error CANT_HOLD_METHODS, "this can not hold methods"
error CANT_HOLD_TEMPLATES, "this can not hold templates"
error CANT_HOLD_PRAGMAS, "this can not hold pragmas"
error CANT_HOLD_VALUE, "this can not hold value"
error CANT_OUTPUT_DOCS, "this can not output documentation"
error CANT_OUTPUT_CODE, "this can not output code"
error UNDEFINED_MEMBER_VALUE, "undefined value for immutable member"
error DEFINE_BEFORE_VALUE, "this must be defined before code or value"
error ALREADY_RENDERED, "this is already rendered"
error NOT_APPLICABLE, "only a compound, an interface or a protocol can be applied to something else"
error NOT_IMPLIABLE, "only same type can be implied"
error ALREADY_APPLYING, "this is already applying"
error ALREADY_IMPLYING, "this is already implying"
error ALREADY_EXTENDING, "this is already extending"
error CANT_EXTEND_INEXISTENT, "can not extend from inexistent"
error CANT_EXTEND_DIFFERENT, "can not extend from a different type"
error CANT_EXTEND_SEALED, "can not extend from sealed"
error RECORDS_CANT_EXTEND, "records can not be extended, try to imply if it's possible"
error RECORDS_DONT_ASTERISK,  "the * modifier is not allowed in record fields"
error VISIBILITY_DOESNT_MATCH, "visibility does not match definition"
error CANT_WRITE_CONFIG, "can not write configuration file"
error CANT_WRITE_OUTPUT, "can not write output file"
error MINIMUM_NIM_VERSION, "the installed nim version does not met the specified minimum"
