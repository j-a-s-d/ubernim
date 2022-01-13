# ubernim / LANGUAGE DIVISION #
#-----------------------------#

import
  xam, preprod,
  header, member, state

use strutils,startsWith

func newLanguageDivision*(kind: string, name: string): LanguageDivision =
  result = new LanguageDivision
  result.kind = kind
  result.data_sealed = kind == DIVISIONS_CLASS and name.startsWith(STRINGS_EXCLAMATION)
  let n = if result.data_sealed: dropLeft(name, 1) else: name
  result.setupMember(n)
  result.applies = @[]
  result.implies = STRINGS_EMPTY
  result.extends = STRINGS_EMPTY
  result.members = @[]

func openDivision*(state: var PreprodState, kind: string, name: string) =
  let ls = loadLanguageState(state)
  var item = LanguageMember()
  item.setupMember(name)
  let p = ls.getDivision(item.name)
  if not assigned(p):
    ls.divisions.add(newLanguageDivision(kind, name))
  ls.currentName = item.name
  ls.currentKind = kind
  ls.currentImplementation = nil

func closeDivision*(state: var PreprodState) =
  let ls = loadLanguageState(state)
  ls.currentName = STRINGS_EMPTY
  ls.currentKind = STRINGS_EMPTY
  ls.currentImplementation = nil
