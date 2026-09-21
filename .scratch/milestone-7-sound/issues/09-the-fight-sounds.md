# 09: The fight sounds

**What to build:** Milestone 6's combat is heard and checked end to end. Its tickets start their sounds inline; this ticket checks the whole: the fight cases print their sounds against vanilla's source, and a recorded fight compares with Chocolate Doom's.

**Blocked by:** 07 (The game sounds); milestone 6's 14 (The fist, the berserk pack and the chainsaw), 20 (Monsters drop their items and doors crush corpses), 21 (Gunfire wakes monsters), 22 (Monsters fight each other and leave the dead alone)

**Status:** resolved

- [x] Every sound vanilla starts in the scripted fights is in the sound table with its priority, and none it cannot start
- [x] The fight cases' sound lines agree with a nushell replay of vanilla's source: weapon, sight, active, attack, pain, death, gib, fireball, barrel, player pain and death
- [x] The chainsaw's idle and the fireball's flight stop and restart as vanilla's do
- [x] Ticket 01 left one gap: a line crossed in the first half of a split move is heard from where the whole move ended, so its volume can be off by one; with moves split for fast monsters and missiles, check it against vanilla here and fix it at its cause if a case shows it
- [x] A recorded fight on Freedoom compares at the target of zero with the sounds placed at their recorded starts
- [x] The second random index at each fight case's end agrees with the replay, so milestone 6's face glances as vanilla's

## Comments

`src/sound.bend` carries the E1M1 combat rows from `S_sfx` in
linuxdoom-1.10's `sounds.c`, including their priorities. The fight cases
in `tests/sim.bend` cover both player weapons, monster sight and active
sounds, attacks, pain, death, gibbing, fireballs, barrels, and player
pain and death. Their expected events and ending `mrnd` values come from
replaying the corresponding calls in `p_pspr.c`, `p_enemy.c`,
`p_inter.c`, `p_mobj.c`, and `s_sound.c` over the WAD and vanilla's two
random tables. The saw trace under
`bendoom-evidence/2026-09-21/m7-09/saw` records `sawup` at tic 50,
`sawidl` from tic 65, repeated `sawful` while held against a target, and
the return to `sawidl`. The sim cases record fireball flight starts and
the stop on removal before `firxpl`.

The split-move case starts at (2025, -450) with 20 units of eastward
momentum and crosses Freedoom's special-2 line at x 2032 in the first
10-unit half. `tools/sound.nu` over vanilla's `tables.c` and Freedoom's
sector 145 sound origin gives volume 45 and separation 156 at the
crossing endpoint x 2035. The old whole-move endpoint x 2045 gives 45
and 157. Crossings now retain each submove endpoint, fire with that
listener position, and restore the final player position. The focused
case prints 45 and 156 while ending at x 2045.

The preserved Freedoom recording is
`bendoom-evidence/2026-09-21/m7-09/pcm/freedoom-trace/capture.raw`.
Chocolate Doom's trace places five pistol restarts at frames 114688,
131072, 147456, 163840, and 179200, a barrel explosion at 148480, and
the barrel removal stop at 183296. Mixing the current expanded sounds
over the isolated OPL stream at those recorded starts and stop gives
`frames 272384`, `differing 0`, `largest 0`. `tools/listen.nu compare`
reports the same zero over the 228327 frames after its lead alignment.

The code change removed the old deferred split-listener limitation.
The existing replay and movement laws still check after the crossing
record gained its endpoint. `bend PROOF.bend` prints `All terms check.`
