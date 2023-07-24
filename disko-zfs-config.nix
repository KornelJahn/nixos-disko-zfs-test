{ lib, disks, zpools, ... }:

let
  devices = {
    disk = {
      x = {
        type = "disk";
        device = "/dev/disk/by-id/ata-VBOX_HARDDISK_VBafedd100-67286476";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "64M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot1";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          }; # partitions
        }; # content
      }; # x
      y = {
        type = "disk";
        device = "/dev/disk/by-id/ata-VBOX_HARDDISK_VBc909afa2-42881324";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "64M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot2";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          }; # partitions
        }; # content
      }; # y
    }; # disk
    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          compression = "lz4";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          local = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          safe = {
            type = "zfs_fs";
            options.mountpoint = "none";
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///tmp/secret.key";
            };
            postCreateHook = ''
              zfs set keylocation="prompt" rpool/safe
            '';
          };
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
            postCreateHook = ''
              zfs snapshot rpool/local/root@blank
            '';
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          "local/log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";
            options.mountpoint = "legacy";
          };
          "safe/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };
        }; # datasets
      }; # zroot
    }; # zpool
  }; # devices
in
{
  disko.devices = {
    disk = lib.filterAttrs (n: v: builtins.elem n disks) devices.disk;
    zpool = lib.filterAttrs (n: v: builtins.elem n zpools) devices.zpool;
  };
}
