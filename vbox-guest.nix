# Common configuration for virtual machines under VirtualBox (using emulated
# PIIX4 and AHCI storage and OHCI+EHCI USB 2.0 Controller).

{ config, lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod"
  ];

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  virtualisation.virtualbox.guest.enable = true;
}
