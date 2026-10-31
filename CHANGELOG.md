# Changelog

All notable changes to openxy are recorded here.

## 0.1.0 — 2026-10-31

### Added

- Idiomatic Nim authoring API for OP-XY synth, sample, and effect machines.
- Typed Q31/SatQ31 arithmetic, units, audio views, display mirrors, and
  sample/effect blocks.
- Metadata validation, target-ABI measurement, and C++ machine generation.
- Synth, sample, and effect templates with host tests.
- Browser preview for synths.
- Blackfin device compile and four-machine collection build.
- Pinned OP-XY SDK tag `v0.0.3` (`17840e3`), firmware 1.2.1, and SDK API 1.6.
- Safe view API: `WordView`, private storage on `SampleView`/`Buffer`/
  `SampleAnalysis`, read-only accessors, and testkit constructors.
- `Q31Half`, `toUint32(Q31)`, `fromQ15`, `MaxHeldNotes`, and enum-indexed
  parameter lookup.
- SDK 1.6 18-bit pad settings, layout-provided machine numbers, sample engine
  bases, page headers, page switching, machine presets, 16 text slots, and
  effect alternates.
- Eight-control `synth-eight` template with the shared two-row header.
- Experimental extension API: `Hooks`, `Actions`, `DoubleTap`, a generated
  C++ adapter, and the `mynotify` extension template.
- Extension validation, host tests, 32-bit ABI probe, and `nim checkTemplates`
  coverage.
- Optional Henka raw-binding regeneration with a checked-in normalization patch.
- GitHub Actions release checks for Linux, macOS, and Atlas.
- Manual, testing, release, and hardware-testing documentation.

### Changed

- Templates use named control enums, named domain constants, and no
  `cast`/`ptr`/`addr`; the synth-eight DSP stages are private inline functions.
- `prepareBegin` receives a `WordView`; host tests build views through the
  public/testkit constructors.
- `nim checkTemplates` rejects unsafe tokens in template sources.

### Fixed

- Both synth templates write path points in Q10, so their two rings render at
  the intended radius instead of collapsing to dots; `mysynth` uses visible
  palette shades and centers its nodes at 240±32,120 with Motion-driven movement.

### Limits

- Source-only experimental developer preview.
- Firmware images and stock OS files are not included.
- Hardware-tested on OP-XY OS 1.2.1 on 2026-10-31 with the four machines and
  `mynotify`; still experimental, with no recovery guarantee.
- Browser preview is synth-only.
- The extension API is experimental, source-level, and covered by one
  `mynotify` hardware row, not a stability guarantee.
- Windows is untested.
- Nix and direnv are not part of the 0.1.0 setup.
- `--mm:arc` is the tested device profile; `--mm:none` is experimental.
