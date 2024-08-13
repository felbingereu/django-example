{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      defaultSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      eachDefaultSystem = lib.genAttrs defaultSystems;
    in
    {
      packages = eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          django-example = (pkgs.lib.callPackageWith pkgs.python312.pkgs) ./nix/django-example.nix { };
          default = django-example;
        }
      );

      nixosModules = rec {
        django-example = {
          imports = [ ./nix/module.nix ];
        };
        default = django-example;
      };

      devShells = eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          # TODO integrate python layout, which is currently in .envrc
          default = pkgs.mkShell { packages = with pkgs; [ python312 ]; };
        }
      );
    };
}
