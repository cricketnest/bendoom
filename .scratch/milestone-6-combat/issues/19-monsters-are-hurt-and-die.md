# 19: Monsters are hurt and die

**What to build:** Monsters take damage as vanilla's do. A hurt monster flinches by its pain chance, a monster at zero health plays its death frames and leaves a corpse the player can walk over, and damage past its spawn health gibs it. Each death raises the kill count.

**Blocked by:** 06 (The exit leads to the intermission), 13 (Bullets hurt things and barrels explode), 16 (A woken monster chases)

**Status:** ready-for-agent

- [ ] The monster side of `P_DamageMobj`: pain chance, reaction time, waking a sleeping monster, and the threshold
- [ ] `P_KillMobj` for monsters: the flags, the quartered height, the gib test, `A_Scream`, `A_XScream`, `A_Fall` and `A_Pain`
- [ ] The kill count rises, and the intermission shows it
- [ ] Sim cases: a zombieman killed by pistol shots, an imp gibbed by a barrel, a monster flinching mid-attack, with health, states and the random index from a replay of the source
- [ ] Render cases: death frames and a corpse at zero differing pixels
- [ ] A closed law pins the gib threshold
