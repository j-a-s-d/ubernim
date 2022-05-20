# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim FSACCESS":

  test "test FSACCESS write":
    #
    writeFile("write.unim", lined(".write bar.txt foo"))
    let eng = makeTestEngine()
    let rr = eng.run("write.unim", newStringSeq())
    check(fileExists("bar.txt"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("write.unim", "write.nim", "bar.txt")

  test "test FSACCESS append":
    #
    writeFile("append.unim", lined(".append foo.txt o.0"))
    let eng = makeTestEngine()
    let rr = eng.run("append.unim", newStringSeq())
    check(fileExists("foo.txt"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("append.unim", "append.nim", "foo.txt")

  test "test FSACCESS copy":
    #
    writeFile("copy.unim", lined(".copy copy.unim file.txt"))
    let eng = makeTestEngine()
    let rr = eng.run("copy.unim", newStringSeq())
    check(fileExists("file.txt"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("copy.unim", "copy.nim", "file.txt")

  test "test FSACCESS move":
    #
    writeFile("move.unim", lined(".move move.unim file.txt"))
    let eng = makeTestEngine()
    let rr = eng.run("move.unim", newStringSeq())
    check(fileExists("file.txt"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("move.nim", "file.txt")

  test "test FSACCESS remove":
    #
    writeFile("remove.unim", lined(".remove remove.unim"))
    let eng = makeTestEngine()
    let rr = eng.run("remove.unim", newStringSeq())
    check(not fileExists("remove.unim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("remove.nim")

  test "test FSACCESS mkdir":
    #
    writeFile("mkdir.unim", lined(".mkdir sample"))
    let eng = makeTestEngine()
    let rr = eng.run("mkdir.unim", newStringSeq())
    check(dirExists("sample"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("mkdir.unim", "mkdir.nim")
    removeDirs("sample")

  test "test FSACCESS cpdir":
    #
    writeFile("cpdir.unim", lined(".mkdir sample", ".cpdir sample testing"))
    let eng = makeTestEngine()
    let rr = eng.run("cpdir.unim", newStringSeq())
    check(dirsExist("sample", "testing"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("cpdir.unim", "cpdir.nim")
    removeDirs("sample", "testing")

  test "test FSACCESS rmdir":
    #
    createdir("sample")
    writeFile("rmdir.unim", lined(".rmdir sample"))
    let eng = makeTestEngine()
    let rr = eng.run("rmdir.unim", newStringSeq())
    check(not dirsExist("sample"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("rmdir.unim", "rmdir.nim")
    removeDirs("sample")

  test "test FSACCESS chdir":
    #
    writeFile("chdir.unim", lined(".chdir .."))
    let eng = makeTestEngine()
    let rr = eng.run("chdir.unim", newStringSeq())
    check(dirsExist("../tests"))
    check(filesExist("../chdir.nim"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("chdir.unim", "../chdir.nim")
