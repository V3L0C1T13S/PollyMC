{ lib
, stdenv
, cmake
, jdk8
, jdk
, zlib
, file
, wrapQtAppsHook
, xorg
, libpulseaudio
, qtbase
, qtsvg
, qtwayland
, libGL
, quazip
, glfw
, openal
, extra-cmake-modules
, ghc_filesystem
, msaClientID ? ""
, jdks ? [ jdk jdk8 ]

  # flake
, self
, version
, libnbtplusplus
, tomlplusplus
}:

stdenv.mkDerivation rec {
  pname = "pollymc";
  inherit version;

  src = lib.cleanSource self;

  nativeBuildInputs = [ extra-cmake-modules cmake file jdk wrapQtAppsHook ];
  buildInputs = [
    qtbase
    qtsvg
    zlib
    quazip
    ghc_filesystem
  ] ++ lib.optional (lib.versionAtLeast qtbase.version "6") qtwayland;

  cmakeFlags = lib.optionals (msaClientID != "") [ "-DLauncher_MSA_CLIENT_ID=${msaClientID}" ]
    ++ lib.optionals (lib.versionAtLeast qtbase.version "6") [ "-DLauncher_QT_VERSION_MAJOR=6" ];
  dontWrapQtApps = true;

  postUnpack = ''
    rm -rf source/libraries/libnbtplusplus
    mkdir source/libraries/libnbtplusplus
    ln -s ${libnbtplusplus}/* source/libraries/libnbtplusplus
    chmod -R +r+w source/libraries/libnbtplusplus
    chown -R $USER: source/libraries/libnbtplusplus
    rm -rf source/libraries/tomlplusplus
    mkdir source/libraries/tomlplusplus
    ln -s ${tomlplusplus}/* source/libraries/tomlplusplus
    chmod -R +r+w source/libraries/tomlplusplus
    chown -R $USER: source/libraries/tomlplusplus
  '';

  postInstall =
    let
      libpath = with xorg;
        lib.makeLibraryPath [
          libX11
          libXext
          libXcursor
          libXrandr
          libXxf86vm
          libpulseaudio
          libGL
          glfw
          openal
          stdenv.cc.cc.lib
        ];
    in
    ''
      # xorg.xrandr needed for LWJGL [2.9.2, 3) https://github.com/LWJGL/lwjgl/issues/128
      wrapQtApp $out/bin/pollymc \
        --set LD_LIBRARY_PATH /run/opengl-driver/lib:${libpath} \
        --prefix PRISMLAUNCHER_JAVA_PATHS : ${lib.makeSearchPath "bin/java" jdks} \
        --prefix PATH : ${lib.makeBinPath [xorg.xrandr]}
    '';


  meta = with lib; {
    homepage = "https://github.com/fn2006/PollyMC";
    description = "A free, open source launcher for Minecraft";
    longDescription = ''
      Allows you to have multiple, separate instances of Minecraft (each with
      their own mods, texture packs, saves, etc) and helps you manage them and
      their associated options with a simple interface.
    '';
    platforms = platforms.linux;
    changelog = "https://github.com/fn2006/PollyMC/releases/tag/${version}";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ minion3665 Scrumplex ];
  };
}

