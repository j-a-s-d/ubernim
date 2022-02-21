# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  unittest,
  os,
  xam,
  .. / src / ubernim / engine

suite "test ubernim":

  template makeTestEngine(): UbernimEngine = newUbernimEngine("test_ubernim", newSemanticVersion("1.0.0"), "signature")

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
