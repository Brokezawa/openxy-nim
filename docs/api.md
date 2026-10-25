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
type Frame = openxy.Frame[2, 64, 2, 0, 16]
```

Helpers: `place`, `hide`, `shade`, `turn`, `text`, `header`, `rotation`,
`sine`, `sweep`, `valid`, and `NoteTracker.update`. `NoteTracker` reports
`holdStarted`, `holdEnded`, and `noteReleased`; the first snapshot and track
changes only establish a baseline.

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
