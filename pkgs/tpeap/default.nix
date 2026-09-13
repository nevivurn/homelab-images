{
  lib,
  stdenvNoCC,
  fetchurl,
  callPackage,
  makeWrapper,
  jre,
  ps,
  rsync,
  mongodb-ce,
}:

stdenvNoCC.mkDerivation {
  pname = "tpeap";
  version = "6.3.0.45";

  src = fetchurl {
    url = "https://static.tp-link.com/upload/software/2026/202609/20260904/Omada_Network_Application_v6.3.0.45_linux_x64_20260903171900.tar.gz";
    hash = "sha256-2t9+GH+ishiSo/Jkda4VNg9B1k9XinDwgB0q4Z2p62o=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -rv data lib properties $out

    mkdir -p $out/bin
    ln -s ${lib.getExe' mongodb-ce "mongod"} $out/bin/mongod

    cat << EOF > $out/bin/tpeap
    #!/usr/bin/env bash
    set -eu

    ln -sf $out/bin $out/lib .

    mkdir -p data/{db,keystore,pdf} logs properties
    ln -sf $out/data/{cluster,html} data
    rsync -r --chmod D0755,F0644 $out/data/static/ data/static/
    cp $out/properties/* properties
    chmod +w properties/*.properties

    cd data
    exec ${lib.getExe jre} -cp "$out/lib/*" -server -Deap.home=.. com.tplink.smb.omada.starter.OmadaLinuxMain
    EOF
    chmod +x $out/bin/tpeap

    wrapProgram $out/bin/tpeap \
      --prefix PATH : ${
        lib.makeBinPath [
          ps
          rsync
        ]
      }

    runHook postInstall
  '';

  passthru.image = callPackage ./image.nix { };

  meta.mainProgram = "tpeap";
}
