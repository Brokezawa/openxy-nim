import openxy

type
  Voice* = object
  Shared* = object

proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} = discard
proc start*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} = discard
proc render*(voice: var Voice; shared: var Shared; owner: VoiceId;
             output: var openArray[Q31]; parameters: openArray[Q31];
             pitch: openArray[PhaseIncrement]) {.raises: [].} = discard

openxyValidate(mkSynth, Voice, Shared)
