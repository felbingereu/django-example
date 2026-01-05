{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
          django-example = pkgs.callPackage ./nix/package.nix { };
          default = django-example;
        }
      );

      checks = eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          django-example = pkgs.callPackage ./nix/test.nix { inherit self system nixpkgs; };
          default = django-example;
        }
      );

      nixosModules = rec {
        django-example =
          { config, lib, ... }:
          {
            imports = [ ./nix/module.nix ];
            nixpkgs.overlays = lib.mkIf config.myapps.django-example.enable [
              self.overlays.default
            ];
          };
        default = django-example;
      };

      devShells = eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];
            packages = with pkgs; [
              python315
            ];
          };
        }
      );
      overlays = {
        default = final: _prev: {
          inherit (self.packages.${final.stdenv.hostPlatform.system}) django-example;
        };
      };
    };
}
