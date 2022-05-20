# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim UNIMPRJS":

  test "test UNIMPRJS unnamed project":
    #
    writeFile("id_less.unimp", ".project")
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(id_less.unimp:1) arguments expected: 1"))
    let rr = eng.run("id_less.unimp", newStringSeq())
    check(not fileExists("id_less.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("id_less.unimp")

  test "test UNIMPRJS empty project":
    #
    writeFile("empty_project.unimp", lined(".project TestProject", ".end"))
    let eng = makeTestEngine()
    let rr = eng.run("empty_project.unimp", newStringSeq())
    check(not fileExists("empty_project.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("empty_project.unimp")

  test "test UNIMPRJS simple project":
    #
    writeFile("simple_project.unimp", lined(".project TestProject", ".main simple.unim", ".end"))
    writeFile("simple.unim", ".$ NOOP")
    let eng = makeTestEngine()
    let rr = eng.run("simple_project.unimp", newStringSeq())
    check(not fileExists("simple.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("simple.unim", "simple_project.unimp")
