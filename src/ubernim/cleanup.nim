# ubernim / CLEANUP #
#-------------------#

import
  xam,
  status

use os,tryRemoveFile
use os,removeDir
use os,dirExists

proc removeGeneratedFiles*(status: UbernimStatus, formatter: DoubleArgsProc[string, string, string]): string =
  status.files.generated.each gf:
    if tryRemoveFile(gf):
      result &= formatter("REMOVED FILE", gf)
    else:
      result &= spaced(STRINGS_ASTERISK, parenthesize("UNREMOVABLE FILE"), gf) & STRINGS_EOL
  status.files.generatedDirectories.each gd:
    if dirExists(gd):
      removeDir(gd)
      if not dirExists(gd):
        result &= formatter("REMOVED DIRECTORY", gd)
      else:
        result &= spaced(STRINGS_ASTERISK, parenthesize("UNREMOVABLE DIRECTORY"), gd) & STRINGS_EOL

proc informGeneratedFiles*(status: UbernimStatus): string =
  status.files.generated.each gf:
    result &= spaced(STRINGS_ASTERISK, parenthesize("GENERATED FILE"), gf) & STRINGS_EOL
  status.files.generatedDirectories.each gd:
    result &= spaced(STRINGS_ASTERISK, parenthesize("GENERATED DIRECTORY"), gd) & STRINGS_EOL
