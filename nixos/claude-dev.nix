# DevaNix — NixOS module
#
# Gebruik in je configuration.nix:
#   imports = [ /pad/naar/DevaNix/nixos/claude-dev.nix ];
#   services.devanix = {
#     enable = true;
#     gebruiker = "jouwgebruikersnaam";
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.services.devanix;
in {

  options.services.devanix = {
    enable = lib.mkEnableOption "DevaNix Claude ontwikkelomgeving";

    gebruiker = lib.mkOption {
      type = lib.types.str;
      description = "Jouw NixOS gebruikersnaam (uitvoer van: whoami)";
    };

    dbNaam = lib.mkOption {
      type    = lib.types.str;
      default = "projectkeys";
      description = "Naam van de PostgreSQL database";
    };

    serverPort = lib.mkOption {
      type    = lib.types.port;
      default = 8000;
      description = "Poort voor de DevaNix API server (bereikbaar op LAN)";
    };
  };

  config = lib.mkIf cfg.enable {

    # ── PostgreSQL met pgvector ──────────────────────────────────────────────
    services.postgresql = {
      enable  = true;
      package = pkgs.postgresql_15;

      # pgvector: vector embeddings opslaan per project
      extraPlugins = ps: [ ps.pgvector ];

      ensureDatabases = [ cfg.dbNaam ];
      ensureUsers = [{
        name             = cfg.gebruiker;
        ensureDBOwnership = true;
      }];

      # Peer-authenticatie voor lokale gebruiker (geen wachtwoord nodig)
      authentication = lib.mkOverride 10 ''
        local all ${cfg.gebruiker} peer
        local all all             peer
        host  all all 127.0.0.1/32 md5
        host  all all ::1/128       md5
      '';
    };

    # Schema initialiseren na eerste start
    systemd.services.devanix-init-db = {
      description   = "DevaNix database schema initialiseren";
      after         = [ "postgresql.service" ];
      requires      = [ "postgresql.service" ];
      wantedBy      = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.gebruiker;
        ExecStart = pkgs.writeShellScript "devanix-init-db" ''
          ${pkgs.postgresql_15}/bin/psql -d ${cfg.dbNaam} \
            -f /etc/devanix/schema.sql \
            --on-error-stop \
            2>/dev/null || true
        '';
        RemainAfterExit = true;
      };
    };

    # Kopieer schema naar /etc/devanix
    environment.etc."devanix/schema.sql".source =
      ./schema.sql;

    # ── DevaNix API server (FastAPI) ─────────────────────────────────────────
    systemd.services.devanix-server = {
      description = "DevaNix Claude API server";
      after       = [ "devanix-init-db.service" "network.target" ];
      wantedBy    = [ "multi-user.target" ];
      serviceConfig = {
        User       = cfg.gebruiker;
        WorkingDirectory = "/home/${cfg.gebruiker}";
        ExecStart  = "${pkgs.python311}/bin/uvicorn devanix.server:app "
                   + "--host 0.0.0.0 "
                   + "--port ${toString cfg.serverPort} "
                   + "--reload";
        Restart    = "on-failure";
        Environment = [
          "DEVANIX_DB=${cfg.dbNaam}"
          "DEVANIX_PORT=${toString cfg.serverPort}"
        ];
      };
    };

    # ── nix-ld: run generic Linux binaries (zoals Claude Code CLI) ──────────
    programs.nix-ld.enable = true;

    # ── direnv ───────────────────────────────────────────────────────────────
    programs.direnv = {
      enable          = true;
      nix-direnv.enable = true;
    };

    # ── Pakketten system-wide beschikbaar ────────────────────────────────────
    environment.systemPackages = with pkgs; [
      postgresql_15
      direnv

      # Python met benodigde libraries
      (python311.withPackages (ps: with ps; [
        anthropic
        psycopg2
        fastapi
        uvicorn
        python-dotenv
        pydantic
      ]))
    ];

    # ── Firewall: open LAN-poort voor API server ─────────────────────────────
    networking.firewall.allowedTCPPorts = [ cfg.serverPort ];

  };
}
