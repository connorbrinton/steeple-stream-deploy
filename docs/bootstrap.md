# Beelink Bootstrap

1. Install NixOS on the Beelink MINI S13.
2. Clone this deployment repository.
3. Ensure the public `steeple-stream` application repository exists, then lock
   deployment inputs:

   ```bash
   nix flake lock
   git add flake.lock
   git commit -m "Lock deployment inputs"
   ```

4. Generate hardware configuration:

   ```bash
   sudo nixos-generate-config --show-hardware-config > nixos/hosts/stakecenter/hardware-configuration.nix
   ```

5. Generate the Beelink age key and copy the public recipient into `.sops.yaml`:

   ```bash
   sudo mkdir -p /var/lib/sops-nix
   sudo age-keygen -o /var/lib/sops-nix/key.txt
   sudo chmod 0400 /var/lib/sops-nix/key.txt
   sudo grep '# public key:' /var/lib/sops-nix/key.txt
   ```

6. Create real encrypted secrets:

   ```bash
   cp secrets/stakecenter.example.yaml secrets/stakecenter.yaml
   sops -e -i secrets/stakecenter.yaml
   ```

7. Run the first manual deployment:

   ```bash
   sudo nixos-rebuild switch --flake .#steeple-stream-stakecenter
   ```

8. Verify services:

   ```bash
   systemctl status steeple-stream
   systemctl status cloudflared
   systemctl status comin
   ```

After the first deployment, comin should pull and apply future changes from the
deployment repository.
