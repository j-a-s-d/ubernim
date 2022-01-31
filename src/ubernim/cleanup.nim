# ubernim / CLEANUP #
#-------------------#

import
  xam,
  status

use os,tryRemoveFile

proc removeGeneratedFiles*(ls: UbernimStatus, formatter: DoubleArgsProc[string, string, string]): string =
  ls.files.generated.each gf:
    if tryRemoveFile(gf):
      result &= formatter("REMOVED", gf)
    else:
      result &= spaced(STRINGS_ASTERISK, parenthesize("UNREMOVABLE"), gf) & STRINGS_EOL

proc informGeneratedFiles*(ls: UbernimStatus): string =
  ls.files.generated.each gf:
    result &= spaced(STRINGS_ASTERISK, parenthesize("GENERATED"), gf) & STRINGS_EOL
