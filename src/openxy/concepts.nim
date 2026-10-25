## Compile-time callback contracts.
##
## These concepts catch ordinary shape mistakes at the machine source. The
## generated wrapper repeats exact proc-type and `raises: []` checks because a
## concept cannot enforce effects.

import std/assertions

import openxy/audio
import openxy/effect
import openxy/kind
import openxy/q31
import openxy/sample
import openxy/units

type
  SynthMachine*[V, S] = concept voice, shared
    initialize(voice, shared, VoiceId)
    start(voice, shared, VoiceId)
    destroy(voice, shared, VoiceId)
    render(voice, shared, VoiceId, var openArray[Q31], openArray[Q31],
           openArray[PhaseIncrement])

  SampleMachine*[V] = concept voice
    initialize(voice, SampleView)
    start(voice)
    renderSample(voice, SampleBlock)

  EffectMachine*[S] = concept state
    initialize(state)
    process(state, EffectBlock)

template openxyValidate*(kind: static[MachineKind]; voice: typedesc;
                         shared: typedesc) =
  ## Validate a synth at the line where the machine declares its contract.
  when kind != mkSynth:
    {.error: "openxyValidate with Voice and Shared is for synth machines".}
  else:
    static:
      doAssert compiles(block:
        let initializeCb: proc (value: var voice; state: var shared;
                                owner: VoiceId) {.raises: [].} = initialize
        let startCb: proc (value: var voice; state: var shared;
                           owner: VoiceId) {.raises: [].} = start
        let destroyCb: proc (value: var voice; state: var shared;
                             owner: VoiceId) {.raises: [].} = destroy
        let renderCb: proc (value: var voice; state: var shared;
                            owner: VoiceId; output: var openArray[Q31];
                            parameters: openArray[Q31];
                            pitch: openArray[PhaseIncrement]) {.raises: [].} = render
      ), "synth callbacks must have the exact SDK signature and must not raise"

template openxyValidate*(kind: static[MachineKind]; voice: typedesc) =
  ## Validate a sample engine or effect at the machine source.
  when kind == mkSample:
    static:
      doAssert compiles(block:
        let initializeCb: proc (value: var voice; sample: SampleView)
          {.raises: [].} = initialize
        let startCb: proc (value: var voice) {.raises: [].} = start
        let renderCb: proc (value: var voice; sampleBlock: SampleBlock)
          {.raises: [].} = renderSample
      ), "sample callbacks must have the exact SDK signature and must not raise"
  elif kind == mkEffect:
    static:
      doAssert compiles(block:
        let initializeCb: proc (state: var voice) {.raises: [].} = initialize
        let processCb: proc (state: var voice; effectBlock: EffectBlock)
          {.raises: [].} = process
      ), "effect callbacks must have the exact SDK signature and must not raise"
  else:
    {.error: "openxyValidate with one type is for sample or effect machines".}
