{ config, pkgs, lib, inputs, ... }:

let
  arcMaxMiB = 512;

  rootDiffScript = pkgs.writeShellScriptBin "my-root-diff" ''
    ${pkgs.zfs}/bin/zfs diff rpool/local/root@blank
  '';

  filterExistingGroups = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [
    inputs.nixpkgs.nixosModules.notDetected
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    # ./qemu-guest.nix"
    ./vbox-guest.nix
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "weekly";
    };
    package = pkgs.nixVersions.nix_2_16;
    settings = {
      warn-dirty = false;
      trusted-users = [ "root" "@wheel" ];
      auto-optimise-store = true;
    };

    # Credits: Misterio77
    # https://raw.githubusercontent.com/Misterio77/nix-config/e227d8ac2234792138753a0153f3e00aec154c39/hosts/common/global/nix.nix

    # Add each flake input as a registry
    registry = lib.mapAttrs (_: v: { flake = v; }) inputs;

    # Map registries to channels (useful when using legacy commands)
    nixPath = lib.mapAttrsToList
      (n: v: "${n}=${v.to.path}")
      config.nix.registry;
  };

  nixpkgs.config.allowUnfree = true;

  boot = {
    # Activate opt-in impermanence
    initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r rpool/local/root@blank
    '';

    kernelParams = [
      "nohibernate"
      # WORKAROUND: get rid of error
      # https://github.com/NixOS/nixpkgs/issues/35681
      "systemd.gpt_auto=0"
      "zfs.zfs_arc_max=${toString (arcMaxMiB * 1048576)}"
    ];

    loader.grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        { devices = [ "nodev" ]; path = "/boot1"; efiSysMountPoint = "/boot1"; }
        { devices = [ "nodev" ]; path = "/boot2"; efiSysMountPoint = "/boot2"; }
      ];
    };
  };

  time.timeZone = "Europe/Budapest";

  console = {
    font = "ter-v22n";
    keyMap = "us";
    packages = [ pkgs.terminus_font ];
    earlySetup = true;
  };

  i18n.defaultLocale = "en_US.UTF-8";

  # neededForBoot flag is not settable from disko
  fileSystems = {
    "/var/log".neededForBoot = true;
    "/persistent".neededForBoot = true;
  };

  networking = {
    hostName = "testhost";
    # Generate host ID from hostname
    hostId = builtins.substring 0 8 (
      builtins.hashString "sha256" config.networking.hostName
    );
    # useDHCP = false;
    # networkmanager.enable = true;
  };

  environment = {
    persistence."/persistent" = {
      hideMounts = true;
      directories = [
        # {
        #   directory = "/etc/NetworkManager/system-connections";
        #   mode = "u=rwx,g=,o=";
        # }
        "/etc/ssh/authorized_keys.d"
        "/var/lib/upower"
      ];
      files = [
        "/etc/adjtime"
        "/etc/machine-id"
        "/etc/zfs/zpool.cache"
      ];
    };

    systemPackages = [ rootDiffScript ];
  };

  programs = {
    git.enable = true;
    tmux.enable = true;
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };

  services = {
    openssh = {
      enable = true;
      hostKeys = [
        {
          bits = 4096;
          path = "/persistent/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
        {
          path = "/persistent/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };

    zfs = {
      trim.enable = true;
      autoScrub = {
        enable = true;
        pools = [ "rpool" ];
      };
    };
  };

  security.sudo.extraConfig = ''
    # Rollback results in sudo lectures after each reboot
    Defaults lecture = never
  '';

  systemd = {
    enableEmergencyMode = false;

    # Explicitly disable ZFS mount service since we rely on legacy mounts
    services.zfs-mount.enable = false;

    extraConfig = ''
      DefaultTimeoutStartSec=20s
      DefaultTimeoutStopSec=10s
    '';
  };

  users = {
    mutableUsers = false;
    users.root = {
      passwordFile = "/persistent/etc/pass-user-root";
      # openssh.authorizedKeys.keys = [
      #   ""
      # ];
    };
    users.nixos = {
      uid = 1000;
      isNormalUser = true;
      passwordFile = "/persistent/etc/pass-user-nixos";
      # openssh.authorizedKeys.keys = [
      #   ""
      # ];
      extraGroups = [
        "wheel"
      ] ++ filterExistingGroups [
        "networkmanager"
      ];
    };
  };

  system.stateVersion = "23.05";

} // (import ./testhost-disko.nix { inherit lib; })
