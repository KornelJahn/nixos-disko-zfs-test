{
  description = "NixOS on a mirrored ZFS pool using disko.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, ... } @ inputs: {
    nixosConfigurations.testhost = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [ ./testhost.nix ];
    };
  };
}
