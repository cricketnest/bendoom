# 17: Zombiemen and shotgun guys shoot

**What to build:** The former humans attack. A chasing zombieman or shotgun guy decides to fire by vanilla's missile range check, faces the player, and shoots hitscan with vanilla's spread and damage, one bullet or three.

**Blocked by:** 02 (One traversal finds what a ray meets), 09 (The nukage hurts and the player dies), 16 (A woken monster chases)

**Status:** ready-for-human

- [x] `A_Chase`'s attack half, `P_CheckMissileRange`, `A_PosAttack` and `A_SPosAttack`, with reaction time and the just-attacked flag
- [x] The player takes the damage through armour, and the attacker is recorded
- [x] Their attack sounds start where vanilla's do
- [ ] Sim cases on Freedoom: each type's first shot at the player, hit and miss, with tics, health and the random index from a replay of the source
- [ ] Render cases: each type mid-attack at zero differing pixels

## Comments

### What was built

- `A_Chase`'s attack half, in `Sim.chase.hit` and `Sim.chase.fire`: a thing that attacked last tic clears MF_JUSTATTACKED and picks a new direction instead of attacking again; a type with a missile state that is not still walking out its move count runs `P_CheckMissileRange`, and one that passes it enters that state and is marked as having just attacked.
- `P_CheckMissileRange` is `Sim.chase.range`: the target has to be in sight, a thing just hit fires back at once and forgets the blow, one still inside its reaction time of 8 holds its fire, and otherwise the whole units between them, 64 off for the range and 128 more for having no melee attack, held at 200, have to beat a draw. The draw is signed, so a thing close enough for the count to go negative always fires.
- `A_PosAttack` is `Sim.posattack` and `A_SPosAttack` is `Sim.sposattack`, sharing `Sim.bullet`, which is one bullet: the spread of a `P_SubRandom` turn shifted 20, the damage of a draw, `((P_Random()%5)+1)*3`, and `P_LineAttack`. The aim is `P_AimLineAttack` once, straight ahead, not the player's `P_BulletSlope` with its two retries. The zombieman sounds sfx_pistol after it aims and before it draws; the shotgun guy sounds sfx_shotgn before it even turns, as vanilla's order has it, and fires three bullets off one aim.
- Rows 184 to 189 are S_POSS_ATK1 to 3 and S_SPOS_ATK1 to 3, `A_FaceTarget` then the attack then a row back to the run. `H.Thing.missile(kind)` names the first of each.
- The damage is not this ticket's code: `P_LineAttack` is the player's own, and the merged damage pass's `PTR_ShootTraverse` calls `P_DamageMobj(th, shootthing, shootthing, damage)` on whatever it hits, player or monster, so a monster's bullet goes through the same one function and the armour, the damage count and the attacker are all the player's own branch of it.
- `src/sound.bend` gains sfx_shotgn (2, priority 64) and the three idle calls sfx_posact, sfx_bgact and sfx_dmact (75 to 77, priority 120), from `sounds.c`. All four lumps are in both WADs.

### Where each expected value came from

- Vanilla's source: `p_enemy.c`'s `A_Chase`, `P_CheckMissileRange`, `A_FaceTarget`, `A_PosAttack` and `A_SPosAttack`; `p_map.c`'s `PTR_ShootTraverse` and `P_AimLineAttack`; `info.c`'s S_POSS_ATK1 to 3 and S_SPOS_ATK1 to 3, with S_SPOS_ATK2's frame 32773, which is frame 5 full bright; `sounds.c` for the numbers and priorities.
- The lumps were read from both WADs in nushell before the rows were written.

### The sim cases

Two runs, each holding the player still while the monster works:

- **the zombieman shoots**: zombieman 177 wakes on tic 15, walks south-west at a player at (488, 256), and on tic 43 enters row 121 (now 184), where `A_FaceTarget` turns it from 225 degrees to 190.074, the angle to the player. Row 185's `A_PosAttack` sounds DSPISTOL on tic 53. The bullet misses; the player stays at 100.
- **the shotgun guy shoots**: shotgun guy 96 wakes on tic 6, walks to (240, 1928), enters row 187 on tic 51 and turns to 202.609 degrees, and row 188's `A_SPosAttack` sounds DSSHOTGN on tic 61. The player drops from 100 to 76 and DSPLPAIN sounds on tic 64.

### Deferred to the later pass

- **Every number in those two cases is a regression pin.** The tics, the damage and the random index come from the code, not from a replay of vanilla over the random table. The hit and the miss are both there, but which of the three shotgun pellets hit, and for how much, is not checked against anything outside.
- **There is no render case of a monster mid-attack.** The nearest evidence is that the two oracle frames where a monster's bullet reaches the player, `key before` and `key after`, keep 8 and 11 differing pixels in a box three wide and five tall at the middle of the view; both carry a damage-flash palette. That box is where the bullet ends, so something of what a bullet that hits the player leaves behind is not right, and it is the one thing tonight's oracle can still see.
- **The imp's and the demon's attacks are ticket 18's.** `H.Thing.melee(kind)` answers 0 for every type and `H.Thing.missile(kind)` answers 0 for the imp and the demon; those two answers are the whole guard. Ticket 18 gives them their rows and adds `A_Chase`'s melee branch, which goes between the just-attacked test in `Sim.chase.hit` and the missile test in `Sim.chase.fire`, with `P_CheckMeleeRange` and the attack sound `H.Thing.attacksound` already reads. Until then the demon closes to melee range and stands there, which is what the head-on oracle frame at 20 tics measures.
- **The shareware WAD was not run.** Only Freedoom.
