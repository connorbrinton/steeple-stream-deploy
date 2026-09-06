# Beelink Bootstrap

This repository currently models the first comin adoption of the already
installed Steeple Stream mini PC.

The first adoption intentionally keeps the existing hostname and SSH posture:

- flake output: `nixosConfigurations.nixos`
- hostname: `nixos`
- direct LAN SSH remains enabled
- password SSH remains enabled
- Cloudflare browser SSH compatibility MACs remain enabled
- GNOME remains installed

Hardening and hostname cleanup should happen only after comin has proven it can
deploy reliably.

## Prerequisites

The host-local age private key must already exist on the appliance:

```bash
/root/.config/sops/age/keys.txt
```

Never commit that file. The encrypted SOPS file in this repository is safe to
commit because it contains ciphertext only:

```bash
secrets/steeplestream.yaml
```

The initial Cloudflare Tunnel route is managed remotely in Cloudflare and points
browser/terminal SSH at localhost port 22 on the appliance.

## First Manual Switch

Clone this repository on the appliance or copy it into a temporary working
directory, then run:

```bash
nixos-rebuild switch \
  --sudo \
  --flake .#nixos
```

If the running system has not picked up flake support yet, add the one-time
option:

```bash
nixos-rebuild switch \
  --sudo \
  --flake .#nixos \
  --option experimental-features 'nix-command flakes'
```

## Verification

After the first switch, verify the services that protect remote access:

```bash
systemctl status cloudflared.service
systemctl status sshd.service
systemctl status comin.service
journalctl -u comin.service -n 100 --no-pager
```

Then test a harmless comin deployment:

1. Make a trivial repository change.
2. Commit and push it to `main`.
3. Watch comin apply the change:

   ```bash
   journalctl -u comin.service -f
   ```

## Later Hardening

After comin and Cloudflare SSH are proven reliable:

- disable SSH password authentication
- consider binding SSH to loopback only
- rename the hostname to a location-specific name
- add the Steeple Stream application service and public broadcast ingress
