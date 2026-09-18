# 11: Animations and scrolling walls

**What to build:** The water and the screens move, and the shareware map's walls scroll. Both are functions of the clock, not state. The animation list is vanilla's, from p_spec.c: an animation exists when the WAD holds its first and last name, and its frames are the flats or textures between them in WAD order, as vanilla counts them. The loader composes every frame of every animation that holds a name the map uses. The renderer translates a flat or texture number through the list at 8 tics a frame, with the phase P_UpdateSpecials would have set on the last tic run: before the first tic the map's own frame shows, and after n tics the phase comes from n less one. A side on a line with special 48 draws with its column offset advanced by one unit per tic run. The oracle tool stops zeroing special 48, and its rest script idles only until the pistol is up.

**Blocked by:** 02 (The oracle plays a demo), 03 (One state the tic maps)

**Status:** ready-for-agent

- [ ] The animation list is taken from linuxdoom's source; which of its animations each WAD holds, and which E1M1 touches, is read out of the WADs in nushell first and recorded in the comments
- [ ] Closed laws pin the translation: the frame at tics 0, 1, 8, 9 and one full cycle on
- [ ] The render test's frames at tic 0 keep their hashes; it gains a water frame at a tic that shows another frame of the cycle
- [ ] The oracle reports zero at every rest position with the shorter idle, and at the new frame; the 97-tic idle and its explanation are deleted from the tool
- [ ] The oracle compares a shareware frame facing a scrolling wall at two tics, counts recorded, target zero
- [ ] The tool's header comment no longer says Bendoom reads no specials or does not animate
- [ ] The frame rate is measured before and after the translation lookup and recorded; both lanes pass; the flake check stays green
