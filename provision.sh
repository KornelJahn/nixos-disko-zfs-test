#!/usr/bin/env sh

if [ -n "$1" ]; then
  sudo nix run github:nix-community/disko \
    --extra-experimental-features 'nix-command flakes' \
    -- \
    --mode disko ./disko-zfs-config.nix \
    --arg disks "[ \"$1\" ]"
else
  sudo nix run github:nix-community/disko \
    --extra-experimental-features 'nix-command flakes' \
    -- \
    --mode disko ./disko-zfs-config.nix \
    --arg disks '[ "x" "y" ]' \
    --arg zpools '[ "rpool" ]'
fi
