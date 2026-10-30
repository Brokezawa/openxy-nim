## Generate the Nim wrapper and C++ adapter for an extension folder.

import std/[os, strutils]

import openxy/util/[extension_validate, fscompat, generator]

type
  HookKind* = enum
    hkContext
    hkRecordableNoteOn
    hkSelectedNoteOff
    hkRecordingTick
    hkInputActivity
    hkQueuedControl

  ExtensionPaths* = object
    root*: string
    id*: string
    source*: string
    buildRoot*: string
    sdkDir*: string
    nimDir*: string

func hookKey*(hook: HookKind): string =
  case hook
  of hkContext: "context"
  of hkRecordableNoteOn: "recordableNoteOn"
  of hkSelectedNoteOff: "selectedNoteOff"
  of hkRecordingTick: "recordingTick"
  of hkInputActivity: "inputActivity"
  of hkQueuedControl: "queuedControl"

func hookField*(hook: HookKind): string =
  case hook
  of hkContext: "context"
  of hkRecordableNoteOn: "recordableNoteOn"
  of hkSelectedNoteOff: "selectedNoteOff"
  of hkRecordingTick: "recordingTick"
  of hkInputActivity: "inputActivity"
  of hkQueuedControl: "queuedControl"

func hookExport*(hook: HookKind): string =
  case hook
  of hkContext: "openxyContext"
  of hkRecordableNoteOn: "openxyRecordableNoteOn"
  of hkSelectedNoteOff: "openxySelectedNoteOff"
  of hkRecordingTick: "openxyRecordingTick"
  of hkInputActivity: "openxyInputActivity"
  of hkQueuedControl: "openxyQueuedControl"

func hookAdapter*(hook: HookKind): string =
  case hook
  of hkContext: "openxy_context_cb"
  of hkRecordableNoteOn: "openxy_recordable_note_on_cb"
  of hkSelectedNoteOff: "openxy_selected_note_off_cb"
  of hkRecordingTick: "openxy_recording_tick_cb"
  of hkInputActivity: "openxy_input_activity_cb"
  of hkQueuedControl: "openxy_queued_control_cb"

func hookWith*(hook: HookKind): string =
  case hook
  of hkContext: "with_context"
  of hkRecordableNoteOn: "with_recordable_note_on"
  of hkSelectedNoteOff: "with_selected_note_off"
  of hkRecordingTick: "with_recording_tick"
  of hkInputActivity: "with_input_activity"
  of hkQueuedControl: "with_queued_control"

func parseHookKey*(key: string): HookKind =
  case key
  of "context": hkContext
  of "recordableNoteOn": hkRecordableNoteOn
  of "selectedNoteOff": hkSelectedNoteOff
  of "recordingTick": hkRecordingTick
  of "inputActivity": hkInputActivity
  of "queuedControl": hkQueuedControl
  else: raise newException(ValueError, "unknown extension hook: " & key)

func hookProbeSource*(moduleName: string): string =
  result = "import " & moduleName & "\n\n"
  for hook in HookKind:
    result.add "echo \"openxy-hook " & hookKey(hook) & " \", " &
      moduleName & ".hooks." & hookField(hook) & " != nil\n"

func parseHookSelection*(output: string): set[HookKind] =
  for line in output.splitLines:
    let marker = "openxy-hook "
    let position = line.find(marker)
    if position < 0:
      continue
    let parts = line[position + marker.len .. ^1].splitWhitespace()
    if parts.len >= 2 and parts[1] == "true":
      result.incl parseHookKey(parts[0])

func extensionPaths*(root, id, source, buildRoot: string): ExtensionPaths =
  let build = if buildRoot.isAbsolute: buildRoot else: root / buildRoot
  ExtensionPaths(
    root: root,
    id: id,
    source: if source.isAbsolute: source else: root / source,
    buildRoot: build,
    sdkDir: build / "extension" / id,
    nimDir: build / "extension" / "nim" / id,
  )

proc prepareExtension*(paths: ExtensionPaths): ExtensionSpec =
  result = loadExtension(paths.root)
  if result.id != paths.id:
    raise newException(ValueError,
      "extension.json id must equal extensionId: " & paths.id)
  let moduleName = splitFile(paths.source).name
  if moduleName != paths.id:
    raise newException(ValueError,
      "extension source file name must equal extensionId: expected " &
      paths.id & ".nim, got " & moduleName & ".nim")
  if not fileExists(paths.source):
    raise newException(IOError, "extension source not found: " & paths.source)
  checkExtensionSource(paths.root)
  ensureDir(paths.sdkDir)
  ensureDir(paths.nimDir)
  writeVendor(paths.nimDir)

proc writeMetadata*(paths: ExtensionPaths) =
  writeFile(paths.sdkDir / "extension.json",
    readFile(paths.root / "extension.json"))

proc writeWrapper*(paths: ExtensionPaths; selected: set[HookKind]) =
  let moduleName = splitFile(paths.source).name
  var text = "import openxy\n" &
    "import openxy/private/raw/opxy/extension_raw as rawExtension\n" &
    "import " & moduleName & "\n\n" &
    """
func toContext(value: rawExtension.Context): extension.Context =
  extension.Context(
    recording: extension.RecordingContext(
      project: extension.ProjectId(value.recording.project),
      pattern: extension.PatternId(value.recording.pattern),
      track: extension.Track(value.recording.track),
      length: extension.Ticks(value.recording.length),
      scale: value.recording.scale,
      quantization: value.recording.quantization,
      editable: value.recording.editable,
      recordable: value.recording.recordable),
    playing: value.playing)

func toControl(value: rawExtension.Control): extension.Control =
  extension.Control(key: value.key, pressed: value.pressed,
    accepted: value.accepted, unmodified: value.unmodified,
    time: extension.Time(value.time))

func toLiveNote(value: rawExtension.LiveNote): extension.LiveNote =
  extension.LiveNote(track: extension.Track(value.track), pitch: value.pitch,
    velocity: value.velocity, position: value.position,
    collisionRadius: value.collision_radius)

func toNoteOff(value: rawExtension.NoteOff): extension.NoteOff =
  extension.NoteOff(track: extension.Track(value.track), pitch: value.pitch)

func toTick(value: rawExtension.Tick): extension.Tick =
  extension.Tick(deltaQ8: value.delta_q8, discontinuity: value.discontinuity)

"""
  for hook in selected:
    case hook
    of hkContext:
      text.add "proc openxyContext(context: ptr rawExtension.Context) " &
        "{.exportcpp, raises: [].} =\n" &
        "  " & moduleName & ".hooks.context(toContext(context[]))\n\n"
    of hkRecordableNoteOn:
      text.add "proc openxyRecordableNoteOn(context: ptr rawExtension.Context; " &
        "note: ptr rawExtension.LiveNote) {.exportcpp, raises: [].} =\n" &
        "  " & moduleName & ".hooks.recordableNoteOn(toContext(context[]), " &
        "toLiveNote(note[]))\n\n"
    of hkSelectedNoteOff:
      text.add "proc openxySelectedNoteOff(context: ptr rawExtension.Context; " &
        "note: ptr rawExtension.NoteOff) {.exportcpp, raises: [].} =\n" &
        "  " & moduleName & ".hooks.selectedNoteOff(toContext(context[]), " &
        "toNoteOff(note[]))\n\n"
    of hkRecordingTick:
      text.add "proc openxyRecordingTick(context: ptr rawExtension.Context; " &
        "tick: ptr rawExtension.Tick) {.exportcpp, raises: [].} =\n" &
        "  " & moduleName & ".hooks.recordingTick(toContext(context[]), " &
        "toTick(tick[]))\n\n"
    of hkInputActivity:
      text.add "proc openxyInputActivity() {.exportcpp, raises: [].} =\n" &
        "  " & moduleName & ".hooks.inputActivity()\n\n"
    of hkQueuedControl:
      text.add "proc openxyQueuedControl(raw: pointer; " &
        "context: ptr rawExtension.Context; control: ptr rawExtension.Control) " &
        "{.exportcpp, raises: [].} =\n" &
        "  " & moduleName & ".hooks.queuedControl(toContext(context[]), " &
        "toControl(control[]), actionsFromRaw(raw))\n\n"
  writeFile(paths.nimDir / "wrapper.nim", text)

proc writeAdapter*(paths: ExtensionPaths; selected: set[HookKind]) =
  var text = "#include \"../nim/" & paths.id & "/extension.cpp\"\n" &
    "#include <opxy/extension.hpp>\n\n" &
    "namespace opxy { namespace extensions { namespace " & paths.id & " {\n\n"
  for hook in selected:
    case hook
    of hkContext:
      text.add "static void " & hookAdapter(hook) & "(const Context& context) {\n" &
        "  ::" & paths.id & "::" & hookExport(hook) &
        "(const_cast<Context*>(&context));\n}\n\n"
    of hkRecordableNoteOn:
      text.add "static void " & hookAdapter(hook) &
        "(const Context& context, const LiveNote& note) {\n" &
        "  ::" & paths.id & "::" & hookExport(hook) &
        "(const_cast<Context*>(&context), const_cast<LiveNote*>(&note));\n}\n\n"
    of hkSelectedNoteOff:
      text.add "static void " & hookAdapter(hook) &
        "(const Context& context, const NoteOff& note) {\n" &
        "  ::" & paths.id & "::" & hookExport(hook) &
        "(const_cast<Context*>(&context), const_cast<NoteOff*>(&note));\n}\n\n"
    of hkRecordingTick:
      text.add "static void " & hookAdapter(hook) &
        "(const Context& context, const Tick& tick) {\n" &
        "  ::" & paths.id & "::" & hookExport(hook) &
        "(const_cast<Context*>(&context), const_cast<Tick*>(&tick));\n}\n\n"
    of hkInputActivity:
      text.add "static void " & hookAdapter(hook) & "() {\n" &
        "  ::" & paths.id & "::" & hookExport(hook) & "();\n}\n\n"
    of hkQueuedControl:
      text.add "static void " & hookAdapter(hook) &
        "(const Context& context, const Control& control, const Actions& actions) {\n" &
        "  ::" & paths.id & "::" & hookExport(hook) &
        "((void*)&actions, const_cast<Context*>(&context), " &
        "const_cast<Control*>(&control));\n}\n\n"
  text.add "extern const Hooks hooks = Hooks()"
  for hook in selected:
    text.add "\n  ." & hookWith(hook) & "(" & hookAdapter(hook) & ")"
  text.add ";\n\n}}}\n"
  writeFile(paths.sdkDir / "extension.cpp", text)
