{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
