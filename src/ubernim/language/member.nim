# ubernim / LANGUAGE MEMBER #
#---------------------------#

import
  strutils,
  xam,
  header

func `$`*(mbr: LanguageMember): string =
  bracketize([
    #"line: " & quote(mbr.line),
    "kind: " & quote(mbr.kind),
    "name: " & quote(mbr.name),
    "public: " & $mbr.public,
    "imported: " & $mbr.imported,
    "data_type: " & quote(mbr.data_type),
    "data_extra: " & quote(mbr.data_extra),
    "data_constructor: " & $mbr.data_constructor,
    "data_getter: " & $mbr.data_getter,
    "data_setter: " & $mbr.data_setter,
    "data_var: " & $mbr.data_var,
    "data_sealed: " & $mbr.data_sealed,
    "generics: " & $mbr.generics,
    "pragmas: " & $mbr.pragmas,
    "docs: " & $mbr.docs,
    "rendered: " & $mbr.rendered
  ].join(STRINGS_COMMA & STRINGS_SPACE))

func setupMember*(item: LanguageMember, name: string) =
  item.public = name.endsWith(STRINGS_ASTERISK)
  item.name = if item.public: dropRight(name, 1) else: name
  if item.name.find(STRINGS_BRACKETS_OPEN) > -1 and item.name.find(STRINGS_BRACKETS_CLOSE) > -1:
    let parts = item.name.split(STRINGS_BRACKETS_OPEN)
    item.name = parts[0]
    item.generics = parts[1].replace(STRINGS_BRACKETS_CLOSE, STRINGS_EMPTY)
  else:
    item.generics = STRINGS_EMPTY

proc readField(fld: LanguageMember, line: string): bool =
  result = true
  let lp = line.split(STRINGS_COLON)
  if lp.len != 2:
    return false
  let n = strip(lp[0])
  let t = strip(lp[1])
  if not haveContent(n, t) or t.find(STRINGS_EQUAL) != -1:
    return false
  fld.setupMember(n)
  if fld.kind == DIVISIONS_RECORD and fld.public:
    return false
  fld.data_type = t

proc readMethod(mtd: LanguageMember, line: string): bool =
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
  mtd.setupMember(n)
  mtd.data_type = t
  mtd.data_constructor = c
  mtd.data_setter = s
  mtd.data_sealed = f
  mtd.data_extra = a

proc read*(mbr: LanguageMember, line: string): bool =
  case mbr.kind:
  of SUBDIVISIONS_FIELDS:
    mbr.readField(line)
  of SUBDIVISIONS_METHODS:
    mbr.readMethod(line)
  of SUBDIVISIONS_TEMPLATES:
    mbr.readMethod(line)
  else:
    false

func newLanguageMember*(kind: string): LanguageMember =
  result = new LanguageMember
  result.kind = kind
  result.docs = @[]
