# Updating the pinned SDK

Use this checklist when moving `open-xy.lock` to a new tagged SDK release.

## 1. Inspect the tag

```sh
git -C open-xy fetch origin tag v0.0.3
git -C open-xy show --stat --oneline v0.0.3
git -C open-xy show v0.0.3:VERSION
git -C open-xy show v0.0.3:docs/api.md | head -40
```

Record the tag, commit, firmware version, SDK API version, and the expected
stock OS version. For the current release:

```text
tag:         v0.0.3
commit:     17840e39a0e427be827cd1c8cbc62d8015205bcd
firmware:    1.2.1
SDK API:     1.6
stock OS:    os.ldr 1.2.1
```

Stop if the tag does not contain the machine headers, the extension headers,
the q31 helpers, and `profiles/opxy-<firmware>.json`.

## 2. Move the pin

```sh
git -C open-xy checkout --detach v0.0.3
printf '%s\n' 17840e39a0e427be827cd1c8cbc62d8015205bcd > open-xy.lock
git add open-xy
git submodule status
nim doctor
```

The gitlink must be staged as `160000`; a plain jj commit does not preserve Git
submodules. See `release.md` for the release commit rule.

## 3. Review the header diff

```sh
git -C open-xy diff --stat c10d61b..17840e3 -- sdk/include
git -C open-xy diff c10d61b..17840e3 -- sdk/include
```

Confirm every changed header has a corresponding public or raw binding change.
For SDK 1.6 the machine-facing change is `opxy/sample_engine.hpp`: `PadSettings`
widens from `u16` to `u32` and carries an 18-bit value. The extension headers
(`opxy/extension.hpp`, `opxy/double_tap.hpp`) are present but are not part of
the machine raw binding list; the extension authoring change owns them.

## 4. Regenerate raw bindings

The header list in `scripts/regen.nims` stays machine-only. Run:

```sh
nim regen
nim cpp -r --hints:off --path:src --passC:-Iopen-xy/sdk/include tests/t_raw.nim
```

Review the generated diff and `src/openxy/private/raw/henka.patch`. The patch
must set `PadSettings` to `uint32`; if Henka changes a template or constant
form, update the patch instead of editing generated files by hand.

## 5. Check the ABI

```sh
nim cpp -r --hints:off --path:src tests/t_abi.nim
```

The probe must agree with the pinned header:

```text
PadSettings        4 bytes
SampleAssignment   40 bytes (64-bit) / 32 bytes (32-bit)
SampleBlock        80 bytes (64-bit) / 64 bytes (32-bit)
SampleView         24 / 16
SampleAnalysis     40 / 28
Buffer             16 / 8
```

## 6. Check PageHeader parity

```sh
nim cpp -r --hints:off --path:src --passC:-Iopen-xy/sdk/include tests/t_page_header.nim
```

The C++ probe must use the pinned `opxy/page_header.hpp`; the Nim helper must
match its page selection, animation, text, and header output.

## 7. Review machine metadata and profiles

SDK 1.5 and newer remove `machine.json.identity`; the build layout assigns the
engine/effect/page numbers. A sample engine names `"base": "sampler"` or
`"base": "drumSampler"` instead of a stock page. Pad settings and drum controls
require the drum sampler base. SDK 1.4 machines may keep `identity` for
compatibility.

The firmware profile remains `opxy-1.2.1` and the stock OS remains 1.2.1. The
module region is now 2032 KiB, and voices are calculated as
`voiceBytes × (min(voiceCapacity, 27) + 1)`. Update `docs/manual.md`,
`docs/testing.md`, `README.md`, `docs/release.md`, `docs/hardware-test.md`, and
the memory report together.

Do not rewrite the authored machine JSON to hide a profile change.

## 8. Update machine-facing features

Review `docs/api.md` and `docs/display.md` for:

- the `PadSettings` 18-bit value and `toUint32` conversion;
- the identity/base split and layout-provided numbers;
- display activation/reset behavior;
- new extension headers left to the extension authoring change;
- starter template changes.

Update validation, public Nim helpers, templates, and tests together. Run:

```sh
nim test
nim checkTemplates -- --full
```

## 9. Release documentation

Update `docs/api.md`, `README.md`, `docs/testing.md`, and the release notes.
Record the exact tag and the hardware-tested stock OS. A CI-green checkout
without a hardware record is not a release candidate. The combined candidate
includes the stacked hardening and extension changes; do not claim a hardware
pass from a stale package hash.

## Drift rule

If the new tag changes a public header, a profile hash, the stock OS, or a
template rule and this checklist does not explain the change, stop. Do not
accept the drift by editing only one layer.
