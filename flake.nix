{
  description = "Bendoom: Doom, written in Bend 2";

  nixConfig = {
    extra-substituters = [ "https://bendoom.cachix.org" ];
    extra-trusted-public-keys = [ "bendoom.cachix.org-1:CQba0LK2+g9Kb7ybgQbfm2dtrZdU4gul5FV5sqvPaUU=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    bend-src = {
      url = "https://github.com/eliesgalvira/bendoom/releases/download/bend-2.0.22-source/bend-94ee9ba40043643df648b13fc5638b065a37cb4e.tar.gz";
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
          alsa-plugins = pkgs.callPackage ./nix/audio-plugins.nix { };
          bendoom = pkgs.callPackage ./nix/bendoom.nix { inherit bend music sounds alsa-plugins; iwad = shareware; };
          film = pkgs.callPackage ./nix/film.nix { inherit bend music sounds; iwad = shareware; };
          portable = package: variant: pkgs.callPackage ./nix/portable.nix { bendoom = package; inherit variant; };
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
            portable = portable bendoom "shareware";
            portable-freedoom = portable (bendoom.override { iwad = freedoom; }) "freedoom";
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
            BENDOOM_MUSIC = music freedoom;
            BENDOOM_SOUNDS = sounds freedoom;
          } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            ALSA_PLUGIN_DIR = alsa-plugins;
          });
        };
    };
}
