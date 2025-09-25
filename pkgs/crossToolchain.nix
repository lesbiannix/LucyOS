{
  pkgs,
  binutilsStage,
  gccStage,
}:

pkgs.stdenv.mkDerivation {
  pname = "crossToolchain";
  version = "0.1";

  outputs = [
    "out"
    "binutils"
    "gcc"
  ];

  # Skip unnecessary phases
  unpackPhase = ":";
  buildPhase = ":";

  installPhase = ''
    mkdir -p $out $binutils $gcc

    # Symlink binutils
    ln -s ${binutilsStage} $binutils

    # Make gcc depend on binutils automatically
    ln -s ${gccStage} $gcc
  '';
}
