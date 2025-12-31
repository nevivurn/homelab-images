{
  lib,
  dockerTools,
  tini,
  coreutils,
  tpeap,
}:

dockerTools.buildLayeredImage {
  name = tpeap.pname;
  tag = tpeap.version;
  config = {
    Entrypoint = [
      (lib.getExe tini)
      "--"
      (lib.getExe tpeap)
    ];
  };
  contents = [
    dockerTools.binSh
    dockerTools.fakeNss
    dockerTools.caCertificates
    coreutils
  ];
}
