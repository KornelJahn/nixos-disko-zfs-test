# NixOS on ZFS using disko and featuring opt-in root persistence

This experimental flake uses [disko](https://github.com/nix-community/disko) to partition two identical (virtual) disks and create a mirrored, encrypted ZFS root pool on them with "mirrored" EFI System Partitions (not sure if the latter one is a good idea though...).

:warning: The root dataset at `/` is ephemeral, being overwritten by a blank snapshot on every boot! :warning:

Opt-in persistence is achieved using the [impermanence](https://github.com/nix-community/impermanence) NixOS module. Persistent state needs to be stored within `/persistent`.

The dataset structure follows [grahamc's](https://grahamc.com/blog/erase-your-darlings/) philosophy, with datasets under `local` never backed up, only those under `safe`.

## Usage

1. Fork this flake for yourself to modify it to your liking.
2. (Optional) Prepare a VM with two identical disks. Recommended size is 16 GiB each (not pre-allocated but dynamically sized). By default, VirtualBox hypervisor is considered. For QEMU/KVM (with virtio storage), please edit `testhost.nix` and uncomment the import of `qemu-guest.nix` and comment the import of `vbox-guest.nix`.
3. Boot up a NixOS ISO (minimal ISO is recommended).
4. Fire up a Nix shell with Git and Tmux (for convenience):

        NIX_CONFIG='experimental-features = nix-command flakes' nix-shell -p git tmux --run tmux

5. Find out persistent virtual disk IDs by comparing `lsblk` and `ls -l /dev/disk/by-id` outputs and modify `testhost-disko.nix` accordingly.
6. Clone the flake using Git and switch to the repo directory.
7. Set up encryption passphrase and user passwords in advance for unattended filesystem creation and installation as:

        ./mkpass -o /tmp/pass-zpool-rpool
        ./mkpass -o /tmp/pass-user-root -a sha-512
        ./mkpass -o /tmp/pass-user-nixos -a sha-512

   Alternatively, for quick testing, execute

        ./testhost-pass

   to set all required passwords and passphrases to `password`.

8. Set target hostname as

        export TARGET_HOST=testhost

8. Partition the disks and create the zpools as

        ./provision

9. Install NixOS as

        ./install

   This script also performs some pre- and post-install operations necessary for some state to become persistent.

## Troubleshooting

### Installation

If you get the following error during NixOS installation after having edited the config,

    error: filesystem error: cannot rename: Invalid cross-device link [...] [...]

then there is likely a different underlying error, which is unfortunately masked by this one.

In that case, try to build the system config first as

    nix build .#nixosConfigurations.testhost.config.system.build.toplevel

which will then reveal the root cause for the error.

### Single-disk boot

If one is forced to do a single-disk boot (e.g. due to a failed second disk),
it may happen that one is dropped into the UEFI shell because the default ESP
is missing. In that case, available (mounted) additional spare ESPs are listed when
entering the UEFI shell or can be listed using `map -r`. Additional mirrored
(non-default) and mounted spare ESP file systems appear as `FSx`. Suppose our
spare ESP file system is `FS0`. In this case, all you need to do is to change
to that file system and find & launch the corresponding `.efi` executable of
the OS (say, `BOOTX64.EFI`) as

    FS0:
    cd EFI/BOOT
    BOOTX64.EFI

If on subsequent reboots, the EFI shell keeps coming up, it is worth examining
the boot order inside the EFI shell using

    bcfg boot dump -s

and -- if necessary -- move some entries around specifying their actual number
and the target number, e.g.

    bcfg boot mv 02 04

Credits: https://www.youtube.com/watch?v=t_7gBLUa600

### Partial partitioning and file system creation

The disko configuration of this flake is composed in a way that partitioning
and file system creation can also run on a subset of disks, e.g. when replacing
a failed disk or adding additional disks later for a new mirrored zpool
storage.

Accordingly, `provision` can be run as

     ./provision -d '[ "disk1" ]'

for partitioning of one disk only, or as

    ./provision -d '[ "disk3" "disk4" ]' -p '[ "dpool" ]'

for the creation of a new zpool `dpool` for newly added disks `disk3` and
`disk4`, which have been introduced previously to the disko config.

Note that the values of options `-d` (or `--disks`) and `-p` (or `--pools`)
must be valid (quoted) Nix expressions, lists of strings (disk and zpool names,
respectively).
