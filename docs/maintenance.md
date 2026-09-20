# Maintenance

## Nix Input Updates

Update a specific input:

```bash
nix flake update nixpkgs
nix flake update sops-nix
nix flake update comin
nix flake update steeple-stream
git add flake.lock
git commit -m "Update deployment inputs"
git push
```

comin will pull the deployment repository and apply the new NixOS generation on
the Beelink.

## Secret Rotation

Edit encrypted secrets with SOPS:

```bash
sops secrets/steeplestream.yaml
git add secrets/steeplestream.yaml
git commit -m "Rotate appliance secrets"
git push
```

The Beelink decrypts secrets locally during activation. Do not copy the Beelink
age private key into GitHub Actions or any repository.

The production secret file contains the Cloudflare tunnel token, Google OAuth
client secret, and Steeple Stream session secret. The Google client ID and
authorized email addresses are nonsecret values declared in the host's NixOS
configuration. Keep the session secret stable; rotating it invalidates existing
application sessions.

The Google OAuth web client must allow this redirect URI:

```text
https://broadcasts.brintonium.com/auth/google/callback
```

Cloudflare Access should not protect the application hostname when application
authentication is enabled. Keep Access enabled for the separate SSH hostname.

## Rollback

On the Beelink:

```bash
sudo nixos-rebuild switch --rollback
```

For cloud infrastructure, revert the deployment repository commit and allow the
GitHub Actions Pulumi workflow to apply the rollback.
