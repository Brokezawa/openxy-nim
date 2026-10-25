import std/assertions

import openxy
import openxy/testkit
import myeffect

block process_block:
  var state: State
  initialize(state)
  var left, right: array[BlockFrames, Q31]
  for index in 0 ..< BlockFrames:
    left[index] = Q31(0x10000000)
    right[index] = Q31(-0x08000000)
  var parameters = zeroParameters()
  parameters[0] = Q31(0x40000000)
  parameters[1] = Q31(0x7fffffff)
  var buffer: array[16, Q31]
  let effectBlock = EffectBlock(
    left: initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr left), left.len),
    right: initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr right), right.len),
    parameters: initAudioView(cast[ptr UncheckedArray[Q31]](addr parameters),
      parameters.len),
    buffer: Buffer(words: cast[ptr UncheckedArray[Q31]](addr buffer),
      count: uint32(buffer.len)),
    transport: Transport(bpmX10: 1200, ticks96: 3, playing: true),
  )
  process(state, effectBlock)
  doAssert left[0] != Q31(0), "the effect should produce audio"
  doAssert buffer[0] != Q31(0), "the effect should use its delay buffer"
  doAssert state.phase == 3'u32 * BlockFrames
  doAssert not effectBlock.buffer.isEmpty
  doAssert not effectBlock.transport.isEmpty

block empty_optional_inputs:
  var state: State
  initialize(state)
  var left, right: array[BlockFrames, Q31]
  var parameters = zeroParameters()
  let effectBlock = EffectBlock(
    left: initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr left), left.len),
    right: initMutableAudioView(cast[ptr UncheckedArray[Q31]](addr right), right.len),
    parameters: initAudioView(cast[ptr UncheckedArray[Q31]](addr parameters),
      parameters.len),
    buffer: Buffer(),
    transport: Transport(),
  )
  doAssert effectBlock.buffer.isEmpty
  doAssert effectBlock.transport.isEmpty
  process(state, effectBlock)
