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
