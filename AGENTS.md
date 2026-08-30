# AGENTS.md -- SyncShell DMS Development Contract

## Project Contract

This repository is a native DankMaterialShell plugin derived from
`ilyaZar/syncshell`. DMS is the target shell. Do not introduce Omarchy shell,
plugin lifecycle, package management, or `qs.Commons`/`qs.Ui` dependencies.

Nix is the canonical development and release environment. Generic non-Nix DMS
installs remain supported, so runtime QML must not depend on Nix store paths.

Version 0.1.x is read-only. It may monitor Syncthing and open folders or the Web
UI. It must not install packages, control services, or mutate Syncthing folder
configuration.

## Start Here

Before editing:

```bash
git status --short
git log -1 --oneline
nix flake metadata
nix flake check
```

Read `README.md`, `UPSTREAM.md`, `plugin.json`, and the affected source files.
On a Nix host use `nix develop` for all formatting, linting, and tests.

## Source Ownership

- `SyncshellDaemon.qml`: API discovery, request lifecycle, state publication,
  and IPC.
- `SyncshellWidget.qml`: DMS bar pill and popout.
- `core/`: reusable stateful API adapters.
- `models/`: pure JavaScript transformations.
- `nix/` and `flake.nix`: package and reusable NixOS integration.
- Host-specific bar placement and policy belong in downstream configurations,
  not this repository.

## Safety

- Never log, persist, publish, or place the Syncthing API key in argv.
- Never expose full GUI configuration through IPC or plugin global state.
- Never disable TLS verification.
- Never use shell interpolation for paths, URLs, or credentials.
- Never modify a real Syncthing instance in automated tests.
- Never assume Syncthing is a user service or that the plugin controls it.
- Never add hostnames, folder names, API keys, or user-specific paths.
- Reject stale asynchronous responses after refresh or configuration changes.
- Keep monitor-only behavior the default in every future capability design.

## Verification

Run before handoff:

```bash
nix fmt -- --check flake.nix nix/module.nix
nix flake check
nix build
```

When DMS is available, also validate the manifest and perform a clean plugin
load in an isolated test profile. Real-instance acceptance is read-only and
must verify that no API key appears in process arguments, logs, IPC, or plugin
settings.

Non-Nix contributors need compatible versions of Quickshell, DMS, Syncthing,
`jq`, and a Nix formatter, but release validation always uses `flake.lock`.

## Releases

- Update `plugin.json`, changelog, and documentation together.
- Run the full Nix verification suite from a clean tree.
- Record tested DMS, Quickshell, Syncthing, and NixOS versions.
- Preserve MIT and MPL-2.0 notices and upstream provenance.
- Do not publish from a dirty worktree.
