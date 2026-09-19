# 07: The game sounds

**What to build:** The game plays its sounds. Each frame the loop hands the sounds of the tics it just ran to the channels, and the mixer writes song and sounds together. A sound starts at the first frame of the next write after its tic. The queue level is set as low as the frame rate allows, so that the delay comes close to vanilla's.

**Blocked by:** 06 (Eight channels by priority)

**Status:** ready-for-agent

- [ ] The state holds one tic's sounds, and the loop replays a frame's tics in one call, so the loop gathers each tic's sounds as it runs them and passes over an ended level, whose state keeps its last live tic's sounds (ticket 01's note)
- [ ] Doors, the lift, switches, pickups, the use grunt and the exit are heard in the window on both packages
- [ ] The ticket measures the lowest queue level with no dry frame at 35 frames a second on the dev machine, sets it there, and records the level, the delay it gives against Chocolate Doom's 1024 frames, and the measurement
- [ ] With no sound device the game prints one line and plays silent; with no sounds directory it prints one line and plays the music alone
- [ ] The window bench runs a script that keeps several channels busy over the music and reports frames a second and dry frames
- [ ] The game test still runs with no device
