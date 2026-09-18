{
  description = "Bendoom: Doom, written in Bend 2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    bend-src = {
      url = "github:bendlang/bend/e6676b080f25b1bc1bf5b5b7d7a17e22f8022599";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

      perSystem = { system, lib, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg:
              lib.getName pkg == "doom1-wad";
          };
          bend = pkgs.callPackage ./nix/bend.nix { src = inputs.bend-src; };
          wads = pkgs.callPackage ./nix/wads.nix { };
          freedoom = "${wads.freedoom}/share/games/doom/freedoom1.wad";
          shareware = "${wads.doom1}/share/games/doom/doom1.wad";
          bendoom = pkgs.callPackage ./nix/bendoom.nix { inherit bend; iwad = freedoom; };
          film = pkgs.callPackage ./nix/film.nix { inherit bend; iwad = freedoom; };
        in {
          packages = {
            inherit bend bendoom film;
            default = bendoom;
            doom1-wad = wads.doom1;
            bendoom-shareware = bendoom.override { iwad = shareware; };
            film-shareware = film.override { iwad = shareware; };
          };

          checks = {
            proof = pkgs.callPackage ./nix/proof.nix { inherit bend; };
            tests = pkgs.callPackage ./nix/tests.nix { inherit bend; };
          };

          apps.default = {
            type = "app";
            program = "${bendoom}/bin/bendoom";
          };

          devShells.default = pkgs.mkShell {
            packages = [
              bend
              pkgs.bun
              pkgs.llvmPackages_19.clang
              pkgs.jujutsu
              # tools/oracle.nu diffs our frames against Chocolate Doom's,
              # which it runs on a headless X server.
              pkgs.chocolate-doom
              pkgs.xorg.xorgserver
              pkgs.xdotool
            ];
            buildInputs = [ pkgs.libx11 pkgs.alsa-lib ];
            BENDOOM_IWAD = freedoom;
            BEND_NO_TELEMETRY = "1";
          };
        };
    };
}
