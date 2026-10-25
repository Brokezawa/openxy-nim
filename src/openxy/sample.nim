## Sample-engine views and fixed-layout SDK mirrors.

import std/options

import openxy/audio
import openxy/q31
import openxy/units

type
  SampleView* = object
    data*: ptr UncheckedArray[int16]
    frames*: uint32
    rate*: uint32
    channels*: uint32
  SampleRegion* = object
    begin*: uint32
    `end`*: uint32
    level*: Q27
    reverse*: bool
    pitchCents*: Cents

  SampleAssignment* = object
    filename*: cstring
    filenameBytes*: uint32
    frames*: uint32
    rate*: uint32
    bpmX10*: uint32
    replacing*: bool
    previous*: PadSettings
    recorded*: bool

  DrumControl* = object
    knob*: uint32
    direction*: int32
    pressed*: bool
    shifted*: bool
    held*: bool

  DrumPanel* = object
    pitchCents*: Cents
    repeat*: bool
    reverse*: bool
    level*: uint32
    shifted*: array[2, array[16, char]]

  SampleAnalysis* = object
    sample*: SampleView
    words*: ptr UncheckedArray[uint32]
    wordCount*: uint32
    info*: uint32

  SampleBlock* = object
    output*: MutableAudioView[Q31]
    parameters*: AudioView[Q31]
    pitch*: AudioView[PhaseIncrement]
    transport*: Transport
    region*: SampleRegion
    analysis*: Option[ptr SampleAnalysis]
    settings*: PadSettings
    outputChannels*: uint32
    trackTranspose*: int32
    drumTranspose*: int32

  ## A sample machine using `sampleAnalysis` declares its own `Preparation`
  ## value type; the generator measures it and emits opaque SDK storage.
  PrepareStatus* = enum
    prepareFailed = 0
    prepareDone = 1
    prepareRunning = 2

func isEmpty*(view: SampleView): bool {.inline.} =
  view.frames == 0 or view.data == nil

func sampleAt*(view: SampleView; frame: uint32; channel: uint32 = 0): int16 {.noinline.} =
  if frame >= view.frames or view.data == nil or view.channels == 0:
    return 0
  let selected = if channel < view.channels: channel else: 0'u32
  # Keep the index in 32 bits: the device has no 64-bit multiply helper.
  let last = high(uint32) - selected
  if frame > last div view.channels:
    return 0
  let index = frame * view.channels + selected
  if index > uint32(high(int)):
    return 0
  view.data[int(index)]

func isEmpty*(region: SampleRegion): bool {.inline.} =
  region.begin >= region.`end`

func frames*(sampleBlock: SampleBlock): int {.inline.} =
  let channels = if sampleBlock.outputChannels == 2: 2 else: 1
  sampleBlock.output.len div channels

func mono*(sampleBlock: SampleBlock): bool {.inline.} =
  sampleBlock.outputChannels != 2
