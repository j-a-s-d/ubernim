# ubernim by Javier Santo Domingo (j-a-s-d@coderesearchlabs.com)

import
  unittest,
  os,
  xam,
  .. / src / ubernim / [constants, engine]

use strutils,strip

template makeTestEngine*(): UbernimEngine = newUbernimEngine(newSemanticVersion("1.0.0"), "testing")

{.warning[UnusedImport]:off.}
