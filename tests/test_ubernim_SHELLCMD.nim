# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim SHELLCMD":

  test "test SHELLCMD exec":
    #
    writeFile("exec.unim", lined(".exec echo foo > bar.txt"))
    let eng = makeTestEngine()
    let rr = eng.run("exec.unim", newStringSeq())
    check(fileExists("bar.txt"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("exec.unim", "exec.nim", "bar.txt")
