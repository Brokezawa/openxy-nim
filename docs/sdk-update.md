# Updating the pinned SDK

Use this checklist when moving `open-xy.lock` to a new tagged SDK release.

## 1. Inspect the tag

```sh
git -C open-xy fetch origin tag v0.0.2
git -C open-xy show --stat --oneline v0.0.2
git -C open-xy show v0.0.2:VERSION
git -C open-xy show v0.0.2:docs/api.md | head -40
```

Record the tag, commit, firmware version, SDK API version, and the expected
stock OS version. For the current release:

```text
tag:         v0.0.2
commit:      c10d61b529521eff48dfcc619cb0d793e602e2eb
firmware:    1.2.1
SDK API:     1.4
stock OS:    os.ldr 1.2.1
```

Stop if the tag does not contain `sdk/include/opxy/page_header.hpp`, the q31
helpers, the machine headers, and `profiles/opxy-<firmware>.json`.

## 2. Move the pin

```sh
git -C open-xy checkout --detach v0.0.2
printf '%s\n' c10d61b529521eff48dfcc619cb0d793e602e2eb > open-xy.lock
git add open-xy
git submodule status
nim doctor
```

The gitlink must be staged as `160000`; a plain jj commit does not preserve Git
submodules. See `release.md` for the release commit rule.

## 3. Review the header diff

```sh
git -C open-xy diff --stat fdf48e5..c10d61b -- sdk/include
git -C open-xy diff fdf48e5..c10d61b -- sdk/include
```

Confirm every changed header has a corresponding public or raw binding change.
For SDK 1.4 the only new public header is `opxy/page_header.hpp`.

## 4. Regenerate raw bindings

Update the header list in `scripts/regen.nims`, then:

```sh
nim regen
nim cpp -r --hints:off --path:src --passC:-Iopen-xy/sdk/include tests/t_raw.nim
```

Review the generated diff and `src/openxy/private/raw/henka.patch`. If Henka
changes a template or constant form, update the patch instead of editing
generated files by hand.

## 5. Check PageHeader parity

```sh
nim cpp -r --hints:off --path:src --passC:-Iopen-xy/sdk/include tests/t_page_header.nim
```

The C++ probe must use the pinned `opxy/page_header.hpp`; the Nim helper must
match its page selection, animation, text, and header output.

## 6. Move the profile and stock files

Compare the new `profiles/opxy-<version>.json`, linker script, and stock content
against the old release. Update:

- `docs/manual.md`, `README.md`, `docs/testing.md`, `docs/release.md`, and
  `docs/hardware-test.md` stock paths;
- the hardware candidate stock OS version;
- CI cache/docs references;
- any SDK version gates in `src/openxy/util/validate.nim`.

Do not rewrite the authored machine JSON to hide a profile change.

## 7. Update machine-facing features

Review `docs/api.md` and `docs/display.md` for:

- new `machine.json` fields;
- display text-slot limits and SDK version gates;
- page switching and effect alternates;
- new headers such as `page_header.hpp`;
- starter template changes.

Update validation, public Nim helpers, templates, and tests together. Run:

```sh
nim test
nim checkTemplates -- --full
```

## 8. Release documentation

Update `docs/api.md`, `README.md`, `docs/testing.md`, and the release notes.
Record the exact tag and the hardware-tested stock OS. A CI-green checkout
without a hardware record is not a release candidate.

## Drift rule

If the new tag changes a public header, a profile hash, the stock OS, or a
template rule and this checklist does not explain the change, stop. Do not
accept the drift by editing only one layer.
