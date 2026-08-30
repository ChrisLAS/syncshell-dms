{
  description = "Read-only Syncthing monitoring plugin for DankMaterialShell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          syncshell-dms = pkgs.stdenvNoCC.mkDerivation {
            pname = "syncshell-dms";
            version = "0.2.1";
            src = self;
            dontBuild = true;
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/share/dms-plugins/syncshell"
              cp -R plugin.json SyncshellDaemon.qml SyncshellWidget.qml \
                core models assets CHANGELOG.md LICENSE THIRD_PARTY_NOTICES.md UPSTREAM.md \
                "$out/share/dms-plugins/syncshell/"
              runHook postInstall
            '';
            meta = {
              description = "Read-only Syncthing monitoring plugin for DankMaterialShell";
              homepage = "https://github.com/ChrisLAS/syncshell-dms";
              license = with pkgs.lib.licenses; [
                mit
                mpl20
              ];
              platforms = pkgs.lib.platforms.linux;
            };
          };
          default = syncshell-dms;
        }
      );

      nixosModules.syncshell-dms = import ./nix/module.nix self;
      nixosModules.default = self.nixosModules.syncshell-dms;

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          package = self.packages.${system}.syncshell-dms;
        in
        {
          inherit package;
          source-contract =
            pkgs.runCommand "syncshell-dms-source-contract"
              {
                nativeBuildInputs = [
                  pkgs.jq
                  pkgs.nodejs
                  pkgs.ripgrep
                ];
              }
              ''
                jq -e '.id == "syncshell" and .type == "composite"' ${self}/plugin.json >/dev/null
                if rg -n 'qs\.(Commons|Ui)|omarchy|systemctl|patchFolder|addFolder|deleteFolder' \
                  ${self} --glob '*.qml' --glob '*.js'; then
                  echo "Forbidden Omarchy or mutation contract found" >&2
                  exit 1
                fi
                cd ${self}
                node tests/model.test.js
                test -f ${package}/share/dms-plugins/syncshell/plugin.json
                touch "$out"
              '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              jq
              nixfmt
              nodejs
              quickshell
              ripgrep
              shellcheck
              syncthing
            ];
          };
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
