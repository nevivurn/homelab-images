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
  version = "6.2.10.17";

  src = fetchurl {
    url = "https://static.tp-link.com/upload/software/2026/202604/20260429/Omada_Network_Application_v6.2.10.17_linux_x64_20260428102037.tar.gz";
    hash = "sha256-1euU8jW2747kLQUhSY6Eopne1E+OZ65vu3TFK9SCJCU=";
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
