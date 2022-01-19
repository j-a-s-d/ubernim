# ubernim / CLEANUP #
#-------------------#

import
  xam, preprod,
  constants, status

use os,tryRemoveFile

let cleanupPerformer* = proc (state: var PreprodState, formatter: proc (action, file: string): string): string =
  let ls = loadUbernimStatus(state)
  let value = state.getPropertyValue(UNIM_CLEANUP_KEY)
  if value != VALUE_IGNORED:
    if value == VALUE_PERFORMED:
      ls.files.generated.each gf:
        if tryRemoveFile(gf):
          result &= formatter("REMOVED", gf)
        else:
          result &= spaced(STRINGS_ASTERISK, parenthesize("UNREMOVABLE"), gf) & STRINGS_EOL
    else: # value == VALUE_INFORMED
      ls.files.generated.each gf:
        result &= spaced(STRINGS_ASTERISK, parenthesize("GENERATED"), gf) & STRINGS_EOL
