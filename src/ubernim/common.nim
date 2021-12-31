# ubernim / COMMON #
#------------------#

import
  rodster, xam

template err*(msg: string) =
  die ansiRed("* [ERROR] ") & msg

template done*(errorlevel: int) =
  quit(ansiGreen("* DONE " & parenthesize($errorlevel)), errorlevel)

proc showHelp*(app: RodsterApplication) =
  let kvm = app.getKvm()
  echo kvm["version"]
  echo ""
  echo "usage"
  echo "-----"
  echo ""
  echo "  ubernim <input.file> <output.file>"
  echo "    -- example: ubernim myfile.unim myfile.nim"
  echo ""
