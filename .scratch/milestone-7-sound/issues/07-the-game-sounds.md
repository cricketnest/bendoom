# 07: The game sounds

**What to build:** The game plays its sounds. Each frame the loop hands the sounds of the tics it just ran to the channels, and the mixer writes song and sounds together. A sound starts at the first frame of the next write after its tic. The queue level is set as low as the frame rate allows, so that the delay comes close to vanilla's.

**Blocked by:** 06 (Eight channels by priority)

**Status:** resolved

- [x] The state holds one tic's sounds, and the loop replays a frame's tics in one call, so the loop gathers each tic's sounds as it runs them and passes over an ended level, whose state keeps its last live tic's sounds (ticket 01's note)
- [x] Doors, the lift, switches, pickups, the use grunt and the exit are heard in the window on both packages
- [x] The ticket measures the lowest queue level with no dry frame at 35 frames a second on the dev machine, sets it there, and records the level, the delay it gives against Chocolate Doom's 1024 frames, and the measurement
- [x] With no sound device the game prints one line and plays silent; with no sounds directory it prints one line and plays the music alone
- [x] The window bench runs a script that keeps several channels busy over the music and reports frames a second and dry frames
- [x] The game test still runs with no device

## Comments

21 Sep 2026. The maintainer played both packages in the window to the exit and heard the doors, the lift, the switches, the pickups, the use grunt and the exit over the music.

20 Sep 2026, on an x86_64 benchmark host on AC power, balanced profile, with sibling worktrees building beside it.

### What was built

- `Game.tics` replaces the `Sim.replay` call the frame made: it runs the frame's tics one at a time and gathers each tic's sounds, since the state holds one tic's only. `Game.gathered` passes over a tic whose state had already ended, whose sounds are the last live tic's, which is ticket 01's note. `Sim.replay` itself is untouched, for the film, the tests and the script the game starts from.
- `Game.started` hands the gathered events to `Stream.hear` before the frame's write, and `Game.tick` now runs the frame's events and tics first and tops the device up after them, so a sound is in the write that follows its own tic instead of the next frame's. The write is still one a frame, so the gap between top-ups is what it was.
- Nothing else in the loop moved. The state, the demo and the keys take the same path.

### The queue level and the delay

`Stream.top` is 2304 frames, 52.2 ms at 44100 Hz, against Chocolate Doom's 1024 frames of 23.2 ms. A sound waits from the tic that started it until the next write, and the write is at most that far ahead of the device.

The closing bench used the first-fight route for its first 420 tics, then
rendered 600 frames at the position `(2037, -461)`, facing 90 degrees,
with health 85 and the monsters awake. Music and effects went through a
PipeWire null sink at the real 44100 Hz device rate; its monitor showed
audio while no hardware output was linked. The machine was an x86_64 benchmark host on AC power with the balanced profile and
`balance_performance` energy preference.

The window bench, built from `bench/window.bend` and run on an Xvfb screen so that no window opened on the desktop, with the door script from the bench's own header (walk to the first door, use it, watch it open, wait and close):

| queue | run | frames a second | dry frames |
| --- | --- | --- | --- |
| 3072 | door script | 57 | 1 |
| 2048 | door script | 58 | 1 |
| 2048 | door script again | 58 | 1 |
| 2048 | WALK=1, no script | 55 | 1 |
| 1024 | first fight, run 1 | 53 | 156 |
| 1024 | first fight, run 2 | 53 | 158 |
| 1536 | first fight, runs 1–3 | 53 | 1, 1, 4 |
| 2048 | first fight, warm runs 1–4 | 52–55 | 1 each |
| 2304 | first fight, runs 1–3 | 53–54 | 1 each |
| 2304 | final combat integration, runs 1–6 | 51–55 | 1 each |

The one dry frame is the first of a passing run, where nothing has been
written yet. A cold first activation at 2048 reported three dry frames;
the four warm repeats each reported only the initial one. At 1536 one of
three runs dried three additional times, while 1024 dried throughout.
All three 2304 runs, including the first execution of its new binary,
reported only the initial empty check. Thus 2304 is the lowest measured
level that also holds cold. After the final melee and damage integration,
six more runs—including the final binary's first execution—each reported
only the initial empty check. Their 51–55 FPS range remains well above the
35 FPS target under Xvfb software rendering.

The sounds the door script keeps busy are the door's own, from its sector: DSDOROPN at the use and DSDORCLS when the wait runs out, one channel at a time with the song under them. E1M1 near the start has no place where eight play at once; a script that fills the table would want milestone 6's monsters.

### The empty cases

Each run of the bench on Xvfb, with the named thing taken away:

    == no sounds directory ==
    bendoom: BENDOOM_SOUNDS names no sounds; playing the music alone
    47 frames a second (600 frames in 12573 ms), the device's queue empty on 1 of them
    == no render ==
    bendoom: BENDOOM_MUSIC names no render; playing the sounds alone
    49 frames a second (600 frames in 12099 ms), the device's queue empty on 1 of them
    == no render and no sounds ==
    bendoom: BENDOOM_SOUNDS names no sounds; playing the music alone
    bendoom: BENDOOM_MUSIC names no render; playing silent
    49 frames a second (600 frames in 12170 ms), silent
    == no device ==
    bendoom: no sound device; playing silent
    46 frames a second (600 frames in 12951 ms), silent

The device was refused with `ALSA_CONFIG_PATH=/nonexistent`. The two lines of the third case are one a fact, and the game plays on with the device let go. Those four runs went side by side with the proof and the tests, which is why they are slower than the table above.

### Trade-offs

- The frame's write moved after its tics. A frame that quits still writes, which costs one buffer at the end of the game and keeps the loop one path.
- `Game.tics` walks the commands itself rather than `Sim.replay` growing a second answer, so every other caller of the replay is untouched and the merge with the sim's branch stays small.
