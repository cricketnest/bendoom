# Bend 2.0.22 upgrade

21 September 2026. The proof repair proved small enough to do now: 45 lines added, 59 removed, and the full proof check passes. This replaces the earlier recommendation to defer until the twelve game tickets were finished.

The flake now pins `94ee9ba40043643df648b13fc5638b065a37cb4e`, Bend 2.0.22. Its source package keeps the window patch and disables telemetry in the compiler wrapper, including outside the dev shell.

## Proof repair

Bend 2.0.17 changed `Nat.min` and `Nat.max` from comparisons followed by `Bool.pick` to structural recursion. Our clipping helpers proved properties of that old implementation. The replacement helpers prove bounds on `Nat.min` and `Nat.max` directly by induction. The comparison flags and their equality witnesses are gone, along with the unused transitivity and comparison helpers. Every law in `LAWS.bend` is unchanged. [Upstream definitions](https://github.com/bendlang/bend/blob/94ee9ba40043643df648b13fc5638b065a37cb4e/bend2/base.bend#L633-L650)

## Remaining workarounds

The 255-word native segment cap, long list literal limit and last-field tuple quantity bug remain. The shared-array documentation complaint is resolved, and large Nat literals now check directly.

`File.write_bytes`, `File.size` and `File.read_at` are available. Adopting them can remove the demo/audio hex conversion and the file reader's array growth. Byte reads still return lists; that remains an upstream request. These I/O refactors are separate from the compiler upgrade. [Base API](https://github.com/bendlang/bend/blob/94ee9ba40043643df648b13fc5638b065a37cb4e/bend2/base.bend#L258-L290)

## Validation

- `nix flake check -L --max-jobs 1` passes on x86_64 Linux, including the full proofs and all fourteen tests on native and JavaScript. Other platforms were not run.
- All twenty Chocolate Doom frame comparisons report zero differing pixels, covering every rest position in `tests/render.bend` and the demon's six-tic pose.
- `nix build .#bendoom .#film --no-link` passes. The packaged shareware game opens and quits cleanly on Xvfb with a silent ALSA sink.

The proof rewrite removes two matches and three case arms. No game code, laws or expected test outputs changed.
