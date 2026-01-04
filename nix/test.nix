{
  self,
  system,
  nixpkgs,
  ...
}:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (nixpkgs) lib;
in
pkgs.testers.nixosTest {
  name = "django-example";

  nodes.machine = {
    imports = [
      self.nixosModules.default
    ];
    myapps.django-example = {
      enable = true;
    };
  };

  testScript = /* python */ ''
    start_all()

    machine.wait_for_unit("django-example.service")

    machine.wait_until_succeeds("ss -tlpn | grep 8000")

    machine.succeed("""
      curl -s http://127.0.0.1:8000/manifest.json | ${lib.getExe pkgs.jq} '.display == "standalone"'
    """)
  '';
}
