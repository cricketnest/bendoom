# 09: The nukage hurts and the player dies

**What to build:** The player can be hurt and can die. Standing in a special 7 sector takes 5 health every 32 tics. Damage passes through armour, a third absorbed by green and a half by blue. At zero health the view sinks to the floor and turns to the killer, and a press of Space loads the level again with a fresh inventory.

**Blocked by:** milestone 7's 01 (The sim reports its sounds)

**Status:** ready-for-agent

- [ ] `P_DamageMobj`'s player branch: armour absorption, the damage count, the attacker, thrust when there is an inflictor, and health as a signed quantity
- [ ] `P_PlayerInSpecialSector` for special 7, only while the player stands on the floor
- [ ] `P_DeathThink`: the view falls to 6 units, turns to the attacker, the weapon lowers if one shows, and use restarts through the same path as the restart after the exit
- [ ] Pickups refuse a dead toucher
- [ ] The pain and death sounds start where vanilla's do
- [ ] Sim cases: nukage tics, green and blue armour absorbing, death in the nukage and the restart, with values worked from the source
- [ ] Closed laws pin absorption at both armour types; replay composition still holds
- [ ] A render case shows the dead view at zero differing pixels
