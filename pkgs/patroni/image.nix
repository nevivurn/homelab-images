{
  lib,
  dockerTools,
  glibcLocales,
  tini,
  coreutils,
  patroni,
  python3Packages,
  postgresql_18,
}:

let
  patroni' = patroni.override {
    extras = [
      "psycopg2"
      "etcd3"
    ];
  };
  locales = glibcLocales.override {
    allLocales = false;
  };
in

(dockerTools.buildLayeredImage {
  name = patroni'.pname;
  tag = patroni'.version;
  config = {
    Entrypoint = [
      (lib.getExe tini)
      "--"
      (lib.getExe' patroni' "patroni")
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
}).overrideAttrs
  (prev: {
    passthru = (prev.passthru or { }) // {
      patroni = patroni';
    };
  })
