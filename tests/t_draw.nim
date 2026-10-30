import std/assertions

import openxy

block layouts:
  doAssert sizeof(Point) == 8
  doAssert sizeof(Turn) == 8
  doAssert sizeof(Path[64]) == 516
  doAssert sizeof(Node) == 28
  doAssert sizeof(Text) == 36
  doAssert sizeof(Input) == 76
  doAssert sizeof(NoteTracker) == 16
  doAssert sizeof(Frame[2, 64, 2, 0, 16]) == 1156
  doAssert sizeof(Frame[0, 0, 2, 0, 16]) == 128

block input_offsets:
  doAssert offsetOf(Input, elapsed) == 16
  doAssert offsetOf(Input, track) == 20
  doAssert offsetOf(Input, noteSerial) == 24
  doAssert offsetOf(Input, reducedMotion) == 28
  doAssert offsetOf(Input, shown) == 32
  doAssert offsetOf(Input, slots) == 36
  doAssert offsetOf(Input, heldNotes) == 68
  doAssert offsetOf(Input, noteOffSerial) == 72

block note_tracker:
  var tracker = NoteTracker()
  var input = Input(track: 7, heldNotes: 1, noteOffSerial: 5)
  doAssert tracker.update(input) == NoteEvents()
  doAssert not tracker.update(input).holdStarted
  var released = Input(track: 7, heldNotes: 0, noteOffSerial: 6)
  let releaseEvents = tracker.update(released)
  doAssert releaseEvents.holdEnded
  doAssert releaseEvents.noteReleased
  let changedTrack = tracker.update(Input(track: 8, heldNotes: 2, noteOffSerial: 9))
  doAssert changedTrack == NoteEvents()
  tracker.reset()
  doAssert tracker.update(Input(track: 8, heldNotes: 2)).holdStarted == false

block held_note_limit:
  var tracker = NoteTracker()
  doAssert MaxHeldNotes == 128
  discard tracker.update(Input(track: 1, heldNotes: MaxHeldNotes + 1))
  doAssert tracker.initialized == 0

block frame_helpers:
  var frame: Frame[2, 64, 2, 0, 16]
  frame.paths[0].key = 1
  frame.paths[1].key = 1
  place(frame, 0, q10(10), q10(20), UnitQ10, 3, PaintStroke)
  place(frame, 1, q10(40), q10(50), UnitQ10, 4, PaintFillAndStroke)
  header(frame, 0, "abc")
  turn(frame, 1, rotation(900))
  doAssert valid(frame)
  hide(frame, 0)
  doAssert valid(frame)
  frame.nodes[0].shade = 16
  doAssert not valid(frame)

block text_helpers:
  var frame: Frame[0, 0, 1, 1, 2]
  place(frame, 0, q10(0), q10(0), UnitQ10, 0, PaintKeep)
  text(frame, 0, q10(0), q10(0), UnitQ10, "hello")
  doAssert valid(frame)
  doAssert frame.texts[0].chars[5] == '\0'
  doAssert terminated(frame.texts[0].chars)

block math:
  doAssert sine(0) == 0
  doAssert sine(900) == 1024
  doAssert sine(1800) == 0
  doAssert rotation(0).cos == 1024
  doAssert rotation(0).sin == 0

block page_header_layout:
  doAssert sizeof(PageHeader) == 20
  var state: PageHeader
  state.reset()
  var frame: Frame[2, 64, 10, 16, 16]
  frame.paths[0].key = 1
  frame.paths[1].key = 1
  place(frame, 0, q10(0), q10(0), UnitQ10, 0, PaintKeep)
  place(frame, 1, q10(0), q10(0), UnitQ10, 0, PaintKeep)
  type HeaderControl = enum one, two, three, four, five, six, seven, eight
  var titles: array[HeaderControl, string] = ["One", "Two", "Three", "Four",
    "Five", "Six", "Seven", "Eight"]
  var values: array[HeaderControl, HeaderText]
  for control in HeaderControl:
    headerAmount(values[control], Q31(0x40000000))
  pageHeader(state, Input(), frame, titles, values, 2)
  doAssert frame.nodes[2].x == 0
  doAssert frame.nodes[2].y == 0
  doAssert frame.nodes[2].scale == int32(Unit)
  doAssert frame.texts[0].chars[0] == 'o'
  doAssert frame.texts[8].chars[0] == 'f'
  doAssert frame.header[0][0] == '5'
  doAssert valid(frame)

block header_amount:
  var text: HeaderText
  headerAmount(text, Q31Max)
  doAssert text[0] == '1' and text[1] == '0' and text[2] == '0'
  doAssert text[3] == '\0'
  headerAmount(text, Q31(-1))
  doAssert text[0] == '0' and text[1] == '\0'
