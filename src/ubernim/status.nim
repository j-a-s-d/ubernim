# ubernim / STATUS #
#------------------#

import
  xam, preprod,
  language / [header, implementation]

use strutils,startsWith
use strutils,endsWith
use strutils,strip

type
  TUbernimInfo = tuple
    semver: SemanticVersion
    signature: string
  TUbernimFiles = tuple
    callstack: StringSeq
    imported: StringSeq
    exported: StringSeq
    generated: StringSeq
  TUbernimLanguage = tuple
    currentName: string
    currentImplementation: LanguageItem
    divisions: LanguageDivisions
  TUbernimStatus = object of PreprodTag
    info*: TUbernimInfo
    files*: TUbernimFiles
    defines*: StringSeq
    language*: TUbernimLanguage
  UbernimStatus* = ptr TUbernimStatus

template makeUbernimStatus*(sver: SemanticVersion, sign: string, divs: LanguageDivisions = makeDefaultDivisions()): UbernimStatus =
  var ads = TUbernimStatus(
    info: TUbernimInfo (
      semver: sver,
      signature: sign
    ),
    files: TUbernimFiles (
      callstack: newStringSeq(),
      imported: newStringSeq(),
      exported: newStringSeq(),
      generated: newStringSeq()
    ),
    defines: newStringSeq(),
    language: TUbernimLanguage (
      currentName: STRINGS_EMPTY,
      currentImplementation: nil,
      divisions: divs
    )
  )
  addr(ads)

template loadUbernimStatus*(state: var PreprodState): UbernimStatus =
  cast[UbernimStatus](state.tag)

template storeUbernimStatus*(state: var PreprodState, ls: UbernimStatus) =
  state.tag = addr(ls[])

template freeUbernimStatus*(state: var PreprodState) =
  if assigned(state.tag):
    reset(state.tag)

# CALLSTACK

template inMainFile*(ls: UbernimStatus): bool =
  ls.files.callstack.len == 1

template isMainFile*(ls: UbernimStatus, name: string): bool =
  ls.files.callstack[0] == name

template getMainFile*(ls: UbernimStatus): string =
  ls.files.callstack[0]

template isCurrentFile*(ls: UbernimStatus, name: string): bool =
  ls.files.callstack[^1] == name

template getCurrentFile*(ls: UbernimStatus): string =
  ls.files.callstack[^1]

template isCircularReference*(ls: UbernimStatus, name: string): bool =
  name in ls.files.callstack

# DIVISION

func getDivision*(ls: UbernimStatus, name: string): LanguageDivision =
  let l = name.strip()
  let m = if l.endsWith(STRINGS_ASTERISK): dropRight(l, 1) else: l
  let n = if m.startsWith(STRINGS_EXCLAMATION): dropLeft(m, 1) else: m
  ls.language.divisions.each p:
    if p.name == n:
      return p
  return nil

func hasDivision*(ls: UbernimStatus, name: string): bool =
  assigned(getDivision(ls, name))

func isDivisionInherited*(ls: UbernimStatus, name: string): bool =
  ls.language.divisions.each p:
    if p.extends == name:
      return true
  return false

func closeDivision*(state: var PreprodState) =
  let ls = loadUbernimStatus(state)
  ls.language.currentName = STRINGS_EMPTY
  ls.language.currentImplementation = nil

func openDivision*(state: var PreprodState, kind: string, name: string) =
  let ls = loadUbernimStatus(state)
  var item = LanguageItem()
  item.setupItem(name)
  let p = ls.getDivision(item.name)
  if not assigned(p):
    ls.language.divisions.add(newLanguageDivision(kind, name))
  ls.language.currentName = item.name
  ls.language.currentImplementation = nil

# ITEM

const DUMMY_EXAMINER = func (member: LanguageItem): bool = true

func getItem*(ls: UbernimStatus, d: LanguageDivision, kind, name: string): LanguageItem =
  var m = d
  while assigned(m):
    m.items.each f:
      if f.kind == kind and f.name == name:
        return f
    m = ls.getDivision(m.extends)
  return nil

func hasItem(ls: UbernimStatus, d: LanguageDivision, kind, name: string, examiner: SingleArgProc[LanguageItem, bool] = DUMMY_EXAMINER): bool =
  var m = d
  while assigned(m):
    m.items.each f:
      if f.kind == kind and f.name == name:
        if examiner(f):
          return true
    m = ls.getDivision(m.extends)
  return false

func hasField*(ls: UbernimStatus, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageItem, bool] = DUMMY_EXAMINER): bool =
  ls.hasItem(d, SUBDIVISIONS_FIELDS, name, examiner)

func hasMethod*(ls: UbernimStatus, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageItem, bool] = DUMMY_EXAMINER): bool =
  ls.hasItem(d, SUBDIVISIONS_METHODS, name, examiner)

func hasTemplate*(ls: UbernimStatus, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageItem, bool] = DUMMY_EXAMINER): bool =
  ls.hasItem(d, SUBDIVISIONS_TEMPLATES, name, examiner)
