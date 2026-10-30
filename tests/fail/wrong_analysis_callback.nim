import openxy

type
  Voice = object
  Preparation = object

proc initialize(voice: var Voice; sample: SampleView) = discard
proc start(voice: var Voice) = discard
proc renderSample(voice: var Voice; block: SampleBlock) = discard
proc analysisWords(sample: SampleView): uint32 = 0
proc prepareBegin(job: var Preparation; sample: SampleView;
                  storage: ptr uint32; words: uint32): bool = false
proc prepareStep(job: var Preparation; frames: uint32;
                 cursor: var uint32): PrepareStatus = prepareDone
proc prepared(job: Preparation; analysis: var SampleAnalysis): bool = false

openxyValidate(mkSample, Voice, Preparation)
