# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

include common

suite "test ubernim TARGETED":

  test "test TARGETED unknown target":
    #
    writeFile("unknown_target.unim", lined(".targeted pascal", ".targeted:end"))
    let eng = makeTestEngine()
    eng.setErrorHandler((msg: string) => check(msg == "(unknown_target.unim:1) errors.BAD_TARGET"))
    let rr = eng.run("unknown_target.unim", newStringSeq())
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("unknown_target.unim", "unknown_target.nim")

  test "test TARGETED empty block":
    #
    writeFile("empty_block.unim", lined(".targeted cc", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("empty_block.unim", newStringSeq())
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("empty_block.unim", "empty_block.nim")

  test "test TARGETED pass params":
    #
    writeFile("pass_params.unim", lined(".nimc:project pass_params", ".nimc:switch --hints:off", ".nimc:switch --warnings:off", ".nimc:target cpp", ".targeted cpp", ".targeted:pass", "  to:compiler \"\"", "  to:local \"\"", "  to:linker \"\"", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("pass_params.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("pass_params.unim", "pass_params.nim", "pass_params")

  test "test TARGETED compile files":
    #
    writeFile("extra.c", "int some_var = 123;")
    writeFile("compile_files.unim", lined(".nimc:project compile_files", ".nimc:switch --hints:off", ".nimc:switch --warnings:off", ".nimc:target cpp", ".targeted cpp", ".targeted:compile", "  extra.c", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("compile_files.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("compile_files.unim", "compile_files.nim", "compile_files", "extra.c")

  test "test TARGETED emit code":
    #
    writeFile("emit_code.unim", lined(".nimc:project emit_code", ".nimc:switch --hints:off", ".nimc:switch --warnings:off", ".targeted cc", ".targeted:emit", "  int some_x = 0;", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("emit_code.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("emit_code.unim", "emit_code.nim", "emit_code")
