## Raw OP-XY extension bindings generated from `opxy/extension.hpp`.
##
## Henka maps the SDK's `u32` and `u8` aliases to C `int` and its reference
## parameters to by-value callbacks. The checked-in normalization patch keeps
## the fields exact, passes `Context` by pointer, and removes the C++ method
## surface that the ergonomic layer does not use.

type
  RecordingContext* {.completeStruct, importcpp: "opxy::extensions::RecordingContext",
    header: "opxy/extension.hpp", bycopy.} = object
    project*, pattern*, track*, length*, scale*, quantization*: uint32
    editable*, recordable*: bool

  Context* {.completeStruct, importcpp: "opxy::extensions::Context",
    header: "opxy/extension.hpp", bycopy.} = object
    recording*: RecordingContext
    playing*: bool

  Note* {.completeStruct, importcpp: "opxy::extensions::Note",
    header: "opxy/extension.hpp", bycopy.} = object
    position*: int32
    length*: uint32
    pitch*, velocity*: uint8

  LiveNote* {.completeStruct, importcpp: "opxy::extensions::LiveNote",
    header: "opxy/extension.hpp", bycopy.} = object
    track*, pitch*, velocity*: uint32
    position*: int32
    collision_radius*: uint32

  NoteOff* {.completeStruct, importcpp: "opxy::extensions::NoteOff",
    header: "opxy/extension.hpp", bycopy.} = object
    track*, pitch*: uint32

  Tick* {.completeStruct, importcpp: "opxy::extensions::Tick",
    header: "opxy/extension.hpp", bycopy.} = object
    delta_q8*: uint32
    discontinuity*: bool

  Time* = uint64

  Control* {.completeStruct, importcpp: "opxy::extensions::Control",
    header: "opxy/extension.hpp", bycopy.} = object
    key*: uint32
    pressed*, accepted*, unmodified*: bool
    time*: Time

  Actions* {.completeStruct, importcpp: "opxy::extensions::Actions",
    header: "opxy/extension.hpp", bycopy.} = object
    insert_notes*: proc (context: Context; track: uint32; notes: ptr Note;
      count: uint32): uint32 {.cdecl, raises: [].}
    notify*: proc (text: cstring) {.cdecl, raises: [].}
    replace_notes*: proc (context: Context; track: uint32; notes: ptr Note;
      count: uint32): uint32 {.cdecl, raises: [].}

  OnContext* = proc (context: ptr Context) {.cdecl, raises: [].}
  OnRecordableNoteOn* = proc (context: ptr Context; note: ptr LiveNote) {.cdecl, raises: [].}
  OnSelectedNoteOff* = proc (context: ptr Context; note: ptr NoteOff) {.cdecl, raises: [].}
  OnRecordingTick* = proc (context: ptr Context; tick: ptr Tick) {.cdecl, raises: [].}
  OnInputActivity* = proc () {.cdecl, raises: [].}
  OnQueuedControl* = proc (context: ptr Context; control: ptr Control;
    actions: ptr Actions) {.cdecl, raises: [].}

  Hooks* {.completeStruct, importcpp: "opxy::extensions::Hooks",
    header: "opxy/extension.hpp", bycopy.} = object
    context*: OnContext
    recordable_note_on*: OnRecordableNoteOn
    selected_note_off*: OnSelectedNoteOff
    recording_tick*: OnRecordingTick
    input_activity*: OnInputActivity
    queued_control*: OnQueuedControl

const record*: uint32 = 50
