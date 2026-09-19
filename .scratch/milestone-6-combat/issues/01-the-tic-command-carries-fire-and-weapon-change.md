# 01: The tic command carries fire and weapon change

**What to build:** Ctrl and the keys 1 to 3 reach the tic command as vanilla's attack bit and weapon-change bits, laid out as the demo's buttons byte. The demo recorder writes the byte, the demo reader returns it, and the oracle's script format carries it, so one script drives Bendoom and Chocolate Doom alike. Nothing fires yet.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The command holds attack and the weapon change as `G_BuildTiccmd` builds them from held keys, including its order of preference among held number keys
- [ ] A recorded demo carries the bits, and Chocolate Doom plays it: the ticket records a demo of held Ctrl and a press of 1 replayed there, with the pistol seen firing and lowering
- [ ] The oracle's and the frame dump's script runs gain the buttons, and every existing script still parses
- [ ] The demo test covers the new bits on both lanes, with bytes worked by hand from `G_WriteDemoTiccmd`
- [ ] The use bit's handling is folded into the buttons, not kept as a parallel field
