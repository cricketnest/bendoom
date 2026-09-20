# 19: Monsters are hurt and die

**What to build:** Monsters take damage as vanilla's do. A hurt monster flinches by its pain chance, a monster at zero health plays its death frames and leaves a corpse the player can walk over, and damage past its spawn health gibs it. Each death raises the kill count.

**Blocked by:** 06 (The exit leads to the intermission), 13 (Bullets hurt things and barrels explode), 16 (A woken monster chases)

**Status:** ready-for-human

- [x] The monster side of `P_DamageMobj`: pain chance, reaction time, waking a sleeping monster, and the threshold
- [x] `P_KillMobj` for monsters: the flags, the quartered height, the gib test, `A_Scream`, `A_XScream`, `A_Fall` and `A_Pain`
- [ ] The kill count rises, and the intermission shows it
- [ ] Sim cases: a zombieman killed by pistol shots, an imp gibbed by a barrel, a monster flinching mid-attack, with health, states and the random index from a replay of the source
- [ ] Render cases: death frames and a corpse at zero differing pixels
- [ ] A closed law pins the gib threshold

## Comments

This ticket's damage-and-death half was cut with ticket 13, in the same pass and the same commits; the rest waits on the tickets it is blocked by. What the two boxes above cover:

- Pain chance, reaction time and the threshold are `Sim.pain.thing` and `Sim.awake` in `src/sim.bend`. The pain roll draws whatever the chance, as C evaluates `P_Random` before it tests it, so a barrel's every wound spends a draw. `reactiontime` is cleared on every blow. A thing with no threshold, hurt by something that is neither nobody nor itself, turns on that source and keeps it for `BASETHRESHOLD`'s hundred tics; one still standing in its spawn state enters its see state with it, which is ticket 15's run rows.
- `P_KillMobj` is `Sim.kill.thing`: it clears `MF_SHOOTABLE`, `MF_FLOAT` and `MF_SKULLFLY`, restores gravity, sets `MF_CORPSE` and `MF_DROPOFF`, quarters the height, picks the gib death where the health went past the negation of the type's spawn health and the type has one, and takes `P_Random()&3` off the death state's tics, never under one. The flags and the height live in the thing's own vector, so `Sim.body.of` answers them and a corpse is at once no longer shootable and, once `A_Fall` has run, no longer solid: the player walks over it and a later bullet flies past it. The sim case shows exactly that, a fourth shot passing the corpse to leave a puff on the wall.
- `A_Pain`, `A_Scream`, `A_XScream` and `A_Fall` are `Sim.thing.acted`. `A_Scream` keeps vanilla's switch: the three former-human death sounds and the two imp ones are groups it draws one of, and the demon's and the barrel's are sounded as they stand.
- The sim case in `tests/sim.bend` is a zombieman, record 265, killed by pistol shots from 80 units east: it bleeds at each hit, rolls its pain, enters `S_POSS_PAIN` (row 121), and the last shot sends it through `S_POSS_DIE1` (row 123) to the corpse it rests in at row 127. `S_POSS_DIE2` screams `DSPODTH2`, which is the group's draw.

### Deferred to the later pass

- The kill count and the intermission that shows it, which belong to ticket 06's parked work.
- The remaining sim cases: an imp gibbed by a barrel, and a monster flinching mid-attack, which needs the attacks of tickets 17 and 18.
- The render cases: death frames and a corpse at zero differing pixels. The sprite load carries the death rows but not the pain frame or the gib frames; ticket 13's comment has the measurement and the reason.
- The closed law pinning the gib threshold.

### What is open

A monster hurt in its idle state enters its see state, and one hurt afterwards returns from its pain rows to its see state, both of which are ticket 15's run rows; the chase itself is ticket 16's, so a hurt monster runs on the spot. A monster's pain frame has no sprite loaded, so it shows nothing for its pain tics; ticket 13's comment says why and what it costs.
