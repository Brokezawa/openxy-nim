## Small helpers for host-side machine tests.

import std/assertions
import std/options

import openxy/audio
import openxy/draw
import openxy/effect
import openxy/q31
import openxy/sample
import openxy/units

func zeroInput*(): Input =
  Input()

func zeroFrame*[Paths, Points, Nodes, Texts, Palette](): Frame[
    Paths, Points, Nodes, Texts, Palette] =
  Frame[Paths, Points, Nodes, Texts, Palette]()

func zeroParameters*(): array[ParameterSlots, Q31] =
  default(array[ParameterSlots, Q31])

func zeroPitch*(): array[PitchSlots, PhaseIncrement] =
  default(array[PitchSlots, PhaseIncrement])

template renderBlock*(voice, shared, owner): untyped =
  ## Render one block and return its 64 output samples.
  block:
    var output: array[BlockFrames, Q31]
    render(voice, shared, owner, output, zeroParameters(), zeroPitch())
    output

template displayFrame*(state, input, frame): untyped =
  ## Call the machine display callback for one frame.
  block:
    display(state, input, frame)
    frame

template assertFrameValid*(frame) =
  doAssert valid(frame), "display frame does not satisfy the SDK contract"

template assertBufferEmpty*(buffer: Buffer) =
  doAssert buffer.isEmpty, "expected an absent effect buffer"

template assertTransportEmpty*(transport: Transport) =
  doAssert transport.isEmpty, "expected an absent transport"

func hasAnalysis*(sampleBlock: SampleBlock): bool {.inline.} =
  sampleBlock.analysis.isSome

func initSampleBlock*(output: var openArray[Q31];
                      parameters: openArray[Q31];
                      pitch: openArray[PhaseIncrement];
                      region: SampleRegion;
                      settings = PadSettings(0);
                      outputChannels = 1'u32;
                      transport = Transport();
                      analysis = none(ptr SampleAnalysis)): SampleBlock =
  ## Borrow caller-owned test buffers for the lifetime of the block.
  SampleBlock(
    output: initMutableAudioView(output),
    parameters: initAudioView(parameters),
    pitch: initAudioView(pitch),
    transport: transport,
    region: region,
    analysis: analysis,
    settings: settings,
    outputChannels: outputChannels,
  )

func initEffectBlock*(left, right: var openArray[Q31];
                      parameters: openArray[Q31];
                      buffer = Buffer();
                      transport = Transport()): EffectBlock =
  ## Borrow caller-owned test buffers for the lifetime of the block.
  EffectBlock(
    left: initMutableAudioView(left),
    right: initMutableAudioView(right),
    parameters: initAudioView(parameters),
    buffer: buffer,
    transport: transport,
  )
