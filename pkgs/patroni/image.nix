{
  lib,
  dockerTools,
  tini,
  coreutils,
  patroni,
  postgresql_18,
  glibcLocales,
}:

let
  locales = glibcLocales.override {
    allLocales = false;
  };
in

dockerTools.buildLayeredImage {
  name = patroni.pname;
  tag = patroni.version;
  config = {
    Entrypoint = [
      (lib.getExe tini)
      "--"
      (lib.getExe' patroni "patroni")
    ];
    Env = [ "LOCALE_ARCHIVE=${locales}/lib/locale/locale-archive" ];
  };
  contents = [
    coreutils
    dockerTools.binSh
    dockerTools.fakeNss
    patroni
    postgresql_18
  ];
}
