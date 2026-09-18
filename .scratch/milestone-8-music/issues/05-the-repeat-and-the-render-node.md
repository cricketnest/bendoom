# 05: The repeat and the render node

**What to build:** `music.bend` renders a WAD's song to two files and the build graph runs it. The render runs the song looping and cuts at the sample where the player's restart callback runs, 5 ms after the last track ends. The first file holds the first pass and the second file the second pass, raw signed 16-bit little-endian mono at 44100 Hz, written with `Bytes.write` chunk by chunk. `nix/music.nix` builds and runs it for one IWAD, and the render's cost is measured.

**Blocked by:** 03 (Freedoom's first pass matches), and the demo recording work on main for `Bytes.write`

**Status:** ready-for-agent

- [ ] The second pass starts with the tails of the first pass's last notes, and both passes equal the capture after the idle lead
- [ ] The render never holds a whole pass in memory
- [ ] The music is a function of the IWAD in the flake; the shareware render is built only with the shareware packages
- [ ] Two builds of the Freedoom node give identical files
- [ ] The Freedoom node's build time and the render's samples a second against real time are recorded
