## Nim authoring surface for OP-XY firmware extensions.
##
## Callbacks are synchronous and serial on the controller path. `Context`,
## `Control`, `Actions`, and a `Note` array are borrowed for the duration of
## the callback; copy values that must outlive it. The SDK has no userdata
## pointer, so an extension keeps its mutable state at module scope.

import openxy/private/raw/opxy/extension_raw as rawExtension

type
  Time* = distinct uint64
  Track* = distinct uint32
  ProjectId* = distinct uint32
  PatternId* = distinct uint32
  Ticks* = distinct uint32

  RecordingContext* = object
    project*: ProjectId
    pattern*: PatternId
    track*: Track
    length*: Ticks
    scale*: uint32
    quantization*: uint32
    editable*: bool
    recordable*: bool

  Context* = object
    recording*: RecordingContext
    playing*: bool

  Note* = object
    position*: int32
    length*: Ticks
    pitch*: uint8
    velocity*: uint8

  LiveNote* = object
    track*: Track
    pitch*: uint32
    velocity*: uint32
    position*: int32
    collisionRadius*: uint32

  NoteOff* = object
    track*: Track
    pitch*: uint32

  Tick* = object
    deltaQ8*: uint32
    discontinuity*: bool

  Control* = object
    key*: uint32
    pressed*: bool
    accepted*: bool
    unmodified*: bool
    time*: Time

  InsertNotesImpl* = proc (raw: pointer; context: Context; track: uint32;
    notes: ptr UncheckedArray[Note]; count: uint32): uint32 {.cdecl, raises: [].}
  ReplaceNotesImpl* = proc (raw: pointer; context: Context; track: uint32;
    notes: ptr UncheckedArray[Note]; count: uint32): uint32 {.cdecl, raises: [].}
  NotifyImpl* = proc (raw: pointer; text: cstring): bool {.cdecl, raises: [].}

  Actions* = object
    raw: pointer
    insertNotesImpl: InsertNotesImpl
    replaceNotesImpl: ReplaceNotesImpl
    notifyImpl: NotifyImpl

  OnContext* = proc (context: Context) {.cdecl, raises: [].}
  OnRecordableNoteOn* = proc (context: Context; note: LiveNote) {.cdecl, raises: [].}
  OnSelectedNoteOff* = proc (context: Context; note: NoteOff) {.cdecl, raises: [].}
  OnRecordingTick* = proc (context: Context; tick: Tick) {.cdecl, raises: [].}
  OnInputActivity* = proc () {.cdecl, raises: [].}
  OnQueuedControl* = proc (context: Context; control: Control;
    actions: Actions) {.cdecl, raises: [].}

  Hooks* = object
    context*: OnContext
    recordableNoteOn*: OnRecordableNoteOn
    selectedNoteOff*: OnSelectedNoteOff
    recordingTick*: OnRecordingTick
    inputActivity*: OnInputActivity
    queuedControl*: OnQueuedControl

  DoubleTap* = object
    pressedAt: Time
    releasedAt: Time
    down: bool
    clean: bool
    pending: bool
    second: bool

const
  RecordKey* = 50'u32
  MaxActionNotes* = 120
  DoubleTapInterval = Time(350_000)
  DoubleTapHoldLimit = Time(250_000)

when sizeof(Time) != 8:
  {.error: "Time must be 8 bytes".}
when sizeof(Track) != 4:
  {.error: "Track must be 4 bytes".}
when sizeof(Note) != 12:
  {.error: "Note must be 12 bytes".}
when offsetOf(Note, position) != 0:
  {.error: "Note.position must be at offset 0".}
when offsetOf(Note, length) != 4:
  {.error: "Note.length must be at offset 4".}
when offsetOf(Note, pitch) != 8:
  {.error: "Note.pitch must be at offset 8".}
when offsetOf(Note, velocity) != 9:
  {.error: "Note.velocity must be at offset 9".}

func `==`*(a, b: Time): bool {.inline.} = uint64(a) == uint64(b)
func `<`*(a, b: Time): bool {.inline.} = uint64(a) < uint64(b)
func `<=`*(a, b: Time): bool {.inline.} = uint64(a) <= uint64(b)
func `-`*(a, b: Time): Time {.inline.} = Time(uint64(a) - uint64(b))

func `==`*(a, b: Track): bool {.inline.} = uint32(a) == uint32(b)
func `==`*(a, b: ProjectId): bool {.inline.} = uint32(a) == uint32(b)
func `==`*(a, b: PatternId): bool {.inline.} = uint32(a) == uint32(b)
func `==`*(a, b: Ticks): bool {.inline.} = uint32(a) == uint32(b)

func initHooks*(): Hooks {.inline.} = Hooks()

func withContext*(hooks: Hooks; callback: OnContext): Hooks {.inline.} =
  result = hooks
  result.context = callback

func withRecordableNoteOn*(hooks: Hooks; callback: OnRecordableNoteOn): Hooks {.inline.} =
  result = hooks
  result.recordableNoteOn = callback

func withSelectedNoteOff*(hooks: Hooks; callback: OnSelectedNoteOff): Hooks {.inline.} =
  result = hooks
  result.selectedNoteOff = callback

func withRecordingTick*(hooks: Hooks; callback: OnRecordingTick): Hooks {.inline.} =
  result = hooks
  result.recordingTick = callback

func withInputActivity*(hooks: Hooks; callback: OnInputActivity): Hooks {.inline.} =
  result = hooks
  result.inputActivity = callback

func withQueuedControl*(hooks: Hooks; callback: OnQueuedControl): Hooks {.inline.} =
  result = hooks
  result.queuedControl = callback

func initActions*(raw: pointer; insertNotesImpl: InsertNotesImpl;
                  replaceNotesImpl: ReplaceNotesImpl;
                  notifyImpl: NotifyImpl): Actions {.inline.} =
  ## Low-level constructor used by the generated adapter and the testkit.
  ## Prefer the `insertNotes`, `replaceNotes`, and `notify` methods.
  Actions(raw: raw, insertNotesImpl: insertNotesImpl,
    replaceNotesImpl: replaceNotesImpl, notifyImpl: notifyImpl)

proc rawInsertNotes(raw: pointer; context: Context; track: uint32;
                    notes: ptr UncheckedArray[Note]; count: uint32): uint32
    {.cdecl, raises: [].} =
  let table = cast[ptr rawExtension.Actions](raw)
  var value = rawExtension.Context(
    recording: rawExtension.RecordingContext(
      project: uint32(context.recording.project),
      pattern: uint32(context.recording.pattern),
      track: uint32(context.recording.track),
      length: uint32(context.recording.length),
      scale: context.recording.scale,
      quantization: context.recording.quantization,
      editable: context.recording.editable,
      recordable: context.recording.recordable),
    playing: context.playing)
  table.insert_notes(value, track, cast[ptr rawExtension.Note](notes), count)

proc rawReplaceNotes(raw: pointer; context: Context; track: uint32;
                     notes: ptr UncheckedArray[Note]; count: uint32): uint32
    {.cdecl, raises: [].} =
  let table = cast[ptr rawExtension.Actions](raw)
  var value = rawExtension.Context(
    recording: rawExtension.RecordingContext(
      project: uint32(context.recording.project),
      pattern: uint32(context.recording.pattern),
      track: uint32(context.recording.track),
      length: uint32(context.recording.length),
      scale: context.recording.scale,
      quantization: context.recording.quantization,
      editable: context.recording.editable,
      recordable: context.recording.recordable),
    playing: context.playing)
  table.replace_notes(value, track, cast[ptr rawExtension.Note](notes), count)

proc rawNotify(raw: pointer; text: cstring): bool {.cdecl, raises: [].} =
  cast[ptr rawExtension.Actions](raw).notify(text)
  true

func actionsFromRaw*(raw: pointer): Actions {.inline.} =
  ## Build the borrowed action table passed to a `queuedControl` callback.
  initActions(raw, rawInsertNotes, rawReplaceNotes, rawNotify)

proc insertNotes*(actions: Actions; context: Context; track: Track;
                  notes: openArray[Note]): uint32 {.raises: [].} =
  ## Insert notes beside the track's existing pattern notes. Returns the
  ## inserted prefix length; `0` means refused or nothing written.
  if notes.len == 0 or notes.len > MaxActionNotes or uint32(track) >= 8:
    return 0
  if actions.insertNotesImpl == nil:
    return 0
  actions.insertNotesImpl(actions.raw, context, uint32(track),
    cast[ptr UncheckedArray[Note]](addr notes[0]), uint32(notes.len))

proc replaceNotes*(actions: Actions; context: Context; track: Track;
                   notes: openArray[Note]): uint32 {.raises: [].} =
  ## Replace the track's pattern notes. Returns the inserted prefix length;
  ## `0` means refused or nothing written.
  if notes.len == 0 or notes.len > MaxActionNotes or uint32(track) >= 8:
    return 0
  if actions.replaceNotesImpl == nil:
    return 0
  actions.replaceNotesImpl(actions.raw, context, uint32(track),
    cast[ptr UncheckedArray[Note]](addr notes[0]), uint32(notes.len))

proc notify*(actions: Actions; text: string): bool {.raises: [].} =
  ## Request a short popup. Returns false when the text is outside 1..31
  ## characters or the action is unavailable. The SDK may still refuse the
  ## popup for permissions or a duplicate request in the same callback.
  if text.len < 1 or text.len > 31 or actions.notifyImpl == nil:
    return false
  actions.notifyImpl(actions.raw, text.cstring)

func cancel*(tap: var DoubleTap) {.raises: [].} =
  ## Cancel the current gesture. Keeps `down` so a held key is not treated as
  ## a fresh press by the next event.
  tap.clean = false
  tap.pending = false
  tap.second = false

func press*(tap: var DoubleTap; time: Time; unmodified: bool): bool {.raises: [].} =
  ## Start a tap. Returns true for the first clean tap of a pair, so the
  ## caller can anchor a history snapshot before the second tap completes.
  if tap.down:
    tap.cancel()
    return false
  tap.second = tap.pending and (time - tap.releasedAt) <= DoubleTapInterval
  tap.pending = false
  tap.pressedAt = time
  tap.down = true
  tap.clean = unmodified
  tap.clean and not tap.second

func release*(tap: var DoubleTap; time: Time): bool {.raises: [].} =
  ## Complete a tap. Returns true when this release completes a double tap.
  if not tap.down:
    tap.cancel()
    return false
  tap.down = false
  if not tap.clean or (time - tap.pressedAt) > DoubleTapHoldLimit:
    tap.cancel()
    return false
  let capture = tap.second
  tap.second = false
  tap.pending = not capture
  tap.releasedAt = time
  capture
