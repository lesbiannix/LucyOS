{
  description = "LucyOS cross-toolchain flake (nixpkgs-style)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Import stages
      binutilsStage = import ./pkgs/by-name/bi/binutils/crossToolchain.nix { pkgs = pkgs; };
      gccStage = import ./pkgs/by-name/gc/gcc/pass_one.nix {
        pkgs = pkgs;
        binutils = binutilsStage;
      };
    in
    {
      packages.${system} = {
        # Cross-toolchain as a set of derivations
        crossToolchain = {
          binutils = binutilsStage;
          gcc = gccStage;
        };
      };

      checks.${system} = {
        # Build binutils
        binutils = pkgs.runCommand "binutils-check" { } ''
          echo "Checking crossToolchain/binutils..."
          # Simply depend on the derivation
          ${binutilsStage}
          echo "binutils check succeeded"
        '';

        # Build gcc (depends on binutils via normal derivation)
        gcc = pkgs.runCommand "gcc-check" { } ''
          echo "Checking crossToolchain/gcc..."
          ${gccStage}
          echo "gcc check succeeded"
        '';

        # Optional: Nix formatting/lint
        nixfmt = pkgs.runCommand "nixfmt-check" { } ''
          echo "Checking Nix formatting..."
          nix fmt --check ./pkgs || exit 1
          echo "Formatting OK"
        '';
      };
    };
}
