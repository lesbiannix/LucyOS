{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      binutilsStage = import ./pkgs/by-name/bi/binutils/crossToolchain.nix { pkgs = pkgs; };
      gccStage = import ./pkgs/by-name/gc/gcc/pass_one.nix {
        pkgs = pkgs;
        binutils = binutilsStage;
      };
    in
    {
      packages.${system}.crossToolchain = {
        binutils = binutilsStage;
        gcc = gccStage;
      };
    };
}
