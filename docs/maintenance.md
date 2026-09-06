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

## Rollback

On the Beelink:

```bash
sudo nixos-rebuild switch --rollback
```

For cloud infrastructure, revert the deployment repository commit and allow the
GitHub Actions Pulumi workflow to apply the rollback.
