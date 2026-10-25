# Package metadata only. Build tasks belong to machine templates and
# openxy/config.nims; there is no openxy CLI.
version       = "0.1.0"
author        = "Brokezawa"
description   = "Idiomatic Nim authoring SDK for the unofficial OP-XY machine SDK."
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]

requires "nim >= 2.2.12"

feature "regen":
  requires "https://github.com/RowDaBoat/henka"
