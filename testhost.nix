{ config, pkgs, lib, modulesPath, disko, ... }:

{
  imports = [
    "${modulesPath}/installer/scan/not-detected.nix"
    # "${modulesPath}/profiles/qemu-guest.nix"
    ./vbox-guest.nix
    disko.nixosModules.disko
  ];

  time.timeZone = "Europe/Budapest";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Treminus16";
    keyMap = "us";
  };

  disko.devices = (import ./disko-zfs-config.nix {
    inherit lib;
    disks = [ "x" "y" ];
    zpools = [ "rpool" ];
  }).disko.devices;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    mirroredBoots = [
      { devices = [ "nodev" ]; path = "/boot1"; efiSysMountPoint = "/boot1"; }
      { devices = [ "nodev" ]; path = "/boot2"; efiSysMountPoint = "/boot2"; }
    ];
  };

  networking.hostId = "deadbeef";

  services.openssh.enable = true;

  users.users.root = {
    password = "nixos";
    # openssh.authorizedKeys.keys = [
    #   ""
    # ];
  };

  system.stateVersion = "23.05";
}
