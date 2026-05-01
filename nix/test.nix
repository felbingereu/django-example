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

  # The test can be run in interactive mode, to enable opening the
  # django-example project in the browser of the host machine:
  # nix build .#checks.x86_64-linux.default.driverInteractive && ./result/bin/nixos-test-driver
  # Next you run start_all() to start the machine.
  # Finally you can access http://127.0.0.1:8000/admin in your browser
  interactive.nodes.machine = {
    myapps.django-example.debug = true;
    networking.firewall.allowedTCPPorts = [ 80 ];
    virtualisation.forwardPorts = [
      {
        from = "host";
        host.port = 8000;
        guest.port = 80;
      }
    ];
  };

  testScript = /* python */ ''
    start_all()

    machine.wait_for_unit("django-example.service")

    machine.wait_for_open_port(8000)

    machine.succeed("""
      curl -s http://127.0.0.1:8000/manifest.json | ${lib.getExe pkgs.jq} '.display == "standalone"'
    """)
  '';
}
