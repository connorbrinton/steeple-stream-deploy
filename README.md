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
- `secrets/steeplestream.example.yaml` documents the SOPS secret shape.
- `secrets/steeplestream.yaml` contains encrypted SOPS ciphertext for the appliance.
- `docs/bootstrap.md` explains first install.
- `docs/maintenance.md` explains routine updates and recovery.

## First Build

```bash
nix build .#nixosConfigurations.nixos.config.system.build.toplevel
```

Real secrets should be stored in `secrets/steeplestream.yaml` with SOPS. Do not
commit cleartext tunnel tokens, OAuth client secrets, age private keys, or env
files. The host age private key stays outside Git at
`/root/.config/sops/age/keys.txt` on the appliance.

## License

Steeple Stream Deploy is licensed under the GNU Affero General Public License
v3.0. See [LICENSE](LICENSE).
