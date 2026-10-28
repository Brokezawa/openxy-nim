# Hardware testing

Hardware testing is the primary gate for the 0.1.0 release. CI cannot replace
it because CI has no stock OS and no OP-XY device.

## Safety

- Use a stock OP-XY OS 1.2.1 image that you own and the SDK tag `v0.0.2`
  (API 1.4).
- Keep a copy of the stock OS outside the repository.
- Do not commit the stock OS, firmware package, sample content, or device
  identifiers.
- Do not publish the candidate package.
- A passing test does not guarantee recovery from a failed write.

## Candidate record

Fill this table from the candidate package and the SDK build report.

| Field | Value |
| --- | --- |
| Candidate commit | `f9d05c6c7d10` (jj working candidate; final Git release commit pending) |
| Candidate package path | `/Users/zawa/Projects/nim/open-xy-nim/openxy/templates/sample/build/out/0.1.0-candidate-synth8` |
| Package hash (`candidate/os.ldr`) | `1d42f109c8f44153b2ab48dd2ebe6c0889838d039c19d49e80a6d6ecd159bd8e` |
| Stock OS version | 1.2.1 |
| SDK tag / API | v0.0.2 / 1.4 |
| Stock OS SHA-256 | `60358afdaa9b58ed40411602f6d5d4e1e3e02553ff2da7e25038e71dd002b52f` |
| Machine IDs | mysynth, mysynth8, mysample, myeffect |
| Tester and date | User, 2026-10-29 |
| Build profile | `opxy-1.2.1`, profiling enabled, fresh-source rebuild matched |

The SDK build report contains `os_sha256` and memory sizes. Record the command
used to build the package.

## Test matrix

Mark each check only after observing it on the device.

### Install and boot

- [x] Copy the candidate `os.ldr` to `/os.ldr` using the SDK install steps.
- [x] Copy `content/op1_factory.json` to `/content/op1_factory.json`.
- [x] Copy `content/display/mysynth.svg` to `/content/display/mysynth.svg`.
- [x] Copy `content/display/mysynth8.svg` to `/content/display/mysynth8.svg`.
- [x] Reboot the device.
- [x] The device reaches the normal OS and does not hang.

### Synth

- [x] The synth is selectable from the stock UI.
- [x] Notes produce audio.
- [x] The four controls change the sound.
- [x] The display draws and animates without corruption.
- [x] Note release and voice reuse do not crash or hang.

### Synth-eight

- [x] `mysynth8` is selectable from the stock UI.
- [x] Notes produce audio.
- [x] All eight controls change the sound.
- [x] The two-row header switches pages when an encoder is pressed.
- [x] The header titles and values update without corruption.
- [x] Note release and voice reuse do not crash or hang.

### Sample

- [x] A sample can be assigned and played.
- [x] Pad settings and playback work.
- [x] The drum page opens and its controls respond.
- [x] The sample does not crash or leave a stuck voice.

### Effect

- [x] The effect is selectable on a send track.
- [x] The effect changes the send audio.
- [x] The dry control works.
- [x] The effect does not crash or hang when bypassed or removed.

### Reboot

- [x] A second reboot reaches the OS.
- [x] The four machines remain selectable.
- [x] No repeated crash or recovery screen occurs.

## Result

| Result | Meaning |
| --- | --- |
| PASS | Every required check above was observed on the recorded configuration. |
| FAIL | At least one required check failed, or the device did not boot. |

Result: **PASS**

Notes:

```text
All four machines booted and behaved as expected.
No bug, crash, stuck voice, display corruption, or recovery screen was observed.
Tested on OP-XY OS 1.2.1 with SDK tag v0.0.2, API 1.4.
This remains an experimental build; no recovery guarantee.
```

## If the result is FAIL

Do not tag the release. Record the failing check and the package hash. Fix the
machine code, generator, or documentation as appropriate. Rebuild the package.
Repeat this matrix if machine code, runtime, or generator changed.

## If the result is PASS

Record the exact configuration in the release notes:

```text
Tested on OP-XY OS 1.2.1 with the <candidate-commit> package on <date>.
SDK tag v0.0.2, API 1.4. Still experimental; no recovery guarantee.
```

See [release](release.md) for the remaining tag steps.
