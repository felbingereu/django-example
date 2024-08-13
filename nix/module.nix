{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.myapps.django-example = {
    enable = mkEnableOption "Django example";
    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.system}.django-example;
    };
    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
    };
    domain = mkOption {
      type = types.str;
      default = "django-example.${toString config.networking.fqdn}";
    };
    listenAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    internal_port = mkOption {
      type = types.port;
      default = 8000;
    };
    useLocalDatabase = mkOption {
      type = types.bool;
      default = true;
    };
    database = {
      hostname = mkOption {
        type = types.str;
        default = "127.0.0.1";
      };
      username = mkOption {
        type = types.str;
        default = "django-example";
      };
      name = mkOption {
        type = types.str;
        default = "django-example";
      };
    };
  };

  config =
    let
      cfg = config.myapps.django-example;
      pkg = cfg.package;
    in
    lib.mkIf cfg.enable {
      systemd.services = {
        django-example = {
          enable = true;
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            User = "django-example";
            Group = "django-example";
            DynamicUser = true;
            Restart = "always";
            EnvironmentFile = cfg.environmentFiles;
            #ExecPreStart = [
            #  "echo ${pkg}/manage.py migrate"
            #  "echo ${pkg}/manage.py collectstatic --no-input"
            #  "echo ${pkg}/manage.py compilemessages"
            #];
            #ExecStart = "echo ${pkg.gunicorn}/bin/gunicorn app.wsgi:application --bind ${cfg.listenAddr}:${cfg.internal_port}";
            ExecStart = "${pkg}/bin/django-example-manage runserver 0.0.0.0:${toString cfg.internal_port}";
            WorkingDirectory = "${pkg}/lib/python3.11/site-packages/app";
          };

          #environment = {
          #  PYTHONPATH = pkg.pythonPath;
          #};
        };
      };

      services.nginx = {
        #enable = true;
        virtualHosts.${toString cfg.domain} = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString cfg.internal_port}";
            proxyWebsockets = true;
          };
          serverName = toString cfg.domain;

          # use ACME DNS-01 challenge
          useACMEHost = toString cfg.domain;
          forceSSL = true;
        };
      };

      #security.acme.certs."${toString cfg.domain}" = {};
    };
}
