# ubernim / LANGUAGE IMPLEMENTATION #
#-----------------------------------#

import
  xam,
  header

use strutils,startsWith
use strutils,endsWith
use strutils,strip
use strutils,replace
use strutils,join
use strutils,split
use strutils,find
use strutils,toLower

# ITEM

func setupItem*(item: LanguageItem, name: string) =
  item.public = name.endsWith(STRINGS_ASTERISK)
  item.name = if item.public: dropRight(name, 1) else: name
  if item.name.find(STRINGS_BRACKETS_OPEN) > -1 and item.name.find(STRINGS_BRACKETS_CLOSE) > -1:
    let parts = item.name.split(STRINGS_BRACKETS_OPEN)
    item.name = parts[0]
    item.generics = parts[1].replace(STRINGS_BRACKETS_CLOSE, STRINGS_EMPTY)
  else:
    item.generics = STRINGS_EMPTY

proc readField(fld: LanguageItem, line: string): bool =
  result = true
  let lp = line.split(STRINGS_COLON)
  if lp.len != 2:
    return false
  let n = strip(lp[0])
  let t = strip(lp[1])
  if not haveContent(n, t) or t.find(STRINGS_EQUAL) != -1:
    return false
  fld.setupItem(n)
  if fld.kind == DIVISIONS_RECORD and fld.public:
    return false
  fld.data_type = t

proc readMethod(mtd: LanguageItem, line: string): bool =
  result = true
  let z = stripLeft(line)
  if not mtd.data_getter:
    # definition
    if line.find(STRINGS_PARENTHESES_OPEN) == -1 or line.find(STRINGS_PARENTHESES_CLOSE) == -1:
      mtd.data_getter = z.startsWith(STRINGS_MINOR)
      return if mtd.data_getter: readField(mtd, dropLeft(z, 1)) else: false
  else:
    # from getter implementation
    return readField(mtd, z)
  let x = line.split(STRINGS_PARENTHESES_OPEN)
  if x.len != 2:
    return false
  let m = strip(x[0])
  if not hasContent(m):
    return false
  let s = m.startsWith(STRINGS_MAJOR)
  let c = m.startsWith(STRINGS_PLUS)
  let f = m.startsWith(STRINGS_EXCLAMATION)
  let n = if s or c or f: dropLeft(m, 1) else: m
  let y = strip(x[1]).split(STRINGS_PARENTHESES_CLOSE)
  if y.len != 2:
    return false
  let a = y[0]
  let d = y[1]
  #if not c and (not hasContent(d) or d.find(STRINGS_COLON) == -1):
  #  return false
  let t = d.replace(STRINGS_COLON, STRINGS_EMPTY).replace(STRINGS_EQUAL, STRINGS_EMPTY).strip()
  #if (not c and not hasContent(t)): # or t.find(STRINGS_EQUAL) != -1:
  #  return false
  mtd.setupItem(n)
  mtd.data_type = t
  mtd.data_constructor = c
  mtd.data_setter = s
  mtd.data_sealed = f
  mtd.data_extra = a

proc read*(mbr: LanguageItem, line: string): bool =
  case mbr.kind:
  of SUBDIVISIONS_FIELDS, SUBDIVISIONS_MEMBERS:
    mbr.readField(line)
  of SUBDIVISIONS_METHODS, SUBDIVISIONS_TEMPLATES, SUBDIVISIONS_ROUTINES:
    mbr.readMethod(line)
  else:
    false

func hasValidIdentifier*(mbr: LanguageItem): bool =
  isValidNimIdentifier(mbr.name) and toLower(mbr.name) notin UNIMLANG_KEYWORDS

func newLanguageItem*(kind: string): LanguageItem =
  result = new LanguageItem
  result.kind = kind
  result.docs = @[]

# DIVISION

func newLanguageDivision*(kind: string, name: string): LanguageDivision =
  result = new LanguageDivision
  result.kind = kind
  result.data_sealed = kind == DIVISIONS_CLASS and name.startsWith(STRINGS_EXCLAMATION)
  let n = if result.data_sealed: dropLeft(name, 1) else: name
  result.setupItem(n)
  result.applies = @[]
  result.extends = STRINGS_EMPTY
  result.items = @[]

template makeDefaultDivisions*(): LanguageDivisions =
  @[newLanguageDivision(DIVISIONS_DEFAULT, SCOPE_GLOBAL)]
