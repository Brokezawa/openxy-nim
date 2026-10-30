## A small, complete OP-XY sample engine written in Nim.
##
## It plays the sample assigned to each voice, implements the optional pad,
## drum-page and analysis services, and keeps the analysis state in the
## machine-owned `Preparation` value the SDK measures at build time.

import openxy

type
  Voice* = object
    sample: SampleView
    position: uint32
    once: bool
    finished: bool

  Preparation* = object
    sample: SampleView
    storage: ptr UncheckedArray[uint32]
    peak: uint32
    wordCount: uint32

const
  Once = PadSettings(1)


proc initialize*(voice: var Voice; sample: SampleView) {.raises: [].} =
  voice.sample = sample
  voice.position = 0
  voice.once = false
  voice.finished = false


proc start*(voice: var Voice) {.raises: [].} =
  voice.position = 0
  voice.finished = false


proc renderSample*(voice: var Voice; sampleBlock: SampleBlock) {.raises: [].} =
  let channels = if sampleBlock.outputChannels == 2: 2 else: 1
  let first = sampleBlock.region.begin
  let last = sampleBlock.region.`end`
  voice.once = (uint32(sampleBlock.settings) and 1) != 0 or
    sampleBlock.parameters[1] > Q31(0x40000000)
  for index in 0 ..< BlockFrames:
    if voice.position < first or voice.position >= last:
      voice.finished = voice.once and voice.position >= last
      voice.position = first
    let silent = voice.finished or first >= last
    for channel in 0 ..< channels:
      var value = Q31(0)
      if not silent:
        value = Q31(int32(voice.sample.sampleAt(voice.position, uint32(channel))) * 0x8000)
      sampleBlock.output[index * channels + channel] = value * sampleBlock.parameters[2]
    if not silent:
      inc voice.position


proc sampleDefaults*(): PadSettings {.raises: [].} =
  PadSettings(0)


proc sampleAssign*(assignment: SampleAssignment): PadSettings {.raises: [].} =
  if assignment.replacing:
    assignment.previous
  else:
    sampleDefaults()


proc drumControl*(value: var PadSettings; event: DrumControl) {.raises: [].} =
  if event.knob == 0 and event.pressed:
    value = PadSettings(uint32(value) xor uint32(Once))


proc drumPanel*(value: PadSettings; saved: SampleRegion;
                parameters: openArray[Q31]; panel: var DrumPanel) {.raises: [].} =
  panel.repeat = (uint32(value) and uint32(Once)) == 0
  panel.level = 0x7fffffff'u32


proc analysisWords*(sample: SampleView): uint32 {.raises: [].} =
  if sample.frames > 0: 1'u32 else: 0'u32


proc prepareBegin*(job: var Preparation; sample: SampleView;
                   storage: ptr uint32; words: uint32): bool {.raises: [].} =
  if storage == nil or words < 1:
    return false
  job = Preparation(
    sample: sample,
    storage: cast[ptr UncheckedArray[uint32]](storage),
    peak: 0,
    wordCount: 1,
  )
  true


proc prepareStep*(job: var Preparation; frames: uint32;
                  cursor: var uint32): PrepareStatus {.raises: [].} =
  let lastFrame = min(job.sample.frames, cursor + frames)
  while cursor < lastFrame:
    let value = int32(job.sample.sampleAt(cursor))
    let magnitude = if value < 0: uint32(-value) else: uint32(value)
    if magnitude > job.peak:
      job.peak = magnitude
    inc cursor
  if cursor < job.sample.frames: prepareRunning else: prepareDone


proc prepared*(job: Preparation; analysis: var SampleAnalysis): bool {.raises: [].} =
  if job.storage == nil or job.wordCount == 0:
    return false
  job.storage[0] = job.peak
  analysis = SampleAnalysis(
    sample: job.sample,
    words: job.storage,
    wordCount: job.wordCount,
    info: 0,
  )
  true


openxyValidate(mkSample, Voice)
