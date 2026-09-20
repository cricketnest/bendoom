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
          # The music and the sounds are functions of the IWAD: a package
          # that takes one gets that IWAD's song and that IWAD's sounds.
          # The packages play the shareware WAD unless named -freedoom.
          # The checks and the dev shell use Freedoom, whose values the
          # tests pin, so the flake check never needs the unfree WAD.
          render = args: iwad: pkgs.callPackage ./nix/render.nix (args // { inherit bend iwad; });
          music = render {
            pname = "bendoom-music";
            root = ./music.bend;
            sources = [
              ./src/bytes.bend ./src/fixed.bend ./src/midi.bend ./src/opl.bend
              ./src/opl_tables.bend ./src/player.bend ./src/song.bend ./src/vec.bend ./src/wad.bend
            ];
          };
          sounds = render {
            pname = "bendoom-sounds";
            root = ./sounds.bend;
            sources = [
              ./src/angle.bend ./src/bytes.bend ./src/fixed.bend ./src/sfx.bend
              ./src/sfx_taps.bend ./src/sound.bend ./src/vec.bend ./src/wad.bend
            ];
          };
          # alsa-lib loads the plugin behind the host's ALSA default from one
          # directory of its own, so on a host whose default is PipeWire or
          # PulseAudio the game needs theirs, as nixpkgs's alsa-utils does.
          alsa-plugins = pkgs.symlinkJoin {
            name = "bendoom-alsa-plugins";
            paths = map (p: "${p}/lib/alsa-lib") [ pkgs.alsa-plugins pkgs.pipewire ];
          };
          bendoom = pkgs.callPackage ./nix/bendoom.nix { inherit bend music sounds alsa-plugins; iwad = shareware; };
          film = pkgs.callPackage ./nix/film.nix { inherit bend music; iwad = shareware; };
        in {
          packages = {
            inherit bend bendoom film;
            default = bendoom;
            music = music shareware;
            sounds = sounds shareware;
            doom1-wad = wads.doom1;
            bendoom-freedoom = bendoom.override { iwad = freedoom; };
            film-freedoom = film.override { iwad = freedoom; };
            music-freedoom = music freedoom;
            sounds-freedoom = sounds freedoom;
          };

          checks = {
            proof = pkgs.callPackage ./nix/proof.nix { inherit bend; };
            tests = pkgs.callPackage ./nix/tests.nix {
              inherit bend;
              music = music freedoom;
              sounds = sounds freedoom;
            };
          };

          apps.default = {
            type = "app";
            program = "${bendoom}/bin/bendoom";
          };

          devShells.default = pkgs.mkShell ({
            packages = [
              bend
              pkgs.bun
              pkgs.llvmPackages_19.clang
              pkgs.jujutsu
              # tools/oracle.nu diffs our frames against Chocolate Doom's,
              # which it runs on a headless X server; tools/listen.nu
              # records its music and its sounds.
              pkgs.chocolate-doom
              pkgs.xorg.xorgserver
              pkgs.xdotool
            ];
            buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.libx11 pkgs.alsa-lib ];
            BENDOOM_IWAD = freedoom;
            BEND_NO_TELEMETRY = "1";
          } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            BENDOOM_MUSIC = music freedoom;
            BENDOOM_SOUNDS = sounds freedoom;
            ALSA_PLUGIN_DIR = alsa-plugins;
          });
        };
    };
}
