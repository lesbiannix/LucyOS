{ pkgs, binutils }:

let
  stdenv = pkgs.stdenv;

  nativePackages = with pkgs; [
    cmake
    zlib
    bison
  ];

  # Attributes for stdenv.mkDerivation can be found at:
  # https://nixos.org/manual/nixpkgs/stable/#sec-tools-of-stdenv
  gccPkg = stdenv.mkDerivation {
    name = "gcc-LFS";

    src = pkgs.fetchurl {
      url = "https://ftp.fau.de/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.gz";
      sha256 = "sha256-cpTWXMGgVYy4Fa8MqMd2PYb3oxGZeU7eP2MMDRsKVyM=";
    };

    secondarySrcs = [
      (pkgs.fetchurl {
        url = "https://ftp.fau.de/gnu/mpfr/mpfr-4.2.2.tar.gz";
        sha256 = "sha256-gmy7JGEL0ZPzb94XIjP7jACfP1wq2Z9kTQ3qLhaiDkI=";
      })
      (pkgs.fetchurl {
        url = "https://ftp.fau.de/gnu/gmp/gmp-6.3.0.tar.xz";
        sha256 = "sha256-o8K4AgG4nmhhb0rTC8Zq7kknw85Q4zkpyoGdXENTiJg=";
      })
      (pkgs.fetchurl {
        url = "https://ftp.fau.de/gnu/mpc/mpc-1.3.1.tar.gz";
        sha256 = "sha256-q2QkkvXPiCt0qgy3MM1BCoHtzb7IlRg86TDnBsHHWbg=";
      })
    ];

    nativeBuildInputs = [
      nativePackages
      binutils
    ];
    buildInputs = with pkgs; [ gcc ];

    prePhases = "prepEnvironmentPhase";

    prepEnvironmentPhase = ''
      export LFS_TGT=$(uname -m)-lucyos-linux-gnu
      export BINTOOLS=${binutils}
      export LFS=$(pwd)
      export LFSTOOLS=$(pwd)/tools
      export PATH=$LFSTOOLS/bin:$PATH
      export CONFIG_SITE=$LFS/usr/share/config.site

      cp -r $BINTOOLS/* $LFS
      chmod -R u+w $LFS
    '';

    # Adding mpc, gmp, and mpfr to gcc source repo.
    patchPhase = ''
      export SOURCE=/build/$sourceRoot

      for secSrc in $secondarySrcs; do
          case $secSrc in
          *.xz)
              tar -xJf $secSrc -C ../$sourceRoot/
              ;;
          *.gz)
              tar -xzf $secSrc -C ../$sourceRoot/
              ;;
          *)
              echo "Invalid filetype: $secSrc"
              exit 1
              ;;
          esac

          srcDir=$(echo $secSrc | sed 's/^[^-]*-\(.*\)\.tar.*/\1/')
          echo "Src: $srcDir"
          newDir=$(echo $secSrc | cut -d'-' -f2)
          echo "newDir: $newDir"
          mv -v ./$srcDir ./$newDir
      done


      case $(uname -m) in
          x86_64)
              sed -e '/m64=/s/lib64/lib/' \
              -i.orig gcc/config/i386/t-linux64
      ;;
      esac
    '';

    # CFLAGS and CXXFLAGS added to dodge string literal warning error.
    configurePhase = ''
      echo "Starting config"

      mkdir -v build
      cd build

      ../configure                         \
              --prefix=$LFSTOOLS          \
              --target=$LFS_TGT           \
              --with-glibc-version=2.39   \
              --with-sysroot=$LFS         \
              --with-newlib               \
              --without-headers           \
              --enable-default-pie        \
              --enable-default-ssp        \
              --disable-nls               \
              --disable-shared            \
              --disable-multilib          \
              --disable-threads           \
              --disable-libatomic         \
              --disable-libgomp           \
              --disable-libquadmath       \
              --disable-libssp            \
              --disable-libvtv            \
              --disable-libstdcxx         \
              --enable-languages=c,c++    \
              CFLAGS='-Wno-error=format-security' \
              CXXFLAGS='-Wno-error=format-security'
    '';

    # Path to the GCC source headers is in gcc dir of source folder.
    # Concatenate these to create/populate internal limits.h of crossGcc
    postInstall = ''
      echo "Install complete."

      cat $LFS/$sourceRoot/gcc/limitx.h $LFS/$sourceRoot/gcc/glimits.h $LFS/$sourceRoot/gcc/limity.h > \
      $(dirname $($LFSTOOLS/bin/$LFS_TGT-gcc -print-libgcc-file-name))/include/limits.h

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
gccPkg
