# ubernim / CONSTANTS #
#---------------------#

const
  UNIM_PROJECT_EXTENSION* = ".unimp"
  UNIM_FILE_KEY* = "UNIM_FILE"
  UNIM_FLUSH_KEY* = "UNIM_FLUSH"
  FLAG_YES* = "yes" # default
  FLAG_NO* = "no"
  UNIM_MODE_KEY* = "UNIM_MODE"
  MODE_FREE* = "free" # default
  MODE_STRICT* = "strict"
  UNIM_CLEANUP_KEY* = "UNIM_CLEANUP"
  VALUE_IGNORED* = "ignored" # default
  VALUE_INFORMED* = "informed"
  VALUE_PERFORMED* = "performed"
  FREQ_IMPORTING_KEY* = "FREQ_IMPORTING"
  FREQ_EXPORTING_KEY* = "FREQ_EXPORTING"
  FREQUENCY_ALWAYS* = "always" # default
  FREQUENCY_ONCE* = "once"
  NIMC_DEFINES_KEY* = "NIMC_DEFINES"
  NIMC_SWITCHES_KEY* = "NIMC_SWITCHES"
  NIMC_CFGFILE_KEY* = "NIMC_CFGFILE"
  NIMC_PROJECT_KEY* = "NIMC_PROJECT"
  NIMC_TARGET_KEY* = "NIMC_TARGET"
  KEY_DIVISION* = "DIVISION"
  KEY_SUBDIVISION* = "SUBDIVISION"
  DIVISIONS_TARGETED* = "TARGETED"
  SUBDIVISIONS_TARGETED_PASS* = "TARGETED_PASS"
  SUBDIVISIONS_TARGETED_COMPILE* = "TARGETED_COMPILE"
  SUBDIVISIONS_TARGETED_LINK* = "TARGETED_LINK"
  SUBDIVISIONS_TARGETED_EMIT* = "TARGETED_EMIT"
  DIVISIONS_PROJECT* = "PROJECT"
  TO_COMPILER* = "to:compiler"
  TO_LOCAL* = "to:local"
  TO_LINKER* = "to:linker"
  PASS_COMPILER* = "passC"
  PASS_LOCAL* = "localPassC"
  PASS_LINK* = "passL"
  TARGET_CC* = "cc"
  TARGET_CPP* = "cpp"
  TARGET_OBJC* = "objc"
  TARGET_JS* = "js"
  NIMC_TARGETS* = [TARGET_CC, TARGET_CPP, TARGET_OBJC, TARGET_JS]
  NIMC_INVOKATION* = "nim"
  NIMC_DEFINE* = "--define:"
