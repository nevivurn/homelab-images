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
  patroni' = patroni.overridePythonAttrs {
    dependencies = with python3Packages; [
      # exclude dependencies for DCS modules other than etcd
      click
      prettytable
      psutil
      psycopg2
      python-dateutil
      python-etcd
      pyyaml
      tzlocal
      urllib3
      (ydiff.overridePythonAttrs {
        # avoid including git, hg, etc. in the closure
        patchPhase = ''
          patchShebangs setup.py
          patchShebangs tests/*.sh
        '';
        doCheck = false;
      })
    ];
    disabledTestPaths = [
      "tests/test_aws.py"
      "tests/test_consul.py"
      "tests/test_exhibitor.py"
      "tests/test_raft.py"
      "tests/test_raft_controller.py"
      "tests/test_zookeeper.py"
    ];
  };
  locales = glibcLocales.override {
    allLocales = false;
  };
in

dockerTools.buildLayeredImage {
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
}
