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
  passthru = { inherit game iwad alsa-plugins; music = music iwad; sounds = sounds iwad; };
  runtimeInputs = [ coreutils ];
  text = ''
    iwad=${lib.escapeShellArg iwad}
    music=${music iwad}
    sounds=${sounds iwad}
    ${lib.optionalString linux ''
      export ALSA_PLUGIN_DIR=''${ALSA_PLUGIN_DIR-${alsa-plugins}}
    ''}
    run_game() { ${lib.getExe game} "$@"; }
    decode_recording() { basenc --base16 -d "$1"; }
    ${lib.readFile ./launch.sh}
  '';
  meta = {
    description = "Doom, written in Bend 2";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
  };
}
