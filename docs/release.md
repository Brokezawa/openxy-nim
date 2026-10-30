# Release process

This document is the 0.1.0 release checklist. It is not a general release
automation guide.

## Scope

The 0.1.0 release is a **source-only experimental developer preview**:

- Nim library, four templates, documentation, tests, and pinned SDK submodule.
- No firmware image.
- No stock OS file.
- No Blackfin toolchain.
- No binary archive.
- No Nimble package.

The release is published as an annotated Git tag and a GitHub Release. It
targets SDK tag `v0.0.3` at `17840e3`, firmware `1.2.1`, and SDK API `1.6`. The
release notes must say that the project is experimental and does not guarantee
device recovery.

## Hardware first

Hardware testing is the primary gate. It happens before CI.

1. Freeze machine code.
2. Create a local release-candidate commit.
3. Build one four-machine package with the user's stock OS.
4. Run the test matrix in [hardware testing](hardware-test.md).
5. Record the candidate commit, stock OS hash, package hash, machine IDs, and
   result in `docs/hardware-test.md`.
6. If documentation or CI changes after the pass, verify the package hash is
   unchanged. If machine code, runtime, or generator changes, rebuild and repeat
   the hardware test.
7. Push the final commit.
8. Require all CI jobs to pass.
9. Tag the CI-green commit.
10. Publish the GitHub Release.

A CI-green commit without a hardware record is not a release candidate.

## Build the candidate

The stock OS is a local, private input. Do not commit it.

```sh
python3 open-xy/sdk.py build \
  --machine templates/synth/build/synth/mysynth \
  --machine templates/synth-eight/build/synth/mysynth8 \
  --machine templates/sample/build/sample/mysample \
  --machine templates/effect/build/effect/myeffect \
  --stock-os /path/to/stock-1.2.1/os.ldr \
  --out /tmp/openxy-0.1.0-candidate
```

The release commit must contain the `open-xy` Git submodule gitlink. Jujutsu
0.45 does not support Git submodules: it can show `.gitmodules`, but it does not
preserve the gitlink in its commits. Keep jj for development, then create the
final release commit with Git so the tree contains `mode 160000` for `open-xy`.
Before committing, verify:

```sh
git submodule status
git ls-files -s open-xy
```

`git submodule status` must report
`17840e39a0e427be827cd1c8cbc62d8015205bcd`, and `git ls-files -s open-xy` must
start with `160000`. A plain jj commit is not sufficient for CI, because GitHub
Actions cannot initialize the SDK without the gitlink.

Record:

- candidate commit;
- `sha256` of `candidate/os.ldr`;
- package hash;
- stock OS version and hash (OS 1.2.1);
- SDK tag and API version;
- machine IDs;
- date and tester.

The SDK writes `layout.json` beside the candidate files. Keep it with the
package for a later build.

## Hardware record

Complete [hardware testing](hardware-test.md). The minimum test covers:

- package installation and boot;
- synth audio, controls, and display;
- sample playback, pad, and drum page;
- effect on a send;
- reboot without a crash.

The record belongs in `docs/hardware-test.md`. Do not put private sample
content, stock OS files, or device identifiers in the repository.

## CI gate

The workflow is `.github/workflows/ci.yml`. It runs:

- Linux fast checks, including the unsafe-token template lint;
- macOS full preview and device checks on Apple Silicon;
- Atlas local-link smoke checks.

The release commit must have a green run. If the workflow changes after the
hardware pass, confirm the firmware package hash is unchanged before tagging.

## Tag and release

Use an annotated tag:

```sh
git tag -a v0.1.0 -m "openxy 0.1.0"
git push origin v0.1.0
```

Create a GitHub Release titled:

```text
openxy 0.1.0 — experimental developer preview
```

Release notes must include:

- the tested configuration and date;
- SDK tag `v0.0.3` and API 1.6;
- the stock OS 1.2.1 version;
- the package hash or a link to the hardware record;
- “Still experimental; no recovery guarantee.”;
- the platform limits;
- a statement that no firmware or stock OS is included.

Attach no firmware, binary archive, stock OS, or toolchain.

## Rollback

If hardware testing fails, do not tag. Fix the defect, rebuild the package, and
repeat hardware testing if machine code changed. If CI fails, fix the commit and
rerun CI. If a tag was created in error, do not publish a replacement package
under the same version; create a new patch version.

## Post-release

Optionally verify the published Atlas install path:

```sh
atlas use https://github.com/Brokezawa/openxy-nim
atlas install
git -C deps/openxy submodule update --init --recursive
```

Record any issue before the next release.

## Related documents

- [Hardware testing](hardware-test.md)
- [Testing](testing.md)
- [Changelog](../CHANGELOG.md)
- [SDK pin](../open-xy.lock)
- [SDK update workflow](sdk-update.md)
