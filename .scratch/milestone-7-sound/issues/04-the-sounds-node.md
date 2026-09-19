# 04: The sounds node

**What to build:** The flake builds every sound of a WAD once. A Bend program beside the music render writes one raw file for each sound in the sound table: signed 16-bit mono at 44100 Hz. A build node beside the music's runs it per WAD, and the launcher, the dev shell and the tests find the directory as they find the music.

**Blocked by:** 01 (The sim reports its sounds), 03 (One sound expands as Chocolate Doom's)

**Status:** ready-for-agent

- [ ] One node per WAD expands the sounds the sound table names, each file named by its lump, with no binary download; a table sound at a rate the expansion does not serve fails the build
- [ ] The packages that take an IWAD derive their sounds from it, so an override of the IWAD carries its sounds along, as it carries the music
- [ ] The launcher defaults the sounds directory beside the IWAD and the music; the dev shell and the tests derivation get Freedoom's
- [ ] The flake check builds Freedoom's sounds alone and never needs the unfree WAD
- [ ] The ticket records the node's build time and its output size for both WADs
- [ ] The music-from-the-wad ticket is updated to say it now covers sounds too
