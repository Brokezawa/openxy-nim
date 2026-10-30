## Sample-engine views and fixed-layout SDK mirrors.

import std/options

import openxy/audio
import openxy/q31
import openxy/units

type
  SampleView* = object
    data: ptr UncheckedArray[int16]
    frameCount: uint32
    sampleRate: uint32
    channelCount: uint32
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

  WordView* = object
    data: ptr UncheckedArray[uint32]
    count: int

  SampleAnalysis* = object
    sampleData: SampleView
    wordData: ptr uint32
    count: uint32
    extra: uint32

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

func initSampleView*(pcm: openArray[int16]; rate, channels: uint32): SampleView =
  ## Borrow a PCM array for the lifetime of the view.
  if pcm.len == 0 or channels == 0:
    return SampleView()
  SampleView(
    data: cast[ptr UncheckedArray[int16]](addr pcm[0]),
    frameCount: uint32(pcm.len div int(channels)),
    sampleRate: rate,
    channelCount: channels,
  )

func initWordView*(data: ptr uint32; count: uint32): WordView =
  ## Borrow SDK-owned analysis storage.
  if data == nil or count == 0:
    return WordView()
  WordView(data: cast[ptr UncheckedArray[uint32]](data), count: int(count))

func initWordView*(data: var openArray[uint32]): WordView =
  ## Borrow caller-owned analysis storage for host tests.
  if data.len == 0:
    WordView()
  else:
    WordView(data: cast[ptr UncheckedArray[uint32]](addr data[0]),
      count: data.len)

func initSampleAnalysis*(sample: SampleView; words: WordView;
                         info: uint32 = 0): SampleAnalysis =
  SampleAnalysis(
    sampleData: sample,
    wordData: (if words.data == nil or words.count == 0: nil
               else: cast[ptr uint32](words.data)),
    count: uint32(words.count),
    extra: info,
  )

func frames*(view: SampleView): uint32 {.inline.} = view.frameCount
func rate*(view: SampleView): uint32 {.inline.} = view.sampleRate
func channels*(view: SampleView): uint32 {.inline.} = view.channelCount

func isEmpty*(view: SampleView): bool {.inline.} =
  view.frameCount == 0 or view.data == nil

func sampleAt*(view: SampleView; frame: uint32; channel: uint32 = 0): int16 {.noinline.} =
  if frame >= view.frameCount or view.data == nil or view.channelCount == 0:
    return 0
  let selected = if channel < view.channelCount: channel else: 0'u32
  # Keep the index in 32 bits: the device has no 64-bit multiply helper.
  let last = high(uint32) - selected
  if frame > last div view.channelCount:
    return 0
  let index = frame * view.channelCount + selected
  if index > uint32(high(int)):
    return 0
  view.data[int(index)]

func sample*(analysis: SampleAnalysis): SampleView {.inline.} = analysis.sampleData
func words*(analysis: SampleAnalysis): WordView {.inline.} =
  initWordView(analysis.wordData, analysis.count)
func wordCount*(analysis: SampleAnalysis): uint32 {.inline.} = analysis.count
func info*(analysis: SampleAnalysis): uint32 {.inline.} = analysis.extra

func isEmpty*(view: WordView): bool {.inline.} =
  view.count == 0 or view.data == nil

func len*(view: WordView): int {.inline.} = view.count

func `[]`*(view: WordView; index: int): uint32 {.inline.} =
  if index < 0 or index >= view.count or view.data == nil: 0'u32
  else: view.data[index]

func `[]=`*(view: WordView; index: int; value: uint32) {.inline.} =
  if index >= 0 and index < view.count and view.data != nil:
    view.data[index] = value

func isEmpty*(region: SampleRegion): bool {.inline.} =
  region.begin >= region.`end`

func frames*(sampleBlock: SampleBlock): int {.inline.} =
  let channels = if sampleBlock.outputChannels == 2: 2 else: 1
  sampleBlock.output.len div channels

func mono*(sampleBlock: SampleBlock): bool {.inline.} =
  sampleBlock.outputChannels != 2
