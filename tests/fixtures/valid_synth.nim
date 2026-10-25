import openxy

type
  Voice* = object
    phase: Phase
  Shared* = object
  DisplayState* = object
    notes: NoteTracker
  Frame* = openxy.Frame[0, 0, 1, 0, 1]

proc initialize*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)
proc start*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  voice.phase = Phase(0)
proc destroy*(voice: var Voice; shared: var Shared; owner: VoiceId) {.raises: [].} =
  discard
proc render*(voice: var Voice; shared: var Shared; owner: VoiceId;
             output: var openArray[Q31]; parameters: openArray[Q31];
             pitch: openArray[PhaseIncrement]) {.raises: [].} =
  for i in 0 ..< output.len:
    output[i] = Q31(0)

openxyValidate(mkSynth, Voice, Shared)
