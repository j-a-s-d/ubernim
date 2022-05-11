# ubernim / CLEANUP #
#-------------------#

import
  xam,
  constants, status

use os,tryRemoveFile
use os,removeDir
use os,dirExists

proc removeGeneratedFiles*(status: UbernimStatus, formatter: DoubleArgsProc[string, string, string]): string =
  status.files.generated.each gf:
    if tryRemoveFile(gf):
      result &= formatter(messages.REMOVED_FILE, gf)
    else:
      result &= formatter(messages.UNREMOVABLE_FILE, gf)
  status.files.generatedDirectories.each gd:
    if dirExists(gd):
      removeDir(gd)
      if not dirExists(gd):
        result &= formatter(messages.REMOVED_DIRECTORY, gd)
      else:
        result &= formatter(messages.UNREMOVABLE_DIRECTORY, gd)

proc informGeneratedFiles*(status: UbernimStatus, formatter: DoubleArgsProc[string, string, string]): string =
  status.files.generated.each gf:
    result &= formatter(messages.GENERATED_FILE, gf)
  status.files.generatedDirectories.each gd:
    result &= formatter(messages.GENERATED_DIRECTORY, gd)
