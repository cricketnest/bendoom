# 05: Animated and full-bright things keep vanilla time

**What to build:** Animated bonuses and decorations run their vanilla state sequences in the replay. Spawning things consumes the random table in the same order as vanilla, including the initial state duration, before the level's light thinkers start. Each tic advances finite states and full-bright frames use the first colormap. Static states avoid the animation path.

**Blocked by:** 02 (The non-monster population spawns)

**Status:** ready-for-agent

- [ ] Reachable non-monster state rows carry sprite, frame, full-bright, duration and next state from vanilla
- [ ] Spawn consumes P_SpawnMobj and P_SpawnMapThing random calls in THINGS order
- [ ] The initial state duration and every later transition match vanilla to the tic
- [ ] Static minus-one states do not take an animation branch each tic
- [ ] Thing thinkers run in vanilla order relative to lights, movers and the clock
- [ ] The random index and milestone 4 blink expectations are updated from vanilla's populated spawn order, not copied from current output
- [ ] Full-bright frames ignore sector darkness while ordinary frames keep sprite lighting
- [ ] Closed laws pin spawn phase and at least one complete animated-item cycle
- [ ] Two oracle frames on different animation states report zero differing sprite pixels
- [ ] Both lanes and the flake check pass

