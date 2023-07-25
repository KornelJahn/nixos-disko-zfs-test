# NixOS on ZFS using disko

This experimental flake uses [disko](https://github.com/nix-community/disko) to partition two identical (virtual) disks and create a mirrored, encrypted ZFS root pool on them with "mirrored" EFI System Partitions (not sure if the latter one is a good idea though...).

The dataset structure follows [grahamc's](https://grahamc.com/blog/erase-your-darlings/) philosophy, with datasets under `local` never backed up, only those under `safe`. Implementing impermanence (erasing `/` on every boot by restoring a blank snapshot) is on-going...

## Usage

1. Fork this flake for yourself to modify it to your liking.
2. (Optional) Prepare a VirtualBox or QEMU-based VM with two identical disks.
3. Boot up a NixOS ISO (minimal ISO is recommended).
4. Fire up a Nix shell with Git and Tmux (for convenience):

        NIX_CONFIG='experimental-features = nix-command flakes' nix-shell -p git tmux --run tmux

5. Find out the disk IDs by comparing `lsblk` and `ls -l /dev/disk/by-id` outputs and modify `testhost-disko.nix` accordingly.
6. Clone the flake in Nix shell and enter the repo directory
7. Execute `provision.sh` to partition the disks and create the zpools:

        ./provision.sh testhost-disko.nix

8. Install NixOS by executing

        sudo nixos-install --flake .#testhost --no-root-passwd

## To-do list

- Complete impermanence
