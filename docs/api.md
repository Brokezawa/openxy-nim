# openxy API

## Audio values

`Q31` is a `distinct int32` Q1.31 sample.

- `+` and `-` wrap modulo 2^32 and compile to unsigned arithmetic.
- `*` calls the SDK's saturating Q1.31 multiply.
- `SatQ31` uses saturating `+`, `-`, and `*`.
- `Q31` converts implicitly to `SatQ31`; use `toQ31` for explicit demotion.
- `Q31Like` accepts either type in generic DSP code.
- `half` uses the SDK helper. `saturatingAdd`/`saturatingSub` accept both types
  and raw `int32` values.
- `Q31Half` is the Q1.31 half-scale value `0x40000000`. `toUint32` returns the
  two's-complement bit pattern without raising, and `fromQ15` converts a Q1.15
  sample to Q1.31.

`Phase` and `PhaseIncrement` are distinct `uint32` values. Adding an increment
to a phase wraps. `Q10` is display geometry, `Q27` is an unsigned sample-region
gain, `Cents` and `Semitones` are tuning, `SampleFrame` is a sample index,
`VoiceId` is a stable nonzero owner, `PadSettings` is a 32-bit SDK-defined value
with an 18-bit range (0..262143), and `Paint` is the four-byte draw enum.
`toUint32` returns the saved value, `toPadSettings` masks to 18 bits, and
existing 16-bit saved values keep their numeric value. Values above 65535
require SDK 1.6.

## Views

The synth callback surface uses:

```nim
Output = openArray[Q31]
Parameters = openArray[Q31]       # 8 slots
Pitch = openArray[PhaseIncrement] # 64 increments
```

The generated adapter copies the SDK's 64-word output into a local Nim array
because a raw pointer cannot become a mutable `openArray`; read-only parameter
and pitch pointers are passed directly. `AudioView` and `MutableAudioView` are
used by sample/effect blocks, with `len`, `[]`, `[]=`, `items`, `mitems`, and
`initAudioView`/`initMutableAudioView`. Host tests use the `openArray`
constructors; machine code never handles the raw pointer. `WordView` is the
borrowed 32-bit view used by sample analysis, with `isEmpty`, `len`, and
bounds-safe `[]`/`[]=`.

Parameter arrays can be indexed by a machine `Control` enum:
`parameters[Blend]`. The template declares the enum in `definition.json` order.

## Display

`Input` is a 76-byte plain mirror; `Node` is 28 bytes, `Text` 36,
`NoteTracker` 16, and `Frame[Paths, Points, Nodes, Texts, Palette]` mirrors the
SDK including `max(Paths, 1)` paths and `max(Texts, 1)` texts. Declare the frame
shape explicitly:

```nim
type Frame = openxy.Frame[2, 64, 10, 16, 16]
```

A frame may declare 0 to 16 text slots. More than four text slots require SDK
1.3 or newer. The declared `Texts` count must match `definition.json` and the
generated C++ frame.

Helpers: `place`, `hide`, `shade`, `turn`, `text`, `header`, `rotation`,
`sine`, `sweep`, `valid`, and `NoteTracker.update`. `NoteTracker` reports
`holdStarted`, `holdEnded`, and `noteReleased`; the first snapshot and track
changes only establish a baseline. `MaxHeldNotes` is 128; a snapshot above it
is treated as unavailable.

`displayReset` runs when an owned synth page becomes selected and when its
selected track changes. The next display callback starts from reset state; use
it for an entrance or a fresh note-activity baseline. Continuing to show the
same page and track does not reset it. Audio state, note routing, and the
drawing input ABI are unchanged.

### Page header

SDK 1.4 adds the shared two-row synth header. Add `PageHeader` to
`DisplayState`, reset it from `displayReset`, and fill it from `display`:

```nim
type
  DisplayState = object
    phase: uint32
    header: PageHeader

  Frame = openxy.Frame[2, 64, 10, 16, 16]

proc displayReset(state: var DisplayState) =
  state.phase = 0
  state.header.reset()

type Control = enum blend, width, level, motion,
  drive, crush, rectify, smooth

proc display(state: var DisplayState; input: Input; frame: var Frame) =
  const titles: array[Control, string] = [
    "Blend", "Width", "Level", "Motion",
    "Drive", "Crush", "Rectify", "Smooth",
  ]
  var values: array[Control, HeaderText]
  for control in Control:
    headerAmount(values[control], input.slots[control])
  pageHeader(state.header, input, frame, titles, values, 2)
```

`PageHeader` is a 20-byte value with private state. `headerAmount` writes a
rounded 0..100 caption without a percent sign. `pageHeader` accepts
`openArray[string]` titles and `openArray[HeaderText]` values, requires eight of
each, at least 16 text slots, eight header nodes after its static `firstNode`,
and no C++ Frame shim. Nodes 0 and 1 are the template's path nodes; nodes 2
through 9 are the header bars. `DefaultPageHeaderSlots` is the standard
`[[0, 1, 2, 3], [4, 5, 6, 7]]` page map.

## SDK 1.6 metadata

A machine declares `machine.json.sdk` as `"1.6"` to use the current surface.
The SDK builds machines from 1.0 through 1.6.

- SDK 1.5 and newer remove `machine.json.identity`; the build layout assigns
  the engine, effect, and page numbers. Pass the previous `layout.json` to
  `nim compile` or `nim build` to keep existing numbers.
- A sample engine targeting 1.5 or newer declares `"base": "sampler"` or
  `"base": "drumSampler"`. Pad settings and drum controls require the drum
  sampler base.
- A legacy SDK 1.4 machine may keep `identity`; the layout gives it those
  numbers when they are free.
- `definition.json` accepts `"press": "page"` for five- to eight-parameter
  synths. SDK 1.3 supports a full second page; a partial page requires 1.4.
- Effects accept up to eight controls. Parameters after the fourth are
  alternates on the send page.
- `machine.json.presets` names a folder of device-authored preset files. Openxy
  copies the folder and the SDK validates its contents.
- `templates/synth-eight` is the idiomatic Nim translation of the SDK
  `synth-eight` starter.

## Callback contracts

`SynthMachine[V, S]`, `SampleMachine[V]`, and `EffectMachine[S]` are public
concepts. `openxyValidate` adds the exact proc-type and `raises: []` check at
the machine source:

```nim
openxyValidate(mkSynth, Voice, Shared)
# or openxyValidate(mkSample, Voice) for a sample engine without analysis
# or openxyValidate(mkSample, Voice, Preparation) with analysis callbacks
# or openxyValidate(mkEffect, State)
```

The generated wrapper repeats the exact checks and static size/alignment
asserts. The generator validates metadata, names, controls, presets, resources,
and measured layouts; the SDK remains the final authority.

## Sample and effect views

`SampleView`, `SampleRegion`, `SampleAssignment`, `DrumControl`, `DrumPanel`,
`SampleAnalysis`, and `SampleBlock` mirror the SDK sample engine. `SampleBlock`
carries mutable output, read-only parameters and pitch views, transport, region,
optional analysis (`Option[ptr SampleAnalysis]`), pad settings, channel count,
and track/drum transpose. `SampleView.sampleAt` is bounds-safe.

`SampleView`, `Buffer`, and `SampleAnalysis` keep their storage private. Host
code constructs them with `initSampleView`, `initBuffer`, `initWordView`, and
`initSampleAnalysis`; metadata is read through `frames`, `rate`, `channels`,
`len`, `words`, `wordCount`, and `info`. The sample-analysis `prepareBegin`
callback receives a `WordView`, not a pointer and word count.

`Buffer` and `Transport` are plain mirrors; an absent buffer is empty, and an
absent transport has `bpmX10 == 0`. `EffectBlock` carries left/right mutable
views, parameters, buffer, and transport. `division` and `divisionSixteenths`
implement the SDK delay division control.

## Testkit

`openxy/testkit` provides `zeroInput`, `zeroFrame`, `zeroParameters`,
`zeroPitch`, `renderBlock`, `displayFrame`, `assertFrameValid`,
`assertBufferEmpty`, `assertTransportEmpty`, and `hasAnalysis` for host tests.
It also provides `initSampleView`, `initAudioView(openArray)`,
`initMutableAudioView(var openArray)`, `initBuffer(var openArray)`,
`initSampleBlock`, and `initEffectBlock`, so tests never build raw pointers.

## Unsafe code boundary

Machine and extension sources do not use `cast`, `ptr`, `addr`, `unsafeAddr`,
or `UncheckedArray`. The library constructors and the generated adapter own the
SDK reinterpretation. `nim checkTemplates` rejects unsafe tokens under
`templates/*/src`. The synth-eight DSP stages are private `{.inline.}`
functions; the generated device assembly is checked for calls to them.
