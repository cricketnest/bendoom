# bend builds doom.bend with the stdenv's clang, which on Linux finds X11
# and ALSA through buildInputs; on macOS Bend uses Apple's frameworks.
# BENDOOM_IWAD in the environment overrides the wrapper's default. The
# game makes no parallel call, and the runtime's idle workers cost it
# three frames a second, so it runs on one thread. On Linux the song it
# plays is the render of its own IWAD, so an override of the IWAD carries
# its music along, and ALSA_PLUGIN_DIR names the plugins the host's ALSA
# default may need; without them the device will not open and the game
# plays silent. On macOS it plays silent for now.
{ lib, llvmPackages_19, makeWrapper, bend, libx11, alsa-lib, alsa-plugins, iwad, music }:

llvmPackages_19.stdenv.mkDerivation {
  pname = "bendoom";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      ../doom.bend
      ../src
      ../LAWS.bend
      ../PROOF.bend
    ];
  };

  nativeBuildInputs = [ bend makeWrapper ];
  buildInputs = lib.optionals llvmPackages_19.stdenv.hostPlatform.isLinux [ libx11 alsa-lib ];

  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    bend doom.bend -o bendoom
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 bendoom $out/libexec/bendoom
    makeWrapper $out/libexec/bendoom $out/bin/bendoom \
      --set-default BENDOOM_IWAD ${lib.escapeShellArg iwad} \
      ${lib.optionalString llvmPackages_19.stdenv.hostPlatform.isLinux
        "--set-default BENDOOM_MUSIC ${music iwad} --set-default ALSA_PLUGIN_DIR ${alsa-plugins}"} \
      --add-flags "--threads 1"
    runHook postInstall
  '';

  meta = {
    description = "Doom, written in Bend 2";
    license = lib.licenses.gpl2Plus;
    mainProgram = "bendoom";
    platforms = lib.platforms.unix;
  };
}
