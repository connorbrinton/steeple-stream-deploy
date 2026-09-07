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

The appliance runs the pinned Steeple Stream service in camera-control mode on
`127.0.0.1:8080`. It trusts Cloudflare Access email headers from loopback and uses
live-only in-memory HLS preview. Its state is in `/var/lib/steeple-stream`.

The existing remotely managed tunnel must route `broadcasts.brintonium.com` to
`http://127.0.0.1:8080`. Keep the whole hostname protected by Cloudflare Access,
including API and media paths, and preserve the SSH ingress route. Tunnel routes
are currently managed in Cloudflare, not by this NixOS configuration.

NDI reception uses single TCP on this appliance: direct receiver tests received
audio and video over TCP but timed out using the default transport. The
receiver-only SDK configuration lives at
`/etc/steeple-stream/ndi/ndi-config.v1.json`; no camera configuration is changed.

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
