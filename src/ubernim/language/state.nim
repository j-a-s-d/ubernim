# ubernim / LANGUAGE STATE #
#--------------------------#

import
  xam, preprod,
  header

use strutils,startsWith
use strutils,endsWith
use strutils,strip

template makeLanguageState*(): LanguageState =
  var ads = TLanguageState(
    semver: newSemanticVersion(),
    signature: STRINGS_EMPTY,
    unit: STRINGS_EMPTY,
    currentName: STRINGS_EMPTY,
    currentKind: STRINGS_EMPTY,
    currentImplementation: nil,
    divisions: @[newLanguageDivision(DIVISIONS_ROUTINES, SCOPE_GLOBAL)]
  )
  addr(ads)

template loadLanguageState*(state: var PreprodState): LanguageState =
  cast[LanguageState](state.tag)

template storeLanguageState*(state: var PreprodState, ls: LanguageState) =
  state.tag = addr(ls[])

template freeLanguageState*(state: var PreprodState) =
  if assigned(state.tag):
    reset(state.tag)

func getDivision*(ls: LanguageState, name: string): LanguageDivision =
  let l = name.strip()
  let m = if l.endsWith(STRINGS_ASTERISK): dropRight(l, 1) else: l
  let n = if m.startsWith(STRINGS_EXCLAMATION): dropLeft(m, 1) else: m
  ls.divisions.each p:
    if p.name == n:
      return p
  return nil

proc getMember*(ls: LanguageState, d: LanguageDivision, kind, name: string): LanguageMember =
  var m = d
  while assigned(m):
    m.members.each f:
      if f.kind == kind and f.name == name:
        return f
    m = ls.getDivision(m.extends)
  return nil

const DUMMY_EXAMINER = proc (member: LanguageMember): bool = true

proc hasMember*(ls: LanguageState, d: LanguageDivision, kind, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  var m = d
  while assigned(m):
    m.members.each f:
      if f.kind == kind and f.name == name:
        return examiner(f)
    m = ls.getDivision(m.extends)
  return false

proc hasField*(ls: LanguageState, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_FIELDS, name, examiner)

proc hasMethod*(ls: LanguageState, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_METHODS, name, examiner)

proc hasTemplate*(ls: LanguageState, d: LanguageDivision, name: string, examiner: SingleArgProc[LanguageMember, bool] = DUMMY_EXAMINER): bool =
  ls.hasMember(d, SUBDIVISIONS_TEMPLATES, name, examiner)

func isDivisionInherited*(ls: LanguageState, name: string): bool =
  ls.divisions.each p:
    if p.extends == name:
      return true
  return false
