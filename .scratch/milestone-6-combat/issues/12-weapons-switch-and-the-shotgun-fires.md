# 12: Weapons switch and the shotgun fires

**What to build:** The player changes weapons as vanilla does. Number keys select a weapon the player owns, the weapon lowers and the next rises, a picked-up weapon the player did not own comes up, ammo running out brings up the best weapon with ammo, and ammo picked up at zero brings back a better one. The shotgun fires seven pellets and pumps. Milestone 5's declared gap, the pistol that stays after a weapon pickup, closes.

**Blocked by:** 11 (Ctrl fires the pistol)

**Status:** ready-for-agent

- [ ] The pending weapon, `A_Lower`, `A_Raise`, `P_BringUpWeapon` and `P_CheckAmmo`'s order of preference, for the weapons the maps can give
- [ ] Keys for weapons the player can never own select nothing, and those weapons have no state rows
- [ ] `P_GiveWeapon` sets the pending weapon, and `P_GiveAmmo`'s switch follows vanilla's table
- [ ] `A_FireShotgun` with its seven spread pellets and the shotgun's states and sound
- [ ] The status bar's ready-ammo number follows the ready weapon
- [ ] Sim cases: a switch by key, the shotgun picked up on the shareware route by literal state or on Freedoom by a literal drop, a blast, the last shell and the switch away from it
- [ ] Render cases: the weapon mid-switch and the shotgun at rest and firing, at zero differing pixels; oracle frames after a weapon pickup are fidelity cases again
- [ ] A closed law pins the weapon chosen when ammo runs out
