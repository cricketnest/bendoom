# The game and its launcher. On Linux doom.bend links X11 and ALSA; on
# macOS Bend uses Apple's frameworks. BENDOOM_IWAD in the environment
# overrides the launcher's default. The game makes no parallel call, and
# the runtime's idle workers cost it three frames a second, so it runs on
# one thread. The song and the sounds it plays are the render and the
# expansion of its own IWAD, so an override of the IWAD carries both
# along. On Linux, ALSA_PLUGIN_DIR names the plugins the host's ALSA
# default may need; without them the device will not open and the game
# plays silent. The game records a
# demo as hex text, so under RECORD it writes a file beside the demo,
# which becomes the demo once the game is over, Ctrl+C included.
{ lib, stdenv, callPackage, writeShellApplication, coreutils, bend, libx11, alsa-lib, alsa-plugins, iwad
, music, sounds }:

let
  linux = stdenv.hostPlatform.isLinux;
  game = callPackage ./program.nix {
    inherit bend;
    pname = "bendoom-game";
    root = ../doom.bend;
    sources = [ ../src ];
    buildInputs = lib.optionals linux [ libx11 alsa-lib ];
  };
in
writeShellApplication {
  name = "bendoom";
  runtimeInputs = [ coreutils ];
  text = ''
    export BENDOOM_IWAD=''${BENDOOM_IWAD-${lib.escapeShellArg iwad}}
    export BENDOOM_MUSIC=''${BENDOOM_MUSIC-${music iwad}}
    export BENDOOM_SOUNDS=''${BENDOOM_SOUNDS-${sounds iwad}}
    ${lib.optionalString linux ''
      export ALSA_PLUGIN_DIR=''${ALSA_PLUGIN_DIR-${alsa-plugins}}
    ''}
    if [ -v RECORD ]; then
      demo=$RECORD
      RECORD=$(mktemp "$demo.XXXXXX")
      trap 'basenc --base16 -d "$RECORD" > "$demo"; rm "$RECORD"' EXIT
    fi
    ${lib.getExe game} --threads 1 "$@"
  '';
  meta = {
    description = "Doom, written in Bend 2";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
  };
}
