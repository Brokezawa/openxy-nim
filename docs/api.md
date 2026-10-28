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

`Phase` and `PhaseIncrement` are distinct `uint32` values. Adding an increment
to a phase wraps. `Q10` is display geometry, `Q27` is an unsigned sample-region
gain, `Cents` and `Semitones` are tuning, `SampleFrame` is a sample index,
`VoiceId` is a stable nonzero owner, `PadSettings` is a 16-bit SDK-defined
value, and `Paint` is the four-byte draw enum.

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
`initAudioView`/`initMutableAudioView`.

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
changes only establish a baseline.

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

proc display(state: var DisplayState; input: Input; frame: var Frame) =
  const titles: array[8, string] = [
    "Blend", "Width", "Level", "Motion",
    "Drive", "Crush", "Rectify", "Smooth",
  ]
  var values: array[8, HeaderText]
  for index in 0 ..< values.len:
    headerAmount(values[index], input.slots[index])
  const slots: PageHeaderSlots = [[0'u8, 1, 2, 3], [4'u8, 5, 6, 7]]
  pageHeader(state.header, input, frame, titles, values, 2, slots)
```

`PageHeader` is a 20-byte value with private state. `headerAmount` writes a
rounded 0..100 caption without a percent sign. `pageHeader` requires at least
16 text slots, eight header nodes after its static `firstNode`, and no C++
Frame shim. Nodes 0 and 1 are the template's path nodes; nodes 2 through 9 are
the header bars. `DefaultPageHeaderSlots` is the standard
`[[0, 1, 2, 3], [4, 5, 6, 7]]` page map.

## SDK 1.4 metadata

A machine declares `machine.json.sdk` as `"1.4"` to use the current surface.
The SDK builds machines from 1.0 through 1.4.

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
# or openxyValidate(mkSample, Voice)
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

`Buffer` and `Transport` are plain mirrors; an absent buffer has `count == 0`,
and an absent transport has `bpmX10 == 0`. `EffectBlock` carries left/right
mutable views, parameters, buffer, and transport. `division` and
`divisionSixteenths` implement the SDK delay division control.

## Testkit

`openxy/testkit` provides `zeroInput`, `zeroFrame`, `zeroParameters`,
`zeroPitch`, `renderBlock`, `displayFrame`, `assertFrameValid`,
`assertBufferEmpty`, `assertTransportEmpty`, and `hasAnalysis` for host tests.
