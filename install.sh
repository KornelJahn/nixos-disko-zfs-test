#!/usr/bin/env sh

set -e

fail() {
  printf %s\\n "$1" >&2
  exit 1
}

usage="usage: $(basename $0) [-h] [-t <target-hostname>]"

hostname="$TARGET_HOSTNAME"

while [ -n "$1" ]; do
  case $1 in
    -h|--help)
      printf %s\\n "$usage"
      exit 0
      ;;
    -t)
      shift
      hostname="$1"
      shift
      ;;
  esac
done

[ -n "$hostname" ] || fail "error: target hostname not configured\\n\\n$usage"

set -x

# Pre-installation tasks
sudo mkdir -p /mnt/persistent/etc
sudo cp -a /etc/machine-id /mnt/persistent/etc/
sudo mkdir -p /mnt/persistent/etc/ssh

# Installation
sudo nixos-install --flake ".#$hostname" --no-root-passwd

# Post-installation tasks
sudo mv /mnt/etc/ssh/authorized_keys.d /mnt/persistent/etc/ssh/
sudo umount /mnt/boot
sudo zpool export rpool
