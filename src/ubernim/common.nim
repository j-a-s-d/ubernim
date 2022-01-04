# ubernim / COMMON #
#------------------#

import
  rodster, xam

const
  APP_VERSION_KEY* = "version"
  APP_INPUT_KEY* = "input"
  APP_ERRORLEVEL_KEY* = "errorlevel"

template err*(msg: string) =
  die ansiRed("* [ERROR] ") & msg

template done*(errorlevel: int) =
  quit(ansiGreen("* DONE " & parenthesize($errorlevel)), errorlevel)

proc showHelp*(app: RodsterApplication) =
  let kvm = app.getKvm()
  echo kvm[APP_VERSION_KEY]
  echo ""
  echo "usage"
  echo "-----"
  echo ""
  echo "  ubernim <input.file> <output.file>"
  echo "    -- example: ubernim myfile.unim myfile.nim"
  echo ""
