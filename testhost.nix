{ config, pkgs, lib, modulesPath, disko, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    # "${modulesPath}/profiles/qemu-guest.nix"
    ./vbox-guest.nix
    disko.nixosModules.disko
  ];

  disko.devices = import ./disko-zfs-config.nix {
    disks = [ "x" "y" ];
    zpools = [ "rpool" ];
  };

  boot.loader.grub = {
    enable = true;
    version = 2;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot1"; efiSysMountPoint = "/boot1"; }
      { devices = [ "nodev" ]; path = "/boot2"; efiSysMountPoint = "/boot2"; }
    ];
  };

  services.openssh.enable = true;

  users.users.root = {
    password = "nixos";
    # openssh.authorizedKeys.keys = [
    #   ""
    # ];
  };
}
