{
  description = "Steeple Stream Beelink appliance deployment";

  inputs = {
    steeple-stream.url = "github:connorbrinton/steeple-stream";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, comin, sops-nix, steeple-stream, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          comin.nixosModules.comin
          sops-nix.nixosModules.sops
          ./nixos/hosts/stakecenter
          {
            environment.systemPackages = [ steeple-stream.packages.${system}.steeple-stream ];
          }
        ];
      };
    };
}
