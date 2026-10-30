# My Sample

A sample engine for the OP-XY, written in Nim with `openxy`.

## Set up

```sh
atlas init
atlas install
git -C deps/openxy submodule update --init --recursive
```

If the template is copied into an existing project, use
`atlas use https://github.com/Brokezawa/openxy-nim` instead and run `atlas install`.

## Edit

- `config.nims` owns `machineId`, `machineSource`, `buildRoot`, `stockOs`,
  `layout`, and the task names.
- `machine.json` declares SDK 1.6, the sample kind, the `drumSampler` base, and
  amp defaults. Pad settings and drum controls require the drum sampler base;
  a `sampler` base plays chromatically without those services.
- `definition.json` owns the controls, presets, and sample resources.
- `src/mysample.nim` implements `Voice`, `Preparation`, and the sample
  callbacks. `openxyValidate(mkSample, Voice, Preparation)` checks the required
  callbacks. The source uses a `Control` enum, typed `PadSettings` operations,
  `Q31Half`, `fromQ15`, and `WordView`; it contains no `cast`, `ptr`, or `addr`.

The sample engine implements every optional service: pad defaults and
assignment, drum controls and panel, and sample analysis. Remove a service from
`definition.json.resources` and its callback from the source together.

## Build

```sh
nim test       # host tests, checks enabled
nim gen        # validate, measure, prepare, compile
nim compile    # Blackfin development module
nim build      # firmware package; edit stockOs first
nim clean
```

`nim preview` reports that the SDK only previews synths. Use `nim compile` for
the fast device check and `nim test` for the host sound checks.

For `nim build`, set `stockOs` to the stock OP-XY OS 1.2.1 image, for example
`../stock-1.2.1/os.ldr`, and optionally `layout` to the `layout.json` from the
previous package.

## Callbacks

```nim
proc initialize*(voice: var Voice; sample: SampleView) {.raises: [].}
proc start*(voice: var Voice) {.raises: [].}
proc renderSample*(voice: var Voice; block: SampleBlock) {.raises: [].}
proc sampleDefaults*(): PadSettings {.raises: [].}
proc sampleAssign*(assignment: SampleAssignment): PadSettings {.raises: [].}
proc drumControl*(value: var PadSettings; event: DrumControl) {.raises: [].}
proc drumPanel*(value: PadSettings; saved: SampleRegion;
                parameters: openArray[Q31]; panel: var DrumPanel) {.raises: [].}
proc analysisWords*(sample: SampleView): uint32 {.raises: [].}
proc prepareBegin*(job: var Preparation; sample: SampleView;
                   storage: WordView): bool {.raises: [].}
proc prepareStep*(job: var Preparation; frames: uint32;
                  cursor: var uint32): PrepareStatus {.raises: [].}
proc prepared*(job: Preparation; analysis: var SampleAnalysis): bool {.raises: [].}
```
