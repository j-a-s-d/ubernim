# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim REQUIRES":

  test "test REQUIRES require":
    #
    writeFile("required.unim", lined(".mkdir dummy"))
    writeFile("require.unim", lined(".require required.unim"))
    let eng = makeTestEngine()
    let rr = eng.run("require.unim", newStringSeq())
    check(dirsExist("dummy"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeDirs("dummy")
    removeFiles("require.unim", "required.unim", "require.nim", "required.nim")

  test "test REQUIRES requirable":
    #
    writeFile("required.unim", lined(".requirable no"))
    writeFile("require.unim", lined(".require required.unim"))
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(required.unim:1) errors.CANT_BE_REQUIRED"))
    let rr = eng.run("require.unim", newStringSeq())
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("require.unim", "required.unim", "require.nim", "required.nim")
