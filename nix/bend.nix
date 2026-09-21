# Bend is a TypeScript program bun runs as is; clang 19 serves its C
# backend (14 suffices on the CPU, 19 for the GPU lane). The patch
# paints the window by walking the frame's tree once, where the pin
# walks it from the root for every pixel
# (.scratch/upstream-bend/issues/01-slow-window-fill.md).
{ lib, stdenvNoCC, makeWrapper, bun, llvmPackages_19, src }:

stdenvNoCC.mkDerivation {
  pname = "bend";
  version = "2.0.22";
  inherit src;

  patches = [ ./window-fill.patch ]
    ++ lib.optional stdenvNoCC.hostPlatform.isDarwin ./local-names.patch;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/bend $out/bin
    cp -r bend2 guide $out/share/bend/
    makeWrapper ${bun}/bin/bun $out/bin/bend \
      --add-flags "$out/share/bend/bend2/main.ts" \
      --set BEND_NO_TELEMETRY 1 \
      --set-default CC ${llvmPackages_19.clang}/bin/clang \
      --prefix PATH : ${lib.makeBinPath [ llvmPackages_19.clang ]}
    runHook postInstall
  '';

  meta = {
    description = "A fast language that blocks AI mistakes via proof";
    homepage = "https://bend-lang.com";
    license = lib.licenses.asl20;
    mainProgram = "bend";
    platforms = lib.platforms.unix;
  };
}
