## Template project paths and machine-name rules.

import std/[os, strutils]

import openxy/kind

const
  MaxMachineIdLength* = 15

  StockMachineNames* = [
    "sampler", "drum", "drumline", "organ", "epiano", "prism", "hardsync",
    "dissolve", "axis", "wavetable", "simple", "midi", "multisampler",
    "delay", "reverb", "chorus", "phaser", "dist", "lofi",
  ]

  NimKeywords = [
    "addr", "and", "as", "asm", "bind", "block", "break", "case", "cast",
    "concept", "const", "continue", "converter", "defer", "discard", "distinct",
    "div", "do", "elif", "else", "end", "enum", "except", "export", "finally",
    "for", "from", "func", "generic", "if", "import", "in", "include",
    "interface", "is", "isnot", "iterator", "let", "macro", "method", "mixin",
    "mod", "nil", "not", "notin", "object", "of", "or", "out", "proc", "ptr",
    "raise", "ref", "return", "shl", "shr", "static", "template", "try",
    "tuple", "type", "using", "var", "when", "while", "xor", "yield",
  ]

  CxxKeywords = [
    "alignas", "alignof", "and", "and_eq", "asm", "auto", "bitand", "bitor",
    "bool", "break", "case", "catch", "char", "char16_t", "char32_t", "class",
    "compl", "const", "constexpr", "const_cast", "continue", "decltype",
    "default", "delete", "do", "double", "dynamic_cast", "else", "enum",
    "explicit", "export", "extern", "false", "float", "for", "friend", "goto",
    "if", "inline", "int", "long", "mutable", "namespace", "new", "noexcept",
    "not", "not_eq", "nullptr", "operator", "or", "or_eq", "private",
    "protected", "public", "register", "reinterpret_cast", "return", "short",
    "signed", "sizeof", "static", "static_assert", "static_cast", "struct",
    "switch", "template", "this", "thread_local", "throw", "true", "try",
    "typedef", "typeid", "typename", "union", "unsigned", "using", "virtual",
    "void", "volatile", "wchar_t", "while", "xor", "xor_eq", "opxy", "std",
  ]

  ReservedPrefixes = ["extensions", "sdk", "kit", "stock", "local"]

type
  Project* = object
    root*: string
    id*: string
    source*: string
    kind*: MachineKind
    buildRoot*: string
    stockOs*: string
    layout*: string

func resolvePath*(root, path: string): string =
  if path.isAbsolute: path else: root / path

func sourceModule*(project: Project): string =
  splitFile(project.source).name

func machineDir*(project: Project): string =
  project.buildRoot / $project.kind / project.id

func sourceDir*(project: Project): string =
  project.source.parentDir

func isLanguageKeyword*(id: string): bool =
  id in NimKeywords or id in CxxKeywords

func isValidMachineId*(id: string): bool =
  if id.len == 0 or id.len > MaxMachineIdLength:
    return false
  if id[0] notin {'a'..'z'}:
    return false
  for character in id:
    if character notin {'a'..'z', '0'..'9', '_'}:
      return false
  if id in StockMachineNames or id in NimKeywords or id in CxxKeywords:
    return false
  for prefix in ReservedPrefixes:
    if id == prefix or id.startsWith(prefix & "_"):
      return false
  true

func machineIdError*(id: string): string =
  if id.len == 0: return "machineId is empty"
  if id.len > MaxMachineIdLength:
    return "machineId must be at most 15 characters"
  if id[0] notin {'a'..'z'}:
    return "machineId must start with a lowercase letter"
  for character in id:
    if character notin {'a'..'z', '0'..'9', '_'}:
      return "machineId may contain only lowercase letters, digits and underscores"
  if id in StockMachineNames:
    return "machineId is reserved by the stock OP-XY catalog: " & id
  if id in NimKeywords or id in CxxKeywords:
    return "machineId is a language keyword or SDK namespace: " & id
  for prefix in ReservedPrefixes:
    if id == prefix or id.startsWith(prefix & "_"):
      return "machineId uses a reserved symbol prefix: " & prefix
  ""

proc loadProject*(machineId, machineSource, buildRoot: string;
                  stockOs = ""; layout = ""): Project =
  ## Resolve the paths declared by a template's `config.nims`.
  result = Project(
    root: getCurrentDir(),
    id: machineId,
    source: resolvePath(getCurrentDir(), machineSource),
    buildRoot: resolvePath(getCurrentDir(), if buildRoot.len == 0: "build" else: buildRoot),
    stockOs: (if stockOs.len == 0: "" else: resolvePath(getCurrentDir(), stockOs)),
    layout: layout,
  )
  let error = machineIdError(machineId)
  if error.len != 0:
    raise newException(ValueError, error)
  if not fileExists(result.source):
    raise newException(IOError, "machine source not found: " & result.source)
  let moduleName = sourceModule(result)
  if moduleName != machineId:
    raise newException(ValueError,
      "machine source file name must equal machineId: expected " & machineId & ".nim, got " &
      moduleName & ".nim")

proc nimLibDir*(): string =
  ## Locate the active compiler's standard library directory.
  when defined(nimscript):
    parentDir(getCurrentCompilerExe()).parentDir / "lib"
  else:
    let compiler = findExe("nim")
    if compiler.len == 0:
      raise newException(IOError, "nim compiler not found in PATH")
    parentDir(compiler).parentDir / "lib"

proc nimbasePath*(): string =
  nimLibDir() / "nimbase.h"

proc sdkIncludeDir*(sdkRoot: string): string =
  sdkRoot / "sdk" / "include"

proc sdkScript*(sdkRoot: string): string =
  sdkRoot / "sdk.py"

proc pythonExecutable*(): string =
  when defined(nimscript):
    let uv = findExe("uv")
    if uv.len != 0:
      let (output, code) = gorgeEx(quoteShell(uv) & " python find 3.12")
      if code == 0 and output.strip.len != 0:
        return output.strip
  for candidate in ["python3", "python"]:
    let found = findExe(candidate)
    if found.len != 0:
      return found
  ""
