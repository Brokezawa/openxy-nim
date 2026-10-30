import std/[assertions, strutils]

import openxy

proc onContext(context: Context) {.cdecl, raises: [].} = discard
proc onRecordable(context: Context; note: LiveNote) {.cdecl, raises: [].} = discard
proc onNoteOff(context: Context; note: NoteOff) {.cdecl, raises: [].} = discard
proc onTick(context: Context; tick: Tick) {.cdecl, raises: [].} = discard
proc onActivity() {.cdecl, raises: [].} = discard
proc onQueued(context: Context; control: Control; actions: Actions)
    {.cdecl, raises: [].} = discard

const hooks = initHooks()
  .withContext(onContext)
  .withRecordableNoteOn(onRecordable)
  .withSelectedNoteOff(onNoteOff)
  .withRecordingTick(onTick)
  .withInputActivity(onActivity)
  .withQueuedControl(onQueued)

block hooks_builder:
  doAssert hooks.context != nil
  doAssert hooks.recordableNoteOn != nil
  doAssert hooks.selectedNoteOff != nil
  doAssert hooks.recordingTick != nil
  doAssert hooks.inputActivity != nil
  doAssert hooks.queuedControl != nil
  doAssert initHooks().context == nil
  doAssert initHooks().queuedControl == nil

var calls: seq[string]
var capturedNotes: seq[Note]

proc fakeInsert(raw: pointer; context: Context; track: uint32;
                notes: ptr UncheckedArray[Note]; count: uint32): uint32
    {.cdecl, raises: [].} =
  calls.add("insert")
  for index in 0 ..< int(count):
    capturedNotes.add(notes[index])
  count

proc fakeReplace(raw: pointer; context: Context; track: uint32;
                 notes: ptr UncheckedArray[Note]; count: uint32): uint32
    {.cdecl, raises: [].} =
  calls.add("replace")
  count

proc fakeNotify(raw: pointer; text: cstring): bool {.cdecl, raises: [].} =
  calls.add("notify:" & $text)
  true

let actions = initActions(nil, fakeInsert, fakeReplace, fakeNotify)
let context = Context(recording: RecordingContext(track: Track(2)))
var notes = [Note(position: 0, length: Ticks(120), pitch: 60, velocity: 100)]

block action_methods:
  doAssert actions.insertNotes(context, Track(2), notes) == 1
  doAssert calls == @["insert"]
  doAssert capturedNotes.len == 1
  doAssert capturedNotes[0].pitch == 60

  calls.setLen(0)
  doAssert actions.replaceNotes(context, Track(3), notes) == 1
  doAssert calls == @["replace"]

  calls.setLen(0)
  doAssert actions.insertNotes(context, Track(8), notes) == 0
  doAssert actions.insertNotes(context, Track(2), newSeq[Note]()) == 0
  doAssert actions.insertNotes(context, Track(2), newSeq[Note](121)) == 0
  doAssert calls.len == 0

  calls.setLen(0)
  doAssert actions.notify("hello")
  doAssert calls == @["notify:hello"]
  doAssert not actions.notify("")
  doAssert not actions.notify(repeat('x', 32))
  doAssert calls.len == 1
