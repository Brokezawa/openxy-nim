## Typed audio views passed to machine callbacks.

import openxy/q31
import openxy/units

const
  BlockFrames* = 64
  ParameterSlots* = 8
  PitchSlots* = 64
  PageControls* = 4
  MonoOutputWords* = BlockFrames
  StereoOutputWords* = BlockFrames * 2

type
  Output* = openArray[Q31]
  Parameters* = openArray[Q31]
  Pitch* = openArray[PhaseIncrement]
  Channel* = openArray[Q31]
  SampleOutput* = openArray[Q31]

  Transport* = object
    bpmX10*: uint32
    ticks96*: uint32
    playing*: bool

  AudioView*[T] = object
    data: ptr UncheckedArray[T]
    length: int

  MutableAudioView*[T] = object
    data: ptr UncheckedArray[T]
    length: int

func initAudioView*[T](data: ptr UncheckedArray[T]; length: int): AudioView[T] {.inline.} =
  AudioView[T](data: data, length: length)

func initMutableAudioView*[T](data: ptr UncheckedArray[T];
                              length: int): MutableAudioView[T] {.inline.} =
  MutableAudioView[T](data: data, length: length)

func len*[T](view: AudioView[T]): int {.inline.} = view.length
func len*[T](view: MutableAudioView[T]): int {.inline.} = view.length
func isEmpty*[T](view: AudioView[T]): bool {.inline.} = view.length == 0
func isEmpty*[T](view: MutableAudioView[T]): bool {.inline.} = view.length == 0
func isEmpty*(transport: Transport): bool {.inline.} = transport.bpmX10 == 0

func `[]`*[T](view: AudioView[T]; index: int): T {.inline.} = view.data[index]
func `[]`*[T](view: MutableAudioView[T]; index: int): T {.inline.} = view.data[index]
func `[]=`*[T](view: MutableAudioView[T]; index: int; value: T) {.inline.} =
  view.data[index] = value

template toOpenArray*[T](view: AudioView[T]): untyped =
  toOpenArray(view.data, 0, view.length - 1)

template toOpenArray*[T](view: MutableAudioView[T]): untyped =
  toOpenArray(view.data, 0, view.length - 1)

func toConst*[T](view: MutableAudioView[T]): AudioView[T] {.inline.} =
  AudioView[T](data: view.data, length: view.length)

iterator items*[T](view: AudioView[T]): T =
  for index in 0 ..< view.length:
    yield view.data[index]

iterator items*[T](view: MutableAudioView[T]): T =
  for index in 0 ..< view.length:
    yield view.data[index]

iterator mitems*[T](view: MutableAudioView[T]): var T =
  for index in 0 ..< view.length:
    yield view.data[index]

template samples*[T](view: openArray[T]; fixedLength: static[int]; body: untyped) =
  ## Iterate a view whose length the SDK contract fixes, with a host check.
  doAssert view.len == fixedLength, "audio view length does not match the SDK contract"
  for sample {.inject.} in view:
    body
