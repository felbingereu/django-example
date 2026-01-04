{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkOption
    types
    ;
in
{
  options.myapps.django-example = {
    enable = mkEnableOption "Django example";
    package = mkOption {
      type = types.package;
      default = pkgs.django-example;
    };
    environmentFiles = mkOption {
      type = types.listOf types.path;
      default = [ ];
    };
    domain = mkOption {
      # TODO configure django
      type = types.str;
      default = "django-example.${toString config.networking.fqdn}";
    };
    listenAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
    };
    port = mkOption {
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
        default = "/run/postgresql";
      };
      port = mkOption {
        type = with types; nullOr port;
        default = null;
      };
      username = mkOption {
        type = types.str;
        default = "django-example";
      };
      passwordFile = mkOption {
        type = with types; nullOr path;
        default = null;
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
    in
    mkIf cfg.enable (mkMerge [
      # base
      {
        users = {
          groups.django-example = { };
          users.django-example = {
            isSystemUser = true;
            group = "django-example";
          };
        };

        systemd.services = {
          django-example = {
            enable = true;
            after = [
              "network.target"
              "postgresql.target"
            ];
            wantedBy = [ "multi-user.target" ];

            preStart = ''
              ${lib.getExe cfg.package} migrate
            '';

            serviceConfig = {
              ExecStart = "${lib.getExe cfg.package.python3.pkgs.gunicorn} --bind ${cfg.listenAddr}:${toString cfg.port} --worker-tmp-dir /dev/shm app.wsgi:application";
              StateDirectory = "django-example";
              User = "django-example";
              Group = "django-example";
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelLogs = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = true;
              ProtectProc = "invisible";
              ProtectSystem = "strict";
              Restart = "on-failure";
              RestartSec = 10;
              RestrictAddressFamilies = [
                "AF_INET"
                "AF_INET6"
                "AF_UNIX"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              EnvironmentFile = cfg.environmentFiles;
            }
            // lib.optionalAttrs (cfg.database.passwordFile != null) {
              LoadCredential = [
                "sql_password:${cfg.database.passwordFile}"
              ];
            };

            environment = {
              PYTHONPATH = "${cfg.package.python3.pkgs.makePythonPath cfg.package.propagatedBuildInputs}:${cfg.package}/lib/django-example";

              SQL_ENGINE = "django.db.backends.postgresql";
              SQL_HOST = cfg.database.hostname;
              SQL_PORT = lib.mkIf (cfg.database.port != null) (toString cfg.database.port);
              SQL_USER = cfg.database.username;
              SQL_PASSWORD_FILE = lib.mkIf (cfg.database.passwordFile != null) "%d/sql_password";
              SQL_DATABASE = cfg.database.name;
            };
          };
        };
      }

      # configure local database
      (mkIf cfg.useLocalDatabase {
        services.postgresql = {
          enable = true;
          ensureDatabases = [ "django-example" ];
          ensureUsers = [
            {
              name = "django-example";
              ensureDBOwnership = true;
            }
          ];
        };
      })
    ]);
}
