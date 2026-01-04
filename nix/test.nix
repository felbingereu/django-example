{
  self,
  system,
  nixpkgs,
  ...
}:
let
  pkgs = import nixpkgs { inherit system; };
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
  '';
}
