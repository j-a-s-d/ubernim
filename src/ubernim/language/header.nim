# ubernim / LANGUAGE HEADER #
#---------------------------#

import
  xam, preprod

# CONSTANTS

const
  KEY_DIVISION* = "DIVISION"
  KEY_SUBDIVISION* = "SUBDIVISION"
  SCOPE_GLOBAL* = "<GLOBAL>"
  DIVISIONS_NOTE* = "NOTE"
  DIVISIONS_COMPOUND* = "COMPOUND"
  DIVISIONS_INTERFACE* = "INTERFACE"
  DIVISIONS_PROTOCOL* = "PROTOCOL"
  DIVISIONS_RECORD* = "RECORD"
  DIVISIONS_CLASS* = "CLASS"
  DIVISIONS_CONSTRUCTOR* = "CONSTRUCTOR" # implementation
  DIVISIONS_METHOD* = "METHOD" # implementation
  DIVISIONS_TEMPLATE* = "TEMPLATE" # implementation
  DIVISIONS_ROUTINES* = "ROUTINES" # global
  DIVISIONS_ROUTINE* = "ROUTINE" # implementation
  DIVISIONS_ON_APPLY* = [DIVISIONS_COMPOUND, DIVISIONS_INTERFACE, DIVISIONS_PROTOCOL]
  DIVISIONS_WITH_CODE* = [DIVISIONS_CONSTRUCTOR, DIVISIONS_METHOD, DIVISIONS_TEMPLATE, DIVISIONS_ROUTINE]
  DIVISIONS_WITH_FIELDS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL, DIVISIONS_COMPOUND]
  DIVISIONS_WITH_METHODS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL, DIVISIONS_INTERFACE]
  DIVISIONS_WITH_TEMPLATES* = [DIVISIONS_CLASS, DIVISIONS_RECORD]
  DIVISIONS_WITH_DOCS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_CONSTRUCTOR, DIVISIONS_METHOD, DIVISIONS_TEMPLATE, DIVISIONS_ROUTINE]
  SUBDIVISIONS_BODY* = "BODY" # implementation
  SUBDIVISIONS_DOCS* = "DOCS"
  SUBDIVISIONS_CLAUSES* = "CLAUSES" # where attribute clauses can appear (ex. extends, applies, etc)
  SUBDIVISIONS_FIELDS* = "FIELDS"
  SUBDIVISIONS_METHODS* = "METHODS"
  SUBDIVISIONS_TEMPLATES* = "TEMPLATES"

# MEMBER

type
  LanguageMember* = ref object of RootObj
    #line*: string
    kind*: string
    name*: string
    public*: bool
    imported*: bool
    generics*: string
    data_type*: string # methods: return type & fields: value type
    data_extra*: string # methods: parameters & class fields: initialization value
    data_constructor*: bool # methods: constructor flag & fields: unused
    data_sealed*: bool # class and methods: sealed flag & fields: unused
    pragmas*: string
    docs*: StringSeq
    rendered*: bool
  LanguageMembers* = seq[LanguageMember]

# STATE

type
  LanguageDivision* = ref object of LanguageMember
    applies*: StringSeq
    implies*: string
    extends*: string
    members*: LanguageMembers
  LanguageDivisions* = seq[LanguageDivision]

# STATE

type
  TLanguageState* = object of PreprodTag
    semver*: SemanticVersion
    signature*: string
    unit*: string
    currentName*: string
    currentKind*: string
    currentImplementation*: LanguageMember
    divisions*: LanguageDivisions
  LanguageState* = ptr TLanguageState
