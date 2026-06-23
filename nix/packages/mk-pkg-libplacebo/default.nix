{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "libplacebo";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith {
    inherit pkgs os arch;
  };

  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pkgs.cmake
    pkgs.python3
    pkgs.python3Packages.jinja2
    pkgs.python3Packages.glad2
  ];

  pname = import ../../utils/name/package.nix name;

  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };

  patchedSource = pkgs.runCommand
    "${pname}-patched-source-${version}"
    { }
    ''
      cp -R ${src} source
      chmod -R u+w source

      # 使用 Nix 提供的 jinja2/glad2，而不是缺失的 Git submodule。
      substituteInPlace source/meson.build \
        --replace-fail "python_env.append" "#"

      cp -R source $out
    '';

  fixedSource = callPackage ../../utils/patch-shebangs/default.nix {
    name = "${pname}-fixed-source-${version}";
    src = patchedSource;
    inherit nativeBuildInputs;
  };

in
pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  inherit pname version;

  src = fixedSource;
  dontUnpack = true;
  enableParallelBuilding = true;

  inherit nativeBuildInputs;

  buildInputs = [
    pkgs.vulkan-headers
    pkgs."fast-float"
  ];

  # 项目直接调用 Xcode clang，而非 Nix clang wrapper。
  # 因此需要显式提供头文件搜索路径。
  CPATH = pkgs.lib.makeSearchPath "include" [
    pkgs.vulkan-headers
    pkgs."fast-float"
  ];

  configurePhase = ''
    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out \
      --buildtype=release \
      -Ddefault_library=static \
      -Db_staticpic=true \
      -Ddemos=false \
      -Dtests=false \
      -Dbench=false \
      -Dfuzz=false \
      -Dvulkan=disabled \
      -Dvk-proc-addr=disabled \
      -Dopengl=disabled \
      -Dgl-proc-addr=disabled \
      -Dd3d11=disabled \
      -Dglslang=disabled \
      -Dshaderc=disabled \
      -Dlcms=disabled \
      -Ddovi=disabled \
      -Dlibdovi=disabled \
      -Dunwind=disabled \
      -Dxxhash=disabled
  '';

  buildPhase = ''
    meson compile -vC build
  '';

  installPhase = ''
    meson install -C build
  '';
}
