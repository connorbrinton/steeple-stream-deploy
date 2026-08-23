{
  description = "Steeple Stream Beelink appliance deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    steeple-stream.url = "github:connorbrinton/steeple-stream";
    comin.url = "github:nlewo/comin";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, steeple-stream, comin, sops-nix }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.steeple-stream-stakecenter = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit self steeple-stream; };
        modules = [
          steeple-stream.nixosModules.default
          comin.nixosModules.comin
          sops-nix.nixosModules.sops
          ./nixos/hosts/stakecenter
        ];
      };
    };
}
