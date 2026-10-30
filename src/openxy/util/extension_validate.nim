## Early validation for extension folders before the SDK sees them.

import std/[json, os, strutils]

import openxy/paths
import openxy/util/project

type
  ExtensionSpec* = object
    root*: string
    id*: string
    name*: string
    description*: string
    note*: string
    claims*: seq[string]
    actions*: seq[string]

const
  MaxExtensionIdLength* = 32
  NameLimit = 32
  DescriptionLimit = 140
  NoteLimit = 100
  ExtensionReservedNames = [
    "runtime", "collection", "stock", "extensions", "sdk", "kit", "local",
  ]

proc fail(message: string) {.noreturn.} =
  raise newException(ValueError, message)

proc require(condition: bool; message: string) =
  if not condition:
    fail(message)

proc requireString(node: JsonNode; field: string): string =
  require(node.hasKey(field), "extension.json is missing " & field)
  require(node[field].kind == JString, field & " must be a string")
  node[field].getStr

func validExtensionId(value: string): bool =
  if value.len == 0 or value.len > MaxExtensionIdLength or value[0] notin {'a'..'z'}:
    return false
  for character in value:
    if character notin {'a'..'z', '0'..'9', '_'}:
      return false
  if value in ExtensionReservedNames or isLanguageKeyword(value):
    return false
  true

func extensionIdError(value: string): string =
  if value.len == 0: return "extension id is empty"
  if value.len > MaxExtensionIdLength:
    return "extension id must be at most 32 characters"
  if value[0] notin {'a'..'z'}:
    return "extension id must start with a lowercase letter"
  for character in value:
    if character notin {'a'..'z', '0'..'9', '_'}:
      return "extension id may contain only lowercase letters, digits and underscores"
  if value in ExtensionReservedNames or isLanguageKeyword(value):
    return "extension id is reserved by the SDK or a language keyword: " & value
  ""

proc stringArray(node: JsonNode; field: string): seq[string] =
  require(node.hasKey(field), "extension.json is missing " & field)
  let values = node[field]
  require(values.kind == JArray, field & " must be an array")
  for value in values:
    require(value.kind == JString, field & " entries must be strings")
    let text = value.getStr
    require(text.len > 0, field & " entries must not be empty")
    require(text notin result, field & " entries must be unique: " & text)
    result.add text

proc registry(): tuple[claims, actions: JsonNode] =
  let path = openxyRoot / "open-xy" / "profiles" / "extensions.json"
  require(fileExists(path), "pinned SDK extension registry not found: " & path)
  let data = parseJson(readFile(path))
  require(data.kind == JObject and data.hasKey("schema") and
    data["schema"].kind == JInt and data["schema"].getInt == 3,
    "unsupported SDK extension registry schema")
  require(data.hasKey("claims") and data["claims"].kind == JObject,
    "SDK extension registry needs claims")
  require(data.hasKey("actions") and data["actions"].kind == JObject,
    "SDK extension registry needs actions")
  let claims = data["claims"]
  let actions = data["actions"]
  require(claims.len <= 32 and actions.len <= 32,
    "the SDK registry allows at most 32 claims and 32 actions")
  for name, claim in claims:
    require(claim.kind == JObject and claim.hasKey("label") and claim.hasKey("key"),
      "invalid SDK claim: " & name)
    require(claim["label"].kind == JString and claim["label"].getStr.len in 1 .. 40,
      "invalid SDK claim label: " & name)
    require(claim["key"].kind == JInt and claim["key"].getInt in 0 .. 255,
      "invalid SDK claim key: " & name)
  for name, action in actions:
    require(action.kind == JObject, "invalid SDK action: " & name)
    if action.hasKey("requires"):
      require(action["requires"].kind == JString and
        claims.hasKey(action["requires"].getStr),
        "SDK action " & name & " requires an unknown claim")
  (claims, actions)

proc loadExtension*(root: string): ExtensionSpec =
  ## Read and validate `extension.json` against the pinned SDK registry.
  let path = root / "extension.json"
  require(fileExists(path), "extension.json not found in " & root)
  var data: JsonNode
  try:
    data = parseJson(readFile(path))
  except JsonParsingError as error:
    fail("invalid extension.json: " & error.msg)
  require(data.kind == JObject, "extension.json must be an object")
  for key, _ in data:
    require(key in ["id", "name", "description", "note", "claims", "actions"],
      "unexpected extension.json field: " & key)
  let id = requireString(data, "id")
  require(validExtensionId(id), extensionIdError(id))
  let name = requireString(data, "name")
  require(name.len in 1 .. NameLimit, "extension name is 1..32 characters")
  let description = requireString(data, "description")
  require(description.len in 1 .. DescriptionLimit,
    "extension description is 1..140 characters")
  var note = ""
  if data.hasKey("note"):
    note = requireString(data, "note")
    require(note.len in 1 .. NoteLimit, "extension note is 1..100 characters")
  let claims = stringArray(data, "claims")
  let actions = stringArray(data, "actions")
  let known = registry()
  for claim in claims:
    require(known.claims.hasKey(claim), "unknown extension claim: " & claim)
  for action in actions:
    require(known.actions.hasKey(action), "unknown extension action: " & action)
    let entry = known.actions[action]
    if entry.hasKey("requires"):
      require(entry["requires"].getStr in claims,
        "extension action " & action & " requires the " & entry["requires"].getStr & " claim")
  require(actions.len == 0 or claims.len > 0,
    "extension actions are granted through a claim")
  ExtensionSpec(root: root, id: id, name: name, description: description,
    note: note, claims: claims, actions: actions)

func stripComment(line: string): string =
  let comment = line.find('#')
  if comment >= 0: line[0 ..< comment] else: line

func hasToken(line, token: string): bool =
  var start = 0
  while true:
    let position = line.find(token, start)
    if position < 0:
      return false
    let before = if position == 0: '\0' else: line[position - 1]
    let after = if position + token.len >= line.len: '\0' else: line[position + token.len]
    if before notin {'A'..'Z', 'a'..'z', '0'..'9', '_'} and
        after notin {'A'..'Z', 'a'..'z', '0'..'9', '_'}:
      return true
    start = position + token.len
  false

proc checkExtensionSource*(root: string) =
  ## Reject unsafe or platform-specific tokens in the authored Nim source.
  let sourceRoot = root / "src"
  require(dirExists(sourceRoot), "extension source folder not found: " & sourceRoot)
  for path in walkDirRec(sourceRoot):
    if not path.endsWith(".nim"):
      continue
    var lineNumber = 0
    for line in readFile(path).splitLines:
      inc lineNumber
      let code = stripComment(line)
      for token in ["cast", "ptr", "addr", "unsafeAddr", "UncheckedArray",
                    "importc", "importcpp", "emit", "asm"]:
        if code.hasToken(token):
          fail(path & ":" & $lineNumber & " uses unsafe token " & token)
      if code.contains("when defined("):
        fail(path & ":" & $lineNumber & " uses conditional compilation")
