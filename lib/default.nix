{ self, nixpkgs, disko, ... }:

let
  inherit (nixpkgs) lib;

  # TODO: provide option to disable installer shell creation for certain
  # configs and return `null` instead
  mkInstallerShell' = { config, pkgs, diskoPkg }:
    pkgs.stdenvNoCC.mkDerivation {
      name = "installer-shell";
      buildInputs = with pkgs; [ coreutils util-linux mkpasswd zfs diskoPkg ];
      shellHook = ''
        export PATH="${builtins.toString ../scripts}:$PATH"
      '';

      # Environment variables
      TARGET_HOST = config.networking.hostName;
      FLAKE_DIR = builtins.toString ./..;
    };

  mkInstallerShell = name: nixosConfiguration:
    let
      inherit (nixosConfiguration.pkgs.stdenv.hostPlatform) system;
      shell = mkInstallerShell' {
        inherit (nixosConfiguration) config pkgs;
        diskoPkg = disko.packages.${system}.disko;
      };
    in
    lib.optionalAttrs (shell != null) { ${system}.${name} = shell; };

  recursiveMergeAttrs = attrsList:
    builtins.foldl' lib.recursiveUpdate { } attrsList;

in
{
  mkInstallerShells = nixosConfigurations:
    recursiveMergeAttrs (
      builtins.filter
        (x: x != { })
        (lib.mapAttrsToList mkInstallerShell nixosConfigurations)
    );
}
