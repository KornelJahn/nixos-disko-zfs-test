#!/usr/bin/env sh

set -e

sname="$(basename $0)"
usage="usage: $sname <disko-nix-config> "
usage+='[-d <disks-list-nix-expr>] [-p <zpools-list-nix-expr>] '
usage+='[<extra-disko-args>...]'

if [ $# -lt 1 ]; then
    printf %s\\n "$usage"
    exit 1
fi

config_nix="$1"
shift

config_nix_args=
disko_args=
while [ -n "$1" ]; do
    case $1 in
        -d)
            config_nix_args+="--arg disks $1 "
            shift
            ;;
        -p)
            config_nix_args+="--arg zpools $1 "
            shift
            ;;
        *)
            disko_args+="$1 "
            shift
            ;;
    esac
done

set -x

sudo nix run github:nix-community/disko \
  --extra-experimental-features 'nix-command flakes' \
  -- \
  --mode disko "$config_nix" \
  $config_nix_args \
  $disko_args
