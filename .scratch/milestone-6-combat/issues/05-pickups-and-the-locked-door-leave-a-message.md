# 05: Pickups and the locked door leave a message

**What to build:** Vanilla's heads-up message line. A pickup or a locked door's refusal sets one message, drawn in the WAD's font at the top of the view and held for 4 seconds. The strings are vanilla's English ones.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Each pickup type the two E1M1s hold sets its vanilla string, and the blue door's refusal sets its own
- [ ] A new message replaces the old; the line clears after `HU_MSGTIMEOUT`
- [ ] Glyphs come from the WAD's font lumps, spaced as `HUlib_drawTextLine` spaces them
- [ ] The sim test prints the message and its tics left on pickup cases
- [ ] Render cases compare message pixels with the font's patches read from the WAD in nushell, since Chocolate Doom's message ticker runs on under the oracle's pause; the oracle keeps messages off
