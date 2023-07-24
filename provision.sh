#!/usr/bin/env sh
sudo nix run github:nix-community/disko \
  --extra-experimental-features nix-command \
  -- \
  --mode disko ./disko-zfs-config.nix \
  --arg disks '[ "x" "y" ]' \
  --arg zpools '[ "rpool" ]'
