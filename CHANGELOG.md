# Changelog

All notable changes to openxy are recorded here.

## 0.1.0 — Unreleased

### Added

- Idiomatic Nim authoring API for OP-XY synth, sample, and effect machines.
- Typed Q31/SatQ31 arithmetic, units, audio views, display mirrors, and
  sample/effect blocks.
- Metadata validation, target-ABI measurement, and C++ machine generation.
- Synth, sample, and effect templates with host tests.
- Browser preview for synths.
- Blackfin device compile and four-machine collection build.
- Pinned OP-XY SDK tag `v0.0.2` (`c10d61b`), firmware 1.2.1, and SDK API 1.4.
- SDK 1.4 page headers, page switching, machine presets, 16 text slots, and
  effect alternates.
- Eight-control `synth-eight` template with the shared two-row header.
- Optional Henka raw-binding regeneration with a checked-in normalization patch.
- GitHub Actions release checks for Linux, macOS, and Atlas.
- Manual, testing, release, and hardware-testing documentation.

### Changed

- None.

### Limits

- Source-only experimental developer preview.
- Firmware images and stock OS files are not included.
- Device builds are not hardware-qualified until the release hardware test is
  recorded.
- Browser preview is synth-only.
- Windows is untested.
- Nix and direnv are not part of the 0.1.0 setup.
- `--mm:arc` is the tested device profile; `--mm:none` is experimental.
