# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim INIT":

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
    removeFiles("blah.nim")

  test "test existent file with a preprod command":
    #
    writeFile("noop_file.preprod", ".$ NOOP")
    let eng = makeTestEngine()
    let rr = eng.run("noop_file.preprod", newStringSeq())
    check(fileExists("noop_file.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("noop_file.nim", "noop_file.preprod")
