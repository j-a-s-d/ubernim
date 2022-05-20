# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim UNIMCMDS":

  test "test UNIMCMDS uncomplete unim:version":
    #
    writeFile("version_less.unim", ".unim:version")
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(version_less.unim:1) arguments expected: 1"))
    let rr = eng.run("version_less.unim", newStringSeq())
    check(fileExists("version_less.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("version_less.unim", "version_less.nim")

  test "test UNIMCMDS invalid unim:version":
    #
    proc testVersion(version: string) =
      writeFile("bad_version.unim", ".unim:version " & version)
      let eng = makeTestEngine()
      eng.setErrorHandler((msg: string) => check(msg == "(bad_version.unim:1) errors.BAD_VERSION"))
      let rr = eng.run("bad_version.unim", newStringSeq())
      check(fileExists("bad_version.nim"))
      check(rr.compilationErrorlevel != 0)
      check(rr.cleanupReport.isEmpty())
      removeFiles("bad_version.unim", "bad_version.nim")
    testVersion("blah")
    testVersion("blah.foo.bar")
    testVersion("1.2")
    testVersion("1.2.lala")

  test "test UNIMCMDS old unim:version":
    #
    writeFile("old_version.unim", ".unim:version 1.0.0")
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(old_version.unim:1) errors.OLD_VERSION"))
    let rr = eng.run("old_version.unim", newStringSeq())
    check(fileExists("old_version.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("old_version.unim", "old_version.nim")

  test "test UNIMCMDS valid unim:version":
    #
    writeFile("valid_version.unim", ".unim:version 0.1.0")
    let eng = makeTestEngine()
    let rr = eng.run("valid_version.unim", newStringSeq())
    check(fileExists("valid_version.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("valid_version.unim", "valid_version.nim")

  test "test UNIMCMDS informed unim:cleanup":
    #
    writeFile("informed_cleanup.unim", lined(".unim:cleanup informed", ".nimc:project informed_cleanup.nim"))
    let eng = makeTestEngine()
    let rr = eng.run("informed_cleanup.unim", newStringSeq())
    check(fileExists("informed_cleanup.nim"))
    check(fileExists("informed_cleanup"))
    check(rr.compilationErrorlevel == 0)
    check(strip(rr.cleanupReport) == "(messages.GENERATED_FILE) informed_cleanup.nim")
    removeFiles("informed_cleanup.unim", "informed_cleanup.nim", "informed_cleanup")

  test "test UNIMCMDS performed unim:cleanup":
    #
    writeFile("performed_cleanup.unim", lined(".unim:cleanup performed", ".nimc:project performed_cleanup.nim"))
    let eng = makeTestEngine()
    let rr = eng.run("performed_cleanup.unim", newStringSeq())
    check(not fileExists("performed_cleanup.nim"))
    check(fileExists("performed_cleanup"))
    check(rr.compilationErrorlevel == 0)
    check(strip(rr.cleanupReport) == "(messages.REMOVED_FILE) performed_cleanup.nim")
    removeFiles("performed_cleanup.unim", "performed_cleanup")

  test "test UNIMCMDS disabled unim:flush":
    #
    writeFile("no_flush.unim", ".unim:flush no")
    let eng = makeTestEngine()
    let rr = eng.run("no_flush.unim", newStringSeq())
    check(not fileExists("no_flush.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("no_flush.unim")

  test "test UNIMCMDS unim:mode":
    #
    writeFile("strict_mode.unim", lined(".unim:mode strict", "echo 1234"))
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(strict_mode.unim:2) errors.STRICT_MODE"))
    let rr = eng.run("strict_mode.unim", newStringSeq())
    check(fileExists("strict_mode.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("strict_mode.unim", "strict_mode.nim")

  test "test UNIMCMDS unim:destination":
    #
    writeFile("destination.unim", lined(".unim:destination src", ".unim:cleanup informed", ".nimc:project destination.nim", ".nimc:config destination.nim.cfg"))
    let eng = makeTestEngine()
    let rr = eng.run("destination.unim", newStringSeq())
    check(dirExists("src"))
    check(fileExists("src/destination.nim"))
    check(fileExists("src/destination.nim.cfg"))
    check(rr.compilationErrorlevel == 0)
    check(strip(rr.cleanupReport) == lined("(messages.GENERATED_FILE) src/destination.nim", "(messages.GENERATED_FILE) src/destination.nim.cfg", "(messages.GENERATED_DIRECTORY) src/"))
    removeFiles("destination.unim", "src/destination.nim", "src/destination.nim.cfg")
    removeDirs("src")
