import openxy/private/raw/opxy/sample

type
  SampleAnalysis* {.importcpp: "opxy::SampleAnalysis",
    header: "opxy/sample_analysis.hpp".} = object
    sample*: SampleView
    words*: ptr uint32
    word_count*: uint32
    info*: uint32

  PrepareStatus* {.size: sizeof(cint), pure,
    importcpp: "PrepareStatus", header: "opxy/sample_analysis.hpp".} = enum
    prepare_failed = 0
    prepare_done = 1
    prepare_running = 2

const
  prepare_failed* = PrepareStatus.prepare_failed
  prepare_done* = PrepareStatus.prepare_done
  prepare_running* = PrepareStatus.prepare_running
