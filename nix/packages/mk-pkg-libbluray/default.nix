{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "libbluray";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  freetype = callPackage ../mk-pkg-freetype/default.nix { };
  libxml2 = callPackage ../mk-pkg-libxml2/default.nix { };

  xctoolchainLipo =
    callPackage ../../utils/xctoolchain/lipo.nix { };

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };

  patchedSource = pkgs.runCommand
    "${pname}-patched-source-${os}-${arch}-${version}"
    { }
    ''
      mkdir -p "$out"
      cp -R ${src}/. "$out/"
      chmod -R u+w "$out"

      ${pkgs.lib.optionalString
        (builtins.elem os [ "ios" "iossimulator" ])
        ''
          substituteInPlace "$out/meson.build" \
            --replace-fail \
              "if host_machine.system() == 'darwin'" \
              "if false"

          substituteInPlace "$out/src/meson.build" \
            --replace-fail \
              "elif host_machine.system() == 'darwin'" \
              "elif false"
        ''}
    '';

in


pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version src;

  dontUnpack = true;
  enableParallelBuilding = true;

  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    xctoolchainLipo
  ];

  buildInputs = [
    freetype
    libxml2
  ];
configurePhase = ''
  runHook preConfigure

  sourceDir="$NIX_BUILD_TOP/libbluray-source"
  buildDir="$NIX_BUILD_TOP/build"

  cp -R "$src" "$sourceDir"
  chmod -R u+w "$sourceDir"

  ${pkgs.lib.optionalString
    (builtins.elem os [ "ios" "iossimulator" ])
    ''
      substituteInPlace "$sourceDir/meson.build" \
        --replace-fail \
          "if host_machine.system() == 'darwin'" \
          "if false"

      substituteInPlace "$sourceDir/src/meson.build" \
        --replace-fail \
          "elif host_machine.system() == 'darwin'" \
          "elif false"
    ''}

  meson setup "$buildDir" "$sourceDir" \
    --native-file ${nativeFile} \
    --cross-file ${crossFile} \
    --prefix="$out" \
    --force-fallback-for=libudfread \
    -Dbuildtype=release \
    -Ddefault_library=shared \
    -Denable_docs=false \
    -Denable_tools=false \
    -Denable_devtools=false \
    -Denable_examples=false \
    -Dbdj_jar=disabled \
    -Dembed_udfread=true \
    -Dfontconfig=disabled \
    -Dfreetype=enabled \
    -Dlibxml2=enabled

  test -f "$buildDir/build.ninja"
  runHook postConfigure
'';

buildPhase = ''
  runHook preBuild
  echo "Using custom libbluray buildPhase"
  meson compile -v -C "$NIX_BUILD_TOP/build"
  runHook postBuild
'';

installPhase = ''
  runHook preInstall
  meson install -C "$NIX_BUILD_TOP/build"

  test -e "$out/lib/libbluray.dylib"
  test -e "$out/lib/pkgconfig/libbluray.pc"
  runHook postInstall
'';
}
