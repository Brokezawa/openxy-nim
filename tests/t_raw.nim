import std/assertions

import openxy/private/raw/opxy

block raw_surface:
  var view: SampleView
  doAssert sample_at(view, 0, 0) == 0
  var frame: Frame
  frame.nodes[0].x = 4
  frame.header[0][0] = 'A'
  doAssert frame.nodes[0].x == 4
  doAssert frame.header[0][0] == 'A'
  var tracker: NoteTracker
  let events = tracker.update(Input())
  doAssert not events.hold_started
  var buffer: Buffer
  doAssert buffer.count == 0
  var transport: Transport
  doAssert transport.bpm_x10 == 0
  var analysis: SampleAnalysis
  doAssert analysis.word_count == 0
