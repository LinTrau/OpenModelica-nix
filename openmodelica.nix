{
  openmodelica-core,
  stdenv,
  lib,
  makeWrapper,
  boost,
  curl,
  expat,
  fontconfig,
  freetype,
  gfortran,
  glibc,
  hdf5,
  icu,
  libffi,
  libGL,
  libxml2,
  libuuid,
  lp_solve,
  openblas,
  lapack,
  openssl,
  qt5,
  readline,
  sundials,
  zlib,
  openscenegraph,
  xorg,
  xterm,
  clang,
  cmake,
  zip,
}:

let
  qtVersion = qt5.qtbase.version;
in

stdenv.mkDerivation {
  pname = "openmodelica";
  version = "1.25.0";

  src = openmodelica-core;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    zip
    clang
    cmake
    boost
    curl
    expat
    fontconfig
    freetype
    gfortran
    gfortran.cc.lib
    glibc
    hdf5
    libffi
    libGL
    libGL.dev
    libxml2
    libuuid
    lp_solve
    openblas
    lapack
    openssl
    qt5.qtbase
    qt5.qtsvg
    qt5.qtxmlpatterns
    qt5.qttools
    qt5.qtwebkit
    qt5.qtwebengine
    readline
    readline.dev
    sundials
    zlib
    openscenegraph
    stdenv.cc.libc_dev
    icu
    xorg.libX11
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xterm
  ];

  phases = [
    "installPhase"
    "fixupPhase"
  ];

  installPhase = ''
    mkdir -p $out/bin
  '';

  postFixup = ''
    wrapper_LIBRARY_PATH="${openmodelica-core}/lib/omc:${
      lib.makeLibraryPath [
        boost
        curl
        expat
        fontconfig
        freetype
        gfortran.cc.lib
        glibc.dev
        hdf5
        icu.dev
        libffi
        libGL
        libxml2
        libuuid
        lp_solve
        openblas
        lapack
        openssl
        qt5.qtbase
        qt5.qtsvg
        qt5.qtxmlpatterns
        qt5.qttools
        qt5.qtwebkit
        qt5.qtwebengine
        readline
        sundials
        zlib
        openscenegraph
        stdenv.cc.libc_dev
        xorg.libX11
        xorg.libXrandr
        xorg.libXinerama
        xorg.libXcursor
      ]
    }"

    ln -s ${xterm}/bin/xterm $out/bin/x-terminal-emulator

    for exe in ${openmodelica-core}/bin/*; do
      if [ -x "$exe" ] && [ ! -L "$exe" ]; then
        echo "wrapping $exe"
        makeWrapper "$exe" "$out/bin/$(basename $exe)" \
          --prefix LD_LIBRARY_PATH : "$wrapper_LIBRARY_PATH" \
          --prefix LIBRARY_PATH    : "$wrapper_LIBRARY_PATH" \
          --prefix QT_PLUGIN_PATH  : "${qt5.qtbase}/lib/qt-${qtVersion}/plugins" \
          --prefix QT_PLUGIN_PATH  : "${qt5.qtsvg}/lib/qt-${qtVersion}/plugins" \
          --prefix QT_PLUGIN_PATH  : "${qt5.qtxmlpatterns}/lib/qt-${qtVersion}/plugins" \
          --prefix QT_PLUGIN_PATH  : "${qt5.qttools}/lib/qt-${qtVersion}/plugins" \
          --prefix QT_PLUGIN_PATH  : "${qt5.qtwebkit}/lib/qt-${qtVersion}/plugins" \
          --prefix QT_PLUGIN_PATH  : "${qt5.qtwebengine}/lib/qt-${qtVersion}/plugins" \
          --prefix PATH            : "${cmake}/bin" \
          --prefix PATH            : "${clang}/bin" \
          --prefix PATH            : "${zip}/bin"
      fi
    done
  '';

  meta = with lib; {
    description = "OpenModelica with wrapped binaries for system-wide installation";
    homepage = "https://openmodelica.org/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
