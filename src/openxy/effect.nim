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
    wordData: ptr UncheckedArray[Q31]
    count: uint32

  EffectBlock* = object
    left*: MutableAudioView[Q31]
    right*: MutableAudioView[Q31]
    parameters*: AudioView[Q31]
    buffer*: Buffer
    transport*: Transport

func initBuffer*(data: ptr UncheckedArray[Q31]; count: uint32): Buffer =
  ## Borrow SDK-owned effect storage; an absent buffer is empty.
  if data == nil or count == 0:
    Buffer()
  else:
    Buffer(wordData: data, count: count)

func initBuffer*(data: var openArray[Q31]): Buffer =
  ## Borrow a caller-owned delay buffer for host tests.
  if data.len == 0:
    Buffer()
  else:
    Buffer(wordData: cast[ptr UncheckedArray[Q31]](addr data[0]),
      count: uint32(data.len))

func isEmpty*(buffer: Buffer): bool {.inline.} =
  buffer.count == 0 or buffer.wordData == nil

func len*(buffer: Buffer): int {.inline.} = int(buffer.count)

func `[]`*(buffer: Buffer; index: int): Q31 {.inline.} =
  if index < 0 or index >= int(buffer.count) or buffer.wordData == nil:
    Q31(0)
  else:
    buffer.wordData[index]

func `[]=`*(buffer: Buffer; index: int; value: Q31) {.inline.} =
  if index >= 0 and index < int(buffer.count) and buffer.wordData != nil:
    buffer.wordData[index] = value

template toOpenArray*(buffer: Buffer): untyped =
  toOpenArray(buffer.wordData, 0, int(buffer.count) - 1)

func division*(control: Q31): uint32 {.inline.} =
  let value = int32(control)
  if value < 0: 0'u32 else: uint32(value) shr 28

func divisionSixteenths*(control: Q31): uint32 {.inline.} =
  DivisionSixteenths[division(control)]
