# Maintenance

## App Updates

Update the application input in this deployment repository:

```bash
nix flake lock --update-input steeple-stream
git commit -am "Update Steeple Stream"
git push
```

comin will pull the deployment repository and apply the new NixOS generation on
the Beelink.

## Secret Rotation

Edit encrypted secrets with SOPS:

```bash
sops secrets/stakecenter.yaml
git commit -am "Rotate appliance secrets"
git push
```

The Beelink decrypts secrets locally during activation. Do not copy the
Beelink age private key into GitHub Actions.

## Rollback

On the Beelink:

```bash
sudo nixos-rebuild switch --rollback
```

For cloud infrastructure, revert the deployment repository commit and allow the
GitHub Actions Pulumi workflow to apply the rollback.
