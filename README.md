# NixOS on ZFS using disko and featuring opt-in root persistence

This experimental flake uses [disko](https://github.com/nix-community/disko) to partition two identical (virtual) disks and create a mirrored, encrypted ZFS root pool on them with "mirrored" EFI System Partitions (not sure if the latter one is a good idea though...).

:warning: The root dataset at `/` is ephemeral, being overwritten by a blank snapshot on every boot! :warning:

Opt-in persistence is achieved using the [impermanence](https://github.com/nix-community/impermanence) NixOS module. Persistent state needs to be stored within `/persistent`.

The dataset structure follows [grahamc's](https://grahamc.com/blog/erase-your-darlings/) philosophy, with datasets under `local` never backed up, only those under `safe`.

## Usage

1. (Optional) Prepare a VM with two identical disks. Recommended size is 16 GiB each (not pre-allocated but dynamically sized). By default, VirtualBox hypervisor is considered but QEMU/KVM (with virtio storage) is also supported.

2. Boot up a NixOS ISO (minimal ISO is recommended).

3. Find out persistent virtual disk block device paths by comparing `lsblk` and `ls -l /dev/disk/by-id` outputs.

4. Fork this flake for yourself and modify it according to your personal preferences. Importantly, switch imports in `hosts/testhost.nix` from `hosts/vbox-guest.nix` to `hosts/qemu-guest.nix` if using QEMU/KVM as hypervisor and replace the disk block device paths in `hosts/testhost-disko.nix` by the paths found in the previous step.

5. There are two ways to jump into an installer Nix devshell of your forked flake for `testhost`:

    1. Fire up a Nix shell with Git:

             NIX_CONFIG='experimental-features = nix-command flakes' nix-shell -p git

       Then clone your flake using Git, switch to the repo directory, and enter
       the `testhost` installer shell as

           nix develop .#testhost

       The source code of the flake is editable in this case.

    2. Enter the flake devshell directly by referencing the repo in `nix develop`. E.g. for this repo:

           nix develop --extra-experimental-features 'nix-command flakes' github:KornelJahn/nixos-disko-zfs-test#testhost

       The source code of the flake resides in the Nix store in this case and is therefore read-only.

6. Set up encryption passphrase and user passwords in advance for unattended filesystem creation and installation as:

        my-mkpass /tmp/pass-zpool-rpool
        my-mkpass -a sha-512 /tmp/pass-user-root
        my-mkpass -a sha-512 /tmp/pass-user-nixos

   Alternatively, for quick testing, execute

        $FLAKE_DIR/hosts/testhost-pass

   to set all required passwords and passphrases to `password`.

7. Partition the disks and create the zpools by executing `my-provision`.

8. Install NixOS by executing `my-install`. This custom command also performs some pre- and post-install operations necessary for some state to become persistent.

## Troubleshooting

### Installation

If you get the following error during NixOS installation after having edited the config,

    error: filesystem error: cannot rename: Invalid cross-device link [...] [...]

then there is likely a different underlying error, which is unfortunately masked by this one.

In that case, try to build the system config first as

    nix build .#nixosConfigurations.testhost.config.system.build.toplevel

which will then reveal the root cause for the error.

### Single-disk boot

If one is forced to do a single-disk boot (e.g. due to a failed second disk), it may happen that one is dropped into the UEFI shell because the default ESP is missing. In that case, available (mounted) additional spare ESPs are listed when entering the UEFI shell or can be listed using `map -r`. Additional mirrored (non-default) and mounted spare ESP file systems appear as `FSx`. Suppose our
spare ESP file system is `FS0`. In this case, all you need to do is to change to that file system and find & launch the corresponding `.efi` executable of the OS (say, `BOOTX64.EFI`) as

    FS0:
    cd EFI/BOOT
    BOOTX64.EFI

If on subsequent reboots, the EFI shell keeps coming up, it is worth examining the boot order inside the EFI shell using

    bcfg boot dump -s

and -- if necessary -- move some entries around specifying their actual number and the target number, e.g.

    bcfg boot mv 02 04

Credits: https://www.youtube.com/watch?v=t_7gBLUa600

### Partial partitioning and file system creation

The disko configuration of this flake is composed in a way that partitioning and file system creation can also run on a subset of disks, e.g. when replacing a failed disk or adding additional disks later for a new mirrored zpool storage.

Accordingly, inside the installer shell `my-provision` can be run as

    my-provision -d '[ "disk1" ]'

for partitioning of one disk only, or as

    my-provision -d '[ "disk3" "disk4" ]' -p '[ "dpool" ]'

for the creation of a new zpool `dpool` for newly added disks `disk3` and `disk4`, which have been introduced previously to the disko config.

Note that the values of options `-d` and `-p` must be valid (quoted) Nix expressions, lists of strings (disk and zpool names, respectively).
