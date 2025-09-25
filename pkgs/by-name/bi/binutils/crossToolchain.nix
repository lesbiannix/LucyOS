{ pkgs }:

let
  stdenv = pkgs.stdenv;

  nativePackages = with pkgs; [
    cmake
    zlib
    gnum4
    bison
  ];

  binutils = stdenv.mkDerivation rec {
    name = "binutils-2.45";

    src = pkgs.fetchurl {
      url = "https://ftp.fau.de/gnu/binutils/binutils-2.45.tar.bz2";
      sha256 = "1393f90db70c2ebd785fb434d6127f8888c559d5eeb9c006c354b203bab3473e";
    };

    nativeBuildInputs = nativePackages;
    buildInputs = [ ];

    prePhases = "prepEnvironmentPhase";
    prepEnvironmentPhase = ''
      export LFS=$(pwd)
      export LFSTOOLS=$(pwd)/tools
      export LFS_TGT=$(uname -m)-lucyos-linux-gnu
      mkdir -v $LFSTOOLS
    '';

    configurePhase = ''
      echo "Configuring... "
      time ( ./configure --prefix=$LFSTOOLS   \
                      --with-sysroot=$LFS     \
                      --target=$LFS_TGT       \
                      --disable-nls           \
                      --enable-gprofng=no     \
                      --disable-werror        \
                      --enable-new-dtags      \
                      --enable-default-hash-style=gnu
          )
    '';

    postInstall = ''
      rm -r $LFS/$sourceRoot
      cp -rvp $LFS/* $out/
    '';

    shellHook = ''
      echo -e "\033[31mNix Develop -> $name: Loading...\033[0m"

      if [[ "$(basename $(pwd))" != "$name" ]]; then
          mkdir -p "$name"
          cd "$name"
      fi

      eval "$prepEnvironmentPhase"
      echo -e "\033[36mNix Develop -> $name: Loaded.\033[0m"
      echo -e "\033[36mNix Develop -> Current directory: $(pwd)\033[0m"
    '';
  };
in
binutils
