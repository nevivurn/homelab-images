{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "mongodb-ce" ];
        overlays = [ self.overlays.default ];
      };
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      overlays.default = final: prev: {
        chrony = prev.chrony.overrideAttrs (prevAttrs: {
          passthru = prevAttrs.passthru // {
            image = final.callPackage ./pkgs/chrony/image.nix { };
          };
        });
        isc-dhcp = final.callPackage ./pkgs/isc-dhcp { };
        patroni = prev.patroni.overrideAttrs (prevAttrs: {
          passthru = prevAttrs.passthru // {
            image = final.callPackage ./pkgs/patroni/image.nix { };
          };
        });
        tpeap = final.callPackage ./pkgs/tpeap { };

        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (python-final: python-prev: {
            # ref: https://github.com/NixOS/nixpkgs/pull/480738
            python-etcd = python-prev.python-etcd.overridePythonAttrs (oldAttrs: {
              version = "0.5.0-unstable-2023-10-31";
              pyproject = true;

              src = final.fetchFromGitHub {
                owner = "jplana";
                repo = "python-etcd";
                rev = "5aea0fd4461bd05dd96e4ad637f6be7bceb1cee5";
                hash = "sha256-eVirStLOPTbf860jfkNMWtGf+r0VygLZRjRDjBMCVKg=";
              };

              patches = (oldAttrs.patches or [ ]) ++ [
                (final.fetchpatch2 {
                  name = "remove-getheader-usage.patch";
                  url = "https://raw.githubusercontent.com/deshaw/nixpkgs/c4dedfb8db95984c60f3339037c90c3541febb92/pkgs/development/python-modules/python-etcd/remove-getheader-usage.patch";
                  hash = "sha256-TdZMGGhKKehwTNNZxMTVOoESZ7bAe5Sz1OFuLdLbjvs=";
                })
              ];
            });
          })
        ];
      };
      packages.${system} = {
        chrony = pkgs.chrony.passthru.image;
        isc-dhcp-dhcrelay = pkgs.isc-dhcp.passthru.image-dhcrelay;
        patroni = pkgs.patroni.passthru.image;
        tpeap = pkgs.tpeap.passthru.image;
      };
      checks.${system}.default = pkgs.linkFarm "homelab-images" self.packages.${system};
    };
}
