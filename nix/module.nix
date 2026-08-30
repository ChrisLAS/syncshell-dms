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
in
{
  options.programs.syncshell-dms = {
    enable = lib.mkEnableOption "SyncShell read-only Syncthing monitoring plugin";

    package = lib.mkOption {
      type = lib.types.package;
      default = package;
      description = "SyncShell DMS plugin package.";
    };

  };

  config = lib.mkIf cfg.enable {
    programs.dms-shell.plugins.syncshell.src = "${cfg.package}/share/dms-plugins/syncshell";
    environment.systemPackages = [
      cfg.package
      pkgs.syncthing
      pkgs.xdg-utils
    ];
  };
}
