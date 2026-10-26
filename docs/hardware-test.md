# Hardware testing

Hardware testing is the primary gate for the 0.1.0 release. CI cannot replace
it because CI has no stock OS and no OP-XY device.

## Safety

- Use a stock OP-XY OS 1.2.0 image that you own.
- Keep a copy of the stock OS outside the repository.
- Do not commit the stock OS, firmware package, sample content, or device
  identifiers.
- Do not publish the candidate package.
- A passing test does not guarantee recovery from a failed write.

## Candidate record

Fill this table from the candidate package and the SDK build report.

| Field | Value |
| --- | --- |
| Candidate commit | |
| Candidate package path | |
| Package hash (`candidate/os.ldr`) | |
| Stock OS version | |
| Stock OS SHA-256 | |
| Machine IDs | mysynth, mysample, myeffect |
| Tester and date | |

The SDK build report contains `os_sha256` and memory sizes. Record the command
used to build the package.

## Test matrix

Mark each check only after observing it on the device.

### Install and boot

- [ ] Copy the candidate `os.ldr` to `/os.ldr` using the SDK install steps.
- [ ] Copy `content/op1_factory.json` to `/content/op1_factory.json`.
- [ ] Copy `content/display/mysynth.svg` to `/content/display/mysynth.svg`.
- [ ] Reboot the device.
- [ ] The device reaches the normal OS and does not hang.

### Synth

- [ ] The synth is selectable from the stock UI.
- [ ] Notes produce audio.
- [ ] The four controls change the sound.
- [ ] The display draws and animates without corruption.
- [ ] Note release and voice reuse do not crash or hang.

### Sample

- [ ] A sample can be assigned and played.
- [ ] Pad settings and playback work.
- [ ] The drum page opens and its controls respond.
- [ ] The sample does not crash or leave a stuck voice.

### Effect

- [ ] The effect is selectable on a send track.
- [ ] The effect changes the send audio.
- [ ] The dry control works.
- [ ] The effect does not crash or hang when bypassed or removed.

### Reboot

- [ ] A second reboot reaches the OS.
- [ ] The three machines remain selectable.
- [ ] No repeated crash or recovery screen occurs.

## Result

| Result | Meaning |
| --- | --- |
| PASS | Every required check above was observed on the recorded configuration. |
| FAIL | At least one required check failed, or the device did not boot. |

Result: **Not recorded yet.**

Notes:

```text
Add device model, OS version, test date, and any observed limitation.
Do not include private sample names, serial numbers, or stock OS files.
```

## If the result is FAIL

Do not tag the release. Record the failing check and the package hash. Fix the
machine code, generator, or documentation as appropriate. Rebuild the package.
Repeat this matrix if machine code, runtime, or generator changed.

## If the result is PASS

Record the exact configuration in the release notes:

```text
Tested on OP-XY OS 1.2.0 with the <candidate-commit> package on <date>.
Still experimental; no recovery guarantee.
```

See [release](release.md) for the remaining tag steps.
