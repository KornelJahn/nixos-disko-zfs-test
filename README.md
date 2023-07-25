# NixOS on ZFS using disko and featuring opt-in root persistence

This experimental flake uses [disko](https://github.com/nix-community/disko) to partition two identical (virtual) disks and create a mirrored, encrypted ZFS root pool on them with "mirrored" EFI System Partitions (not sure if the latter one is a good idea though...).

:warning: The root dataset at `/` is ephemeral, being overwritten by a blank snapshot on every boot! :warning:

Opt-in persistence is achieved using the [impermanence](https://github.com/nix-community/impermanence) NixOS module. Persistent state needs to be stored within `/persistent`.

The dataset structure follows [grahamc's](https://grahamc.com/blog/erase-your-darlings/) philosophy, with datasets under `local` never backed up, only those under `safe`.

## Usage

1. Fork this flake for yourself to modify it to your liking.
2. (Optional) Prepare a VM with two identical disks. By default, VirtualBox hypervisor is considered. For QEMU/KVM, please edit `testhost.nix`.
3. Boot up a NixOS ISO (minimal ISO is recommended).
4. Fire up a Nix shell with Git and Tmux (for convenience):

        NIX_CONFIG='experimental-features = nix-command flakes' nix-shell -p git tmux --run tmux

5. Find out persistent virtual disk IDs by comparing `lsblk` and `ls -l /dev/disk/by-id` outputs and modify `testhost-disko.nix` accordingly.
6. Clone the flake using Git and switch to the repo directory.
7. Partition the disks and create the zpools as

        ./provision.bash testhost

8. Install NixOS as

        ./install.bash testhost

   This script also performs some pre- and post-install operations necessary for some state to become persistent.
