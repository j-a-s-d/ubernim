# ubernim / LANGUAGE HEADER #
#---------------------------#

import
  xam

# CONSTANTS

const
  UNIMLANG_SELF* = "self"
  UNIMLANG_PARENT* = "parent"
  UNIMLANG_KEYWORDS* = [UNIMLANG_SELF, UNIMLANG_PARENT]
  SCOPE_GLOBAL* = "<GLOBAL>"
  DIVISIONS_NOTE* = "NOTE"
  DIVISIONS_IMPORTS* = "IMPORTS"
  DIVISIONS_EXPORTS* = "EXPORTS"
  DIVISIONS_COMPOUND* = "COMPOUND"
  DIVISIONS_INTERFACE* = "INTERFACE"
  DIVISIONS_PROTOCOL* = "PROTOCOL"
  DIVISIONS_RECORD* = "RECORD"
  DIVISIONS_CLASS* = "CLASS"
  DIVISIONS_CONSTRUCTOR* = "CONSTRUCTOR" # implementation
  DIVISIONS_GETTER* = "GETTER" # implementation
  DIVISIONS_SETTER* = "SETTER" # implementation
  DIVISIONS_METHOD* = "METHOD" # implementation
  DIVISIONS_TEMPLATE* = "TEMPLATE" # implementation
  DIVISIONS_DEFAULT* = "DEFAULT" # global
  DIVISIONS_ROUTINE* = "ROUTINE" # implementation
  DIVISIONS_MEMBER* = "MEMBER" # implementation
  DIVISIONS_ON_APPLY* = [DIVISIONS_COMPOUND, DIVISIONS_INTERFACE, DIVISIONS_PROTOCOL]
  DIVISIONS_WITH_CODE* = [DIVISIONS_CONSTRUCTOR, DIVISIONS_GETTER, DIVISIONS_SETTER, DIVISIONS_METHOD, DIVISIONS_TEMPLATE, DIVISIONS_ROUTINE, DIVISIONS_MEMBER]
  DIVISIONS_WITH_VALUE* = [DIVISIONS_MEMBER]
  DIVISIONS_WITH_FIELDS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL, DIVISIONS_COMPOUND]
  DIVISIONS_WITH_METHODS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL, DIVISIONS_INTERFACE]
  DIVISIONS_WITH_TEMPLATES* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_PROTOCOL]
  DIVISIONS_WITH_DOCS* = [DIVISIONS_CLASS, DIVISIONS_RECORD, DIVISIONS_CONSTRUCTOR, DIVISIONS_GETTER, DIVISIONS_SETTER, DIVISIONS_METHOD, DIVISIONS_TEMPLATE, DIVISIONS_ROUTINE, DIVISIONS_MEMBER]
  SUBDIVISIONS_BODY* = "BODY" # implementation
  SUBDIVISIONS_DOCS* = "DOCS"
  SUBDIVISIONS_CLAUSES* = "CLAUSES" # where attribute clauses can appear (ex. extends, applies, etc)
  SUBDIVISIONS_FIELDS* = "FIELDS"
  SUBDIVISIONS_METHODS* = "METHODS"
  SUBDIVISIONS_TEMPLATES* = "TEMPLATES"
  SUBDIVISIONS_MEMBERS* = "MEMBERS"
  SUBDIVISIONS_ROUTINES* = "ROUTINES"

# MEMBER

type
  LanguageItem* = ref object of RootObj
    #line*: string
    kind*: string
    name*: string
    public*: bool
    imported*: bool
    generics*: string
    data_type*: string # methods: return type & fields: value type
    data_extra*: string # methods: parameters & members and class fields: initialization value
    data_constructor*: bool # methods: constructor flag & fields: unused
    data_getter*: bool # methods: getter flag & fields: unused
    data_setter*: bool # methods: setter flag & fields: unused
    data_var*: bool # method: var flag & fields: unused
    data_sealed*: bool # class and methods: sealed flag & fields: unused
    pragmas*: string
    uses*: StringSeq
    docs*: StringSeq
    rendered*: bool
  LanguageItems* = seq[LanguageItem]

# DIVISION

type
  LanguageDivision* = ref object of LanguageItem
    applies*: StringSeq
    extends*: string
    items*: LanguageItems
  LanguageDivisions* = seq[LanguageDivision]
