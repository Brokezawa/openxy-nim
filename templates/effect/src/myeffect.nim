## A small, complete OP-XY send effect written in Nim.
##
## The buffer stores the previous wet sample for a short feedback trail; the
## transport can freeze the trail when playback stops.

import openxy

type
  State* = object
    level: Q31
    phase*: uint32


proc initialize*(state: var State) {.raises: [].} =
  state = State()


proc process*(state: var State; effectBlock: EffectBlock) {.raises: [].} =
  let drive = effectBlock.parameters[0]
  let level = effectBlock.parameters[1]
  var feedback = Q31(0)
  if effectBlock.buffer.len > 0:
    feedback = effectBlock.buffer[0]
  let moving = effectBlock.transport.isEmpty or effectBlock.transport.playing
  for index in 0 ..< effectBlock.left.len:
    let dry = effectBlock.left[index]
    let wet = dry * drive + feedback
    effectBlock.left[index] = wet * level
    effectBlock.right[index] = (effectBlock.right[index] * drive + feedback) * level
    if effectBlock.buffer.len > 0:
      effectBlock.buffer[index mod effectBlock.buffer.len] = wet
    if moving:
      inc state.phase, effectBlock.transport.ticks96
  if effectBlock.buffer.len > 0:
    state.level = effectBlock.buffer[0]


openxyValidate(mkEffect, State)
