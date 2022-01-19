# ubernim / STATUS #
#------------------#

import
  xam, preprod,
  language / header

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
    currentKind: string
    currentImplementation: LanguageMember
    divisions: LanguageDivisions
  TUbernimStatus = object of PreprodTag
    info*: TUbernimInfo
    files*: TUbernimFiles
    language*: TUbernimLanguage
  UbernimStatus* = ptr TUbernimStatus

template makeUbernimStatus*(): UbernimStatus =
  var ads = TUbernimStatus(
    info: TUbernimInfo (
      semver: newSemanticVersion(),
      signature: STRINGS_EMPTY
    ),
    files: TUbernimFiles (
      callstack: newStringSeq(),
      imported: newStringSeq(),
      exported: newStringSeq(),
      generated: newStringSeq()
    ),
    language: TUbernimLanguage (
      currentName: STRINGS_EMPTY,
      currentKind: STRINGS_EMPTY,
      currentImplementation: nil,
      divisions: @[]
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

template isCurrentFile*(ls: UbernimStatus, name: string): bool =
  ls.files.callstack[^1] == name

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

# MEMBER

const DUMMY_EXAMINER = func (member: LanguageMember): bool = true

func getMember*(ls: UbernimStatus, d: LanguageDivision, kind, name: string): LanguageMember =
  var m = d
  while assigned(m):
    m.members.each f:
      if f.kind == kind and f.name == name:
        return f
    m = ls.getDivision(m.extends)
  return nil

func hasMember(ls: UbernimStatus, d: LanguageDivision, kind, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  var m = d
  while assigned(m):
    m.members.each f:
      if f.kind == kind and f.name == name:
        if examiner(f):
          return true
    m = ls.getDivision(m.extends)
  return false

func hasField*(ls: UbernimStatus, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_FIELDS, name, examiner)

func hasMethod*(ls: UbernimStatus, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_METHODS, name, examiner)

func hasTemplate*(ls: UbernimStatus, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_TEMPLATES, name, examiner)
