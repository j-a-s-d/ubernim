# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  unittest,
  os,
  xam,
  .. / src / ubernim / engine

use strutils,strip

suite "test ubernim":

  template makeTestEngine(): UbernimEngine = newUbernimEngine("test_ubernim", newSemanticVersion("1.0.0"), "testing")

  test "test assigned":
    #
    check(assigned(makeTestEngine()))

  test "test inexistent file":
    #
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "the file 'blah.unim' does not exist"))
    let rr = eng.run("blah.unim", newStringSeq())
    check(fileExists("blah.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("blah.nim")

  test "test existent file with a preprod command":
    #
    writeFile("noop_file.preprod", ".$ NOOP")
    let eng = makeTestEngine()
    let rr = eng.run("noop_file.preprod", newStringSeq())
    check(fileExists("noop_file.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("noop_file.nim")
    removeFile("noop_file.preprod")

  test "test UNIMPRJS unnamed project":
    #
    writeFile("id_less.unimp", ".project")
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(id_less.unimp:1) arguments expected: 1"))
    let rr = eng.run("id_less.unimp", newStringSeq())
    check(not fileExists("id_less.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("id_less.unimp")

  test "test UNIMPRJS empty project":
    #
    writeFile("empty_project.unimp", lined(".project TestProject", ".end"))
    let eng = makeTestEngine()
    let rr = eng.run("empty_project.unimp", newStringSeq())
    check(not fileExists("empty_project.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("empty_project.unimp")

  test "test UNIMPRJS simple project":
    #
    writeFile("simple_project.unimp", lined(".project TestProject", ".main simple.unim", ".end"))
    writeFile("simple.unim", ".$ NOOP")
    let eng = makeTestEngine()
    let rr = eng.run("simple_project.unimp", newStringSeq())
    check(not fileExists("simple.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("simple.unim")
    removeFile("simple_project.unimp")

  test "test UNIMCMDS uncomplete unim:version":
    #
    writeFile("version_less.unim", ".unim:version")
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(version_less.unim:1) arguments expected: 1"))
    let rr = eng.run("version_less.unim", newStringSeq())
    check(fileExists("version_less.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("version_less.unim")
    removeFile("version_less.nim")

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
      removeFile("bad_version.unim")
      removeFile("bad_version.nim")
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
    removeFile("old_version.unim")
    removeFile("old_version.nim")

  test "test UNIMCMDS valid unim:version":
    #
    writeFile("valid_version.unim", ".unim:version 0.1.0")
    let eng = makeTestEngine()
    let rr = eng.run("valid_version.unim", newStringSeq())
    check(fileExists("valid_version.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("valid_version.unim")
    removeFile("valid_version.nim")

  test "test UNIMCMDS informed unim:cleanup":
    #
    writeFile("informed_cleanup.unim", lined(".unim:cleanup informed", ".nimc:project informed_cleanup.nim"))
    let eng = makeTestEngine()
    let rr = eng.run("informed_cleanup.unim", newStringSeq())
    check(fileExists("informed_cleanup.nim"))
    check(fileExists("informed_cleanup"))
    check(rr.compilationErrorlevel == 0)
    check(strip(rr.cleanupReport) == "* (GENERATED) informed_cleanup.nim")
    removeFile("informed_cleanup.unim")
    removeFile("informed_cleanup.nim")
    removeFile("informed_cleanup")

  test "test UNIMCMDS performed unim:cleanup":
    #
    writeFile("performed_cleanup.unim", lined(".unim:cleanup performed", ".nimc:project performed_cleanup.nim"))
    let eng = makeTestEngine()
    let rr = eng.run("performed_cleanup.unim", newStringSeq())
    check(not fileExists("performed_cleanup.nim"))
    check(fileExists("performed_cleanup"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "(REMOVED) performed_cleanup.nim")
    removeFile("performed_cleanup.unim")
    removeFile("performed_cleanup")

  test "test UNIMCMDS disabled unim:flush":
    #
    writeFile("no_flush.unim", ".unim:flush no")
    let eng = makeTestEngine()
    let rr = eng.run("no_flush.unim", newStringSeq())
    check(not fileExists("no_flush.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("no_flush.unim")

  test "test UNIMCMDS unim:mode":
    #
    writeFile("strict_mode.unim", lined(".unim:mode strict", "echo 1234"))
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(strict_mode.unim:2) errors.STRICT_MODE"))
    let rr = eng.run("strict_mode.unim", newStringSeq())
    check(fileExists("strict_mode.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFile("strict_mode.unim")
    removeFile("strict_mode.nim")
