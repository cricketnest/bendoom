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
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }:
      let
        inherit (lib.filesystem) listFilesRecursive;
        inherit (lib.lists) filter;
        inherit (lib.strings) hasSuffix;
      in {
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];

        imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./nix);
      });
}
