# ubernim / LANGUAGE DIVISION #
#-----------------------------#

import
  xam, preprod,
  header, item,
  ../status

use strutils,startsWith

func newLanguageDivision*(kind: string, name: string): LanguageDivision =
  result = new LanguageDivision
  result.kind = kind
  result.data_sealed = kind == DIVISIONS_CLASS and name.startsWith(STRINGS_EXCLAMATION)
  let n = if result.data_sealed: dropLeft(name, 1) else: name
  result.setupItem(n)
  result.applies = @[]
  result.extends = STRINGS_EMPTY
  result.items = @[]

func openDivision*(state: var PreprodState, kind: string, name: string) =
  let ls = loadUbernimStatus(state)
  var item = LanguageItem()
  item.setupItem(name)
  let p = ls.getDivision(item.name)
  if not assigned(p):
    ls.language.divisions.add(newLanguageDivision(kind, name))
  ls.language.currentName = item.name
  ls.language.currentKind = kind
  ls.language.currentImplementation = nil

func closeDivision*(state: var PreprodState) =
  let ls = loadUbernimStatus(state)
  ls.language.currentName = STRINGS_EMPTY
  ls.language.currentKind = STRINGS_EMPTY
  ls.language.currentImplementation = nil

template makeDefaultDivisions*(): LanguageDivisions =
  @[newLanguageDivision(DIVISIONS_DEFAULT, SCOPE_GLOBAL)]
