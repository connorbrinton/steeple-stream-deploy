# Steeple Stream Deploy

Deployment source of truth for the Steeple Stream Beelink appliance.

This repository is intentionally separate from the application repository. It
contains the NixOS host configuration, comin pull deployment configuration,
Pulumi infrastructure-as-code, and SOPS-encrypted runtime secrets for the
specific appliance.

## Layout

- `flake.nix` defines the NixOS system.
- `nixos/hosts/stakecenter` contains the Beelink host configuration.
- `infra/cloudflare-gcp` contains Pulumi TypeScript infrastructure.
- `secrets/stakecenter.example.yaml` documents the SOPS secret shape.
- `docs/bootstrap.md` explains first install.
- `docs/maintenance.md` explains routine updates and recovery.

## First Build

```bash
nix build .#nixosConfigurations.steeple-stream-stakecenter.config.system.build.toplevel
```

Real secrets should be stored in `secrets/stakecenter.yaml` with SOPS. Do not
commit cleartext tunnel tokens, OAuth client secrets, age private keys, or env
files.
