# bend builds doom.bend with the stdenv's clang, which finds X11 and ALSA
# through buildInputs; BENDOOM_IWAD in the environment overrides the
# wrapper's default. The game makes no parallel call, and the runtime's
# idle workers cost it three frames a second, so it runs on one thread.
# The song it plays is the render of its own IWAD, so an override of the
# IWAD carries its music along.
{ lib, llvmPackages_19, makeWrapper, bend, libx11, alsa-lib, iwad, music }:

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
  buildInputs = [ libx11 alsa-lib ];

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
      --set-default BENDOOM_MUSIC ${music iwad} \
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
