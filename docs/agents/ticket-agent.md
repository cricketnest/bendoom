# Working a ticket

What every agent dispatched to a ticket does. The dispatch prompt names the worktree, the branch, the base, the ticket, and the handoff notes; this file is the rest.

## Where you work

- Only in the worktree the prompt names. Never touch the main checkout or a sibling worktree. Never rebase or push, and never commit to another branch. The one merge you make is the last step: once your work is committed, merge the integration branch the prompt names INTO your branch, resolve the conflicts by reading both sides, and run the proof and the tests again, so that your branch merges back clean.
- Run tools through the dev shell, `nix develop -c <command>` from the worktree: bend, bun, nu, chocolate-doom, Xvfb and xdotool are in it, and `BENDOOM_IWAD` is Freedoom there. The shareware WAD is `doom1.wad` under the `doom1-wad` store path (`nix build .#doom1-wad --print-out-paths`).
- Other agents run the same commands beside you. Never kill processes by a pattern (`pkill -f`, `killall`); kill only a PID you started.
- Scratch files go under `/tmp/<branch>/`, never in the repo.

## Read before editing

1. `AGENTS.md`. The erasure rules bind you.
2. `docs/bend.md`: what the Bend checker refuses.
3. The milestone's `spec.md`, then your ticket, then the tickets the prompt names as what you build on. Their Comments hold the interfaces you call.
4. The code the prompt names.
5. Vanilla's source, which is the specification: linuxdoom-1.10 as Chocolate Doom 3.1.1 carries it. `nix develop -c nix eval --raw nixpkgs#chocolate-doom.src` does not work offline; find the unpacked source with `ls -d /nix/store/*-source | while read d; do test -f $d/src/doom/s_sound.c && echo $d; done`. Read it; no C enters the repo.

## Merges stay mechanical

Sibling branches edit the same files. Add record fields at the END of a record, append table rows and definitions after the existing ones, and do not reorder, rename or reformat what you are not changing.

## Tests and evidence

- Expected values come from outside the Bend code: vanilla's source worked by hand or replayed in nushell, or the WAD read in nushell (`tools/wad.nu`). No Python anywhere. A value with no outside answer is a regression pin, and the ticket says so.
- A test is a `tests/*.bend` file whose trailing `#|` lines are its expected output, run natively and on the JS lane (bun); `nix/tests.nix` shows how. A whole-frame hash is regenerated only after the oracle says zero for that frame.
- A frame is right when `tools/oracle.nu` reports no differing pixel against Chocolate Doom. Build the dump first (`bend tools/frame.bend -o /tmp/<branch>/frame`, passed with `--frame`). It runs headless on its own Xvfb in real time; several run side by side on a quiet machine. Record each report in the ticket. Never open a window or a sound device on the desktop.
- Laws go in `LAWS.bend`, filled in `PROOF.bend`. `bend PROOF.bend` must print "All terms check." and takes about four minutes. Replay composition must keep holding when the state grows.

## Erasure

Half the effort goes to removing. Replacing X with Y includes deleting X. Update or delete every comment, test header and tool header your change makes false. No comments that narrate inside function bodies, no TODO markers, no scratch tools left in the repo.

## Run and report

1. Run the proof, every test on both lanes, the oracle cases, then `nix flake check` from the worktree. It sees only files that are git-added.
2. Commit in the repo's style: a conventional prefix and a lower-case subject that says what now holds (`git log --oneline -15`). No `Co-Authored-By` trailer. Do not change git config; preserve the configured author and GitHub no-reply email.
3. In the ticket file, tick the boxes you met, set `**Status:** resolved` only if every box is met, and append under `## Comments`: where each expected value came from, the oracle reports, what was built, what was deleted, what was pulled forward from a later ticket, what surprised you. Plain words, no em dashes, no puffery.
4. The final message: commit hashes, the proof, test and oracle results verbatim with output on failure, the interface later tickets call, every trade-off taken, and anything left open. Report failures plainly, and claim no box you did not verify.
