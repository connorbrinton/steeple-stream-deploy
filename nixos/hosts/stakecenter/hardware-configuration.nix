{ lib, ... }:

{
  # Replace this placeholder with the file generated on the Beelink:
  #
  #   sudo nixos-generate-config --show-hardware-config > nixos/hosts/stakecenter/hardware-configuration.nix
  #
  # The placeholder exists so the repository has the expected path before the
  # appliance arrives. It is intentionally not bootable.
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
}
