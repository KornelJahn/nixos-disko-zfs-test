{ self, nixpkgs, ... }:

let
  scripts = {
    mkpass = pkgs: pkgs.writeShellApplication {
      name = "mkpass";
      text = builtins.readFile ../scripts/mkpass;
      runtimeInputs = with pkgs; [ mkpasswd ];
    };

    provision = pkgs: pkgs.writeShellApplication {
      name = "provision";
      test = builtins.readFile ../scripts/provision;
      runtimeInputs = with pkgs; [ ];
    };

    install = pkgs: pkgs.writeShellApplication {
      name = "install";
      text = builtins.readFile ../scripts/install;
      runtimeInputs = with pkgs; [
        coreutils # cp mkdir
        util-linux # umount
        zfs
      ];
    };
  };

  # TODO: provide option to disable installer shell creation for certain
  # configs and return `null` instead
  mkInstallerShell' = { config, pkgs }: pkgs.stdenvNoCC.mkDerivation {
    name = "installer-shell";
    buildInputs = map (f: f pkgs) (builtins.attrValues scripts);
    TARGET_HOST = config.networking.hostName;
  };

  mkInstallerShell = name: nixosConfiguration:
    let
      inherit (nixosConfiguration.pkgs.stdenv.hostPlatform) system;
      shell = mkInstallerShell' { inherit (nixosConfiguration) config pkgs; };
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
