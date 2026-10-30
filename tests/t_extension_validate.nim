import std/[assertions, json, os, strutils]

import openxy/util/extension_validate

let scratch = getTempDir() / "openxy-extension-validate"
if dirExists(scratch):
  removeDir(scratch)
createDir(scratch)

proc writeExtension(folder: string; data: JsonNode) =
  let path = scratch / folder
  createDir(path)
  writeFile(path / "extension.json", $data)

proc base(): JsonNode =
  %*{
    "id": "mynotify",
    "name": "My Notify",
    "description": "A small extension that shows a popup on a Record double-tap.",
    "claims": ["record_double_tap"],
    "actions": ["notify"],
  }

block valid:
  writeExtension("valid", base())
  let spec = loadExtension(scratch / "valid")
  doAssert spec.id == "mynotify"
  doAssert spec.claims == @["record_double_tap"]
  doAssert spec.actions == @["notify"]

block optional_note:
  var data = base()
  data["note"] = %"Only fires while the recorder is idle."
  writeExtension("note", data)
  doAssert loadExtension(scratch / "note").note.len > 0

block invalid_id:
  var data = base()
  data["id"] = %"MyNotify"
  writeExtension("bad_id", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "bad_id")

block reserved_id:
  var data = base()
  data["id"] = %"runtime"
  writeExtension("reserved_id", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "reserved_id")

block unknown_claim:
  var data = base()
  data["claims"] = %["unknown_claim"]
  writeExtension("unknown_claim", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "unknown_claim")

block unknown_action:
  var data = base()
  data["actions"] = %["unknown_action"]
  writeExtension("unknown_action", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "unknown_action")

block action_without_claim:
  var data = base()
  data["claims"] = %[]
  writeExtension("no_claim", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "no_claim")

block duplicate_claim:
  var data = base()
  data["claims"] = %["record_double_tap", "record_double_tap"]
  writeExtension("duplicate_claim", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "duplicate_claim")

block long_description:
  var data = base()
  data["description"] = %repeat('x', 141)
  writeExtension("long_description", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "long_description")

block unknown_field:
  var data = base()
  data["extra"] = %true
  writeExtension("unknown_field", data)
  doAssertRaises ValueError:
    discard loadExtension(scratch / "unknown_field")

block source_boundary:
  let good = scratch / "good_source"
  createDir(good / "src")
  writeFile(good / "src" / "mynotify.nim", "import openxy\n")
  checkExtensionSource(good)

  let bad = scratch / "bad_source"
  createDir(bad / "src")
  writeFile(bad / "src" / "mynotify.nim", "let value = cast[int32](1)\n")
  doAssertRaises ValueError:
    checkExtensionSource(bad)

  let conditional = scratch / "conditional_source"
  createDir(conditional / "src")
  writeFile(conditional / "src" / "mynotify.nim",
    "when defined(windows):\n  discard\n")
  doAssertRaises ValueError:
    checkExtensionSource(conditional)

removeDir(scratch)
