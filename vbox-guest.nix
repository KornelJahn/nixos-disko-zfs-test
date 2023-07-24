{ config, pkgs, lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod"
  ];

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  virtualisation.virtualbox.guest.enable = true;
}
