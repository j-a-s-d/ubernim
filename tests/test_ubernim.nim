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
    check(strip(rr.cleanupReport) == "* (GENERATED) informed_cleanup.nim")
    removeFiles("informed_cleanup.unim", "informed_cleanup.nim", "informed_cleanup")

  test "test UNIMCMDS performed unim:cleanup":
    #
    writeFile("performed_cleanup.unim", lined(".unim:cleanup performed", ".nimc:project performed_cleanup.nim"))
    let eng = makeTestEngine()
    let rr = eng.run("performed_cleanup.unim", newStringSeq())
    check(not fileExists("performed_cleanup.nim"))
    check(fileExists("performed_cleanup"))
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport == "(REMOVED) performed_cleanup.nim")
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

  test "test SHELLCMD exec":
    #
    writeFile("exec.unim", lined(".exec echo foo > bar.txt"))
    let eng = makeTestEngine()
    let rr = eng.run("exec.unim", newStringSeq())
    check(fileExists("bar.txt"))
    check(rr.compilationErrorlevel != 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("exec.unim", "exec.nim", "bar.txt")

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
    writeFile("pass_params.unim", lined(".nimc:project pass_params", ".nimc:target cpp", ".targeted cpp", ".targeted:pass", "  to:compiler \"\"", "  to:local \"\"", "  to:linker \"\"", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("pass_params.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("pass_params.unim", "pass_params.nim", "pass_params")

  test "test TARGETED compile files":
    #
    writeFile("extra.c", "int some_var = 123;")
    writeFile("compile_files.unim", lined(".nimc:project compile_files", ".nimc:target cpp", ".targeted cpp", ".targeted:compile", "  extra.c", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("compile_files.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("compile_files.unim", "compile_files.nim", "compile_files", "extra.c")

  test "test TARGETED emit code":
    #
    writeFile("emit_code.unim", lined(".nimc:project emit_code", ".targeted cc", ".targeted:emit", "  int some_x = 0;", ".targeted:end"))
    let eng = makeTestEngine()
    let rr = eng.run("emit_code.unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    removeFiles("emit_code.unim", "emit_code.nim", "emit_code")

  template testLanguageCommand(name, input, output: string, debug: bool = false) =
    writeFile(name & ".unim", lined(".nimc:project " & name, input))
    let eng = makeTestEngine()
    let rr = eng.run(name & ".unim", newStringSeq())
    check(rr.compilationErrorlevel == 0)
    check(rr.cleanupReport.isEmpty())
    let sig = "static: echo \"" & name & ".nim testing\""
    let expected = if output.isEmpty(): sig else: lined(sig, output)
    check(strip(readFile(name & ".nim")) == expected)
    if debug:
      echo "---"
      echo strip(readFile(name & ".nim"))
      echo "---"
      echo expected
      echo "---"
    else:
      removeFiles(name & ".unim", name & ".nim", name)

  test "test LANGUAGE push/pop":
    #
    testLanguageCommand("push_pop", lined(
      ".push inline",
      "proc hey() = discard",
      ".pop",
      "hey()"
    ), lined(
      STRINGS_EOL,
      "{.push inline.}",
      "proc hey() = discard",
      "{.pop.}",
      STRINGS_EMPTY,
      "hey()"
    ))

  test "test LANGUAGE exports":
    #
    testLanguageCommand("exports", lined(
      "import os, strtabs",
      ".exports",
      "  os",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".exports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os, strtabs",
      "export os",
      "export strtabs",
      "export os",
      STRINGS_EMPTY,
      "export os"
    ))

  test "test LANGUAGE exporting always":
    #
    testLanguageCommand("exporting_always", lined(
      "import os, strtabs",
      ".exporting always",
      ".exports",
      "  os",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".exports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os, strtabs",
      "export os",
      "export strtabs",
      "export os",
      STRINGS_EMPTY,
      "export os"
    ))

  test "test LANGUAGE exporting once":
    #
    testLanguageCommand("exporting_once", lined(
      "import os, strtabs",
      ".exporting once",
      ".exports",
      "  os",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".exports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os, strtabs",
      "export os",
      "export strtabs"
    ))

  test "test LANGUAGE imports":
    #
    testLanguageCommand("imports", lined(
      ".imports",
      "  os",
      "  strutils.split",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".imports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os",
      "from strutils import split",
      "import strtabs",
      "import os",
      STRINGS_EMPTY,
      "import os",
    ))

  test "test LANGUAGE importing always":
    #
    testLanguageCommand("importing_always", lined(
      ".importing always",
      ".imports",
      "  os",
      "  strutils.split",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".imports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os",
      "from strutils import split",
      "import strtabs",
      "import os",
      STRINGS_EMPTY,
      "import os",
    ))

  test "test LANGUAGE importing once":
    #
    testLanguageCommand("importing_once", lined(
      ".importing once",
      ".imports",
      "  os",
      "  strutils.split",
      "  strtabs",
      "  os",
      ".end",
      STRINGS_EMPTY,
      ".imports",
      "  os",
      ".end"
    ), STRINGS_EOL & lined(
      "import os",
      "from strutils import split",
      "import strtabs"
    ))

  test "test LANGUAGE note nothing":
    #
    testLanguageCommand("note_nothing", lined(
      ".note",
      ".end"
    ), STRINGS_EMPTY)

  test "test LANGUAGE note line":
    #
    testLanguageCommand("note_line", lined(
      ".note",
      "  This will be a comment in the source code.",
      ".end"
    ), STRINGS_EOL & lined(
      "#   This will be a comment in the source code.",
    ))

  test "test LANGUAGE note lines":
    #
    testLanguageCommand("note_lines", lined(
      ".note",
      "  You can insert a note into the emitted source code.",
      "  Just like this.",
      ".end"
    ), STRINGS_EOL & lined(
      "#   You can insert a note into the emitted source code.",
      "#   Just like this."
    ))

  test "test more commands of the LANGUAGE feature":
    #
    echo "TODO"
