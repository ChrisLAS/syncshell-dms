self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.syncshell-dms;
  package = self.packages.${pkgs.stdenv.hostPlatform.system}.syncshell-dms;
  pluginSource = "${package}/share/dms-plugins/syncshell";
in
{
  options.programs.syncshell-dms = {
    enable = lib.mkEnableOption "SyncShell read-only Syncthing monitoring plugin";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "SyncShell DMS plugin package.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        enabled = true;
        refreshIntervalSec = 60;
        syncthingExecutable = "syncthing";
        webUiUrl = "http://127.0.0.1:8384";
      };
      description = "Settings merged into the DMS plugin settings profile by the consumer.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasAttrByPath [ "programs" "dms-shell" "plugins" ] config;
        message = "programs.syncshell-dms requires a DMS module exposing programs.dms-shell.plugins";
      }
    ];

    programs.dms-shell.plugins.syncshell.src = pluginSource;
    environment.systemPackages = [
      cfg.package
      pkgs.syncthing
      pkgs.xdg-utils
    ];
  };
}
