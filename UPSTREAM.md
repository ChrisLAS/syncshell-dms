# Upstream

`syncshell-dms` began as a native DankMaterialShell port of
[`ilyaZar/syncshell`](https://github.com/ilyaZar/syncshell) at commit
`9454b414c771f68d210c5c245585bda9d0415840`.

Reused or adapted areas:

- local Syncthing API discovery and request lifecycle;
- event-based file activity classification;
- folder and device projection helpers;
- Syncthing status artwork.

Deliberately omitted from the first release:

- Omarchy package installation and removal;
- service start and stop controls;
- folder configuration mutations;
- Omarchy Web UI theming;
- Omarchy shell and UI component dependencies.

Future upstream reviews should compare behavior and pure model changes first.
Do not copy Omarchy lifecycle or UI code into the DMS frontend.
