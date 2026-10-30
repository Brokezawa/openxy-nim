## A small, complete OP-XY send effect written in Nim.
##
## The buffer stores the previous wet sample for a short feedback trail; the
## transport can freeze the trail when playback stops.

import openxy

type
  Control* = enum
    drive, level, dry

  State* = object
    phase*: uint32


proc initialize*(state: var State) {.raises: [].} =
  state = State()


proc process*(state: var State; effectBlock: EffectBlock) {.raises: [].} =
  let driveAmount = effectBlock.parameters[drive]
  let levelAmount = effectBlock.parameters[level]
  let hasBuffer = not effectBlock.buffer.isEmpty
  let bufferLength = effectBlock.buffer.len
  var feedback = Q31(0)
  if hasBuffer:
    feedback = effectBlock.buffer[0]
  let moving = effectBlock.transport.isEmpty or effectBlock.transport.playing
  for index in 0 ..< effectBlock.left.len:
    let dry = effectBlock.left[index]
    let wet = dry * driveAmount + feedback
    effectBlock.left[index] = wet * levelAmount
    effectBlock.right[index] = (effectBlock.right[index] * driveAmount + feedback) * levelAmount
    if hasBuffer:
      effectBlock.buffer[index mod bufferLength] = wet
    if moving:
      inc state.phase, effectBlock.transport.ticks96


openxyValidate(mkEffect, State)
