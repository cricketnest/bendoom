# 07: The film carries the music

**What to build:** `film` muxes its IWAD's render under the video: the first pass, then the second repeated, cut at the video's length, starting at frame zero, as the game starts the song on its first frame.

**Blocked by:** 05 (The repeat and the render node), and the demo recording work on main

**Status:** ready-for-agent

- [ ] `film` and `film-shareware` take the music of their own IWAD
- [ ] The audio starts at the first frame and ends with the last, checked with ffprobe on a filmed demo
- [ ] A demo longer than one pass shows the repeat in the audio with no gap
- [ ] The README's recording section says the video has the music
