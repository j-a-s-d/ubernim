# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim SWITCHES":

  test "test SWITCHES nimc:project":
    #
    writeFile("project.unim", lined(".nimc:project project.nim"))
    let eng = makeTestEngine()
    let rr = eng.run("project.unim", newStringSeq())
    check(fileExists("project.nim"))
    check(fileExists("project"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("project.unim", "project.nim", "project")

  test "test SWITCHES nimc:minimum":
    #
    writeFile("project.unim", lined(".nimc:project project.nim", ".nimc:minimum 1.0.6"))
    let eng = makeTestEngine()
    let rr = eng.run("project.unim", newStringSeq())
    check(fileExists("project.nim"))
    check(fileExists("project"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("project.unim", "project.nim", "project")

  test "test SWITCHES nimc:target":
    #
    writeFile("project.unim", lined(".nimc:project project.nim", ".nimc:target cpp"))
    let eng = makeTestEngine()
    let rr = eng.run("project.unim", newStringSeq())
    check(fileExists("project.nim"))
    check(fileExists("project"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("project.unim", "project.nim", "project")

  test "test SWITCHES nimc:define":
    #
    writeFile("project.unim", lined(".nimc:project project.nim", ".nimc:define release"))
    let eng = makeTestEngine()
    let rr = eng.run("project.unim", newStringSeq())
    check(fileExists("project.nim"))
    check(fileExists("project"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("project.unim", "project.nim", "project")

  test "test SWITCHES nimc:switch":
    #
    writeFile("project.unim", lined(".nimc:project project.nim", ".nimc:switch --threads:on"))
    let eng = makeTestEngine()
    let rr = eng.run("project.unim", newStringSeq())
    check(fileExists("project.nim"))
    check(fileExists("project"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("project.unim", "project.nim", "project")

  test "test SWITCHES nimc:config":
    #
    writeFile("project.unim", lined(".nimc:project project.nim", ".nimc:config project.nim.cfg"))
    let eng = makeTestEngine()
    let rr = eng.run("project.unim", newStringSeq())
    check(fileExists("project.nim.cfg"))
    check(fileExists("project.nim"))
    check(fileExists("project"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "")
    removeFiles("project.unim", "project.nim.cfg", "project.nim", "project")
