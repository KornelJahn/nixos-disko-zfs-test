#!/usr/bin/env bash

set -e

fail() { echo -e "$1" >&2; exit 1; }

usage="usage: $(basename $0) [-h] [-t <target-hostname>] "
usage+='[-d <disks-list-nix-expr>] [-p <zpools-list-nix-expr>] '
usage+='[<extra-disko-args>...]'

hostname="${TARGET_HOSTNAME:-}"
config_nix_args=
disko_args=

while [ -n "$1" ]; do
  case $1 in
    -h|--help)
      echo "$usage"
      exit 0
      ;;
    -t)
      shift
      hostname="$1"
      shift
      ;;
    -d)
      shift
      config_nix_args+="--arg disks $1 "
      shift
      ;;
    -p)
      shift
      config_nix_args+="--arg zpools $1 "
      shift
      ;;
    *)
      disko_args+="$1 "
      shift
      ;;
  esac
done

[ -n "$hostname" ] || fail "error: target hostname not configured\n\n$usage"

set -x

sudo nix run github:nix-community/disko \
  --extra-experimental-features 'nix-command flakes' \
  -- \
  $disko_args \
  --mode disko "./$hostname-disko.nix" \
  $config_nix_args
