# Changelog

## 0.1.0 - 2026-08-30

- Add a native DMS composite daemon and DankBar widget.
- Discover the local Syncthing API without persisting its API key.
- Show read-only folder health, synchronization state, and connected devices.
- Open configured folders and the local Syncthing Web UI.
- Export a Nix package, reusable NixOS module, checks, formatter, and dev shell.
- Preserve upstream SyncShell attribution and Syncthing icon licensing.

Validated with DMS 1.5.3, Quickshell 0.3.0, Syncthing 2.1.3, and NixOS
26.11. The unavailable state was tested without a Syncthing service on
Nixvader. Live API discovery, 11 folders, device status, and popout rendering
were tested against the system Syncthing service on Nixstation.
