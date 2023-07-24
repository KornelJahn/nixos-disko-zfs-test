{
  description = "NixOS on a mirrored ZFS pool using disko.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... } @ attrs: {
    nixosConfigurations.testhost = nixpkgs.lib.nixosSystem {
      specialArgs = attrs;
      modules = [ ./testhost.nix ];
    };
  };
}
