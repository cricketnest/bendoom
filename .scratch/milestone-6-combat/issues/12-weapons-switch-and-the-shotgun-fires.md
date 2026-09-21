# 12: Weapons switch and the shotgun fires

**What to build:** The player changes weapons as vanilla does. Number keys select a weapon the player owns, the weapon lowers and the next rises, a picked-up weapon the player did not own comes up, ammo running out brings up the best weapon with ammo, and ammo picked up at zero brings back a better one. The shotgun fires seven pellets and pumps. Milestone 5's declared gap, the pistol that stays after a weapon pickup, closes.

**Blocked by:** 11 (Ctrl fires the pistol)

**Status:** resolved

- [x] The pending weapon, `A_Lower`, `A_Raise`, `P_BringUpWeapon` and `P_CheckAmmo`'s order of preference, for the weapons the maps can give
- [x] Keys for weapons the player can never own select nothing, and those weapons have no state rows
- [x] `P_GiveWeapon` sets the pending weapon, and `P_GiveAmmo`'s switch follows vanilla's table
- [x] `A_FireShotgun` with its seven spread pellets and the shotgun's states and sound
- [x] The status bar's ready-ammo number follows the ready weapon
- [x] Sim cases: a switch by key, the shotgun picked up on the shareware route by literal state or on Freedoom by a literal drop, a blast, the last shell and the switch away from it
- [x] Render cases: the weapon mid-switch and the shotgun at rest and firing, at zero differing pixels; oracle frames after a weapon pickup are fidelity cases again
- [x] A closed law pins the weapon chosen when ammo runs out

## Comments

- Vanilla sources were `p_pspr.c` lines 124-428 and 675-696 for switching, lowering, raising, ammo checks and seven shotgun pellets; `p_inter.c` lines 59-210 for ammo and weapon grants; `info.c` lines 146-159 for the shotgun and flash rows; and `st_stuff.c` for ready ammo and weapon ownership widgets.
- The shotgun uses rows 201 through 214. Rows 190 through 200 remain the imp, demon and fireball rows from ticket 18. `Thing.weapon` is the shared table seam, and `Inventory.ready`, `Inventory.pending`, `Inventory.weaponstate`, `Inventory.owns` and `Inventory.want` expose the switching state without widening `Inventory`.
- The sim cases cover a literal placed shotgun grant, key selection, lowering, raising, a blast, seven pellets and random consumption, the last shell and the automatic switch to the pistol. Both native and Bun matched these cases before the combined combat merge; Bun matched after it. `PROOF.bend` completed successfully after the merge and proves `empty_shotgun_picks_pistol`.
- The Freedoom route at `824 896 0` reported `differing 0` for scripts ending after 8 idle tics of lowering, 40 idle tics at rest, and 40 idle tics plus fire and 3 idle tics. The shareware route at `1056 -3616 90`, with record 6 rewritten to a shotgun at `1056 -3576`, reported `differing 0` for the same three phases.
- The shareware comparison exposed five pixels left by `STlib_updateMultIcon`: vanilla restores the old gray shotgun-number rectangle from `STBAR` before drawing the yellow number. The bar now preserves that behavior, and both WADs compare at zero pixels.
- Unsupported weapon keys add no rows and leave the pending weapon unchanged. Ticket 14 can extend `Thing.weapon`, `Inventory.weaponbit`, the key selector and the ammo preference table for the fist and chainsaw.
