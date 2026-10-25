## Send-effect block and buffer views.

import openxy/audio
import openxy/q31
import openxy/units

const
  EffectStateBytes* = 476
  EffectBufferedStateBytes* = 472
  EffectStateAlignment* = 4
  EffectBufferBytes* = 524288
  DivisionSixteenths* = [2'u32, 3, 4, 6, 8, 12, 16, 32]

type
  Buffer* = object
    words*: ptr UncheckedArray[Q31]
    count*: uint32

  EffectBlock* = object
    left*: MutableAudioView[Q31]
    right*: MutableAudioView[Q31]
    parameters*: AudioView[Q31]
    buffer*: Buffer
    transport*: Transport

func isEmpty*(buffer: Buffer): bool {.inline.} =
  buffer.count == 0 or buffer.words == nil

func len*(buffer: Buffer): int {.inline.} = int(buffer.count)

func `[]`*(buffer: Buffer; index: int): Q31 {.inline.} = buffer.words[index]
func `[]=`*(buffer: Buffer; index: int; value: Q31) {.inline.} =
  buffer.words[index] = value

template toOpenArray*(buffer: Buffer): untyped =
  toOpenArray(buffer.words, 0, int(buffer.count) - 1)

func division*(control: Q31): uint32 {.inline.} =
  let value = int32(control)
  if value < 0: 0'u32 else: uint32(value) shr 28

func divisionSixteenths*(control: Q31): uint32 {.inline.} =
  DivisionSixteenths[division(control)]
