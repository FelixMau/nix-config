{
  config,
  lib,
  pkgs,
  ...
}:
let
  hl = config.homelab;
in
{
  # Server hardware - no integrated GPU
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    graphics.enable = false;  # Supermicro X11SSL-F has no integrated GPU
  };

  # Compressed RAM swap to prevent OOM during builds
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };
  boot = {
    supportedFilesystems = [ "nfs" ];
    zfs.forceImportRoot = true;
    kernelParams = [
      "pcie_aspm=force"
      "consoleblank=60"
      # Disable graphics to prevent ASPEED AST2400 freeze (SSH-only server)
      "nomodeset"
      "video=astdrmfb:off"
    ];
    # Blacklist problematic modules: Intel ISH (boot delays) + ASPEED ast (freeze)
    blacklistedKernelModules = [ "intel_ish_ipc" "intel_ishtp" "ast" ];
    kernelModules = [
      "coretemp"
      "jc42"
      # Server hardware modules
      "ahci"
      "xhci_pci"
    ];
  };

  networking =
    let
      # Verified via `ip link show` on new Supermicro hardware - uses eno2 naming
      mainIface = "eno2";
    in
    {
      # Enable DHCP fallback in case static config fails
      useDHCP = lib.mkDefault true;
      networkmanager.enable = false;
      hostName = "emily";
      interfaces.${mainIface} = {
        ipv4.addresses = [
          {
            address = "192.168.2.199";
            prefixLength = 24;
          }
        ];
      };
      defaultGateway = {
        address = "192.168.2.1";
        interface = mainIface;
      };
      nameservers = [ "192.168.2.1" "8.8.8.8" ];
      hostId = "0730ae51";
      firewall = {
        enable = true;
        allowPing = true;
        trustedInterfaces = [
          mainIface
          "tailscale0"
        ];
      };
    };

  zfs-root = {
    boot = {
      partitionScheme = {
        biosBoot = "-part1";
        efiBoot = "-part2";
        bootPool = "-part3";
        rootPool = "-part4";
      };
      bootDevices = [
        "ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J"
      ];
      immutable = false;  # Disabled: initrd activation was running before /var/lib mount
      availableKernelModules = [
        "uhci_hcd"
        "ehci_pci"
        "ahci"
        "sd_mod"
        "sr_mod"
      ];
      removableEfi = true;
    };
  };

  imports = [
    ../../../misc/tailscale
    ../../../misc/zfs-root
    ../../../misc/claude-cli
    ./homelab
  ];

  modules.claude-cli.enable = true;

  virtualisation.docker.storageDriver = "overlay2";

  system.autoUpgrade.enable = true;

  services.autoaspm.enable = true;
  powerManagement.powertop.enable = true;

  environment.systemPackages = with pkgs; [
    pciutils
    glances
    hdparm
    smartmontools
    cpufrequtils
    intel-gpu-tools
    powertop
    ipmitool
  ];

  tg-notify = {
    enable = true;
    credentialsFile = config.age.secrets.tgNotifyCredentials.path;
  };

  services.adiosBot = {
    enable = false;
    botTokenFile = config.age.secrets.adiosBotToken.path;
  };

  # CRITICAL FIX: Ensure D-Bus and nscd start AFTER /var/lib is mounted
  # Without this, services fail because /var/lib/dbus is not available
  systemd.services.dbus = {
    after = [ "var-lib.mount" "local-fs.target" ];
    requires = [ "var-lib.mount" ];
  };

  systemd.services.nscd = {
    after = [ "var-lib.mount" "local-fs.target" ];
    requires = [ "var-lib.mount" ];
  };

  # Ensure agenix can access SSH keys before services need secrets
  systemd.services.agenix = lib.mkIf (config.age.secrets != {}) {
    after = [ "persist.mount" "local-fs.target" ];
    requires = [ "persist.mount" ];
  };
  # IPMI fan control - set quiet fan speed on boot (Supermicro X11SSL-F)
  systemd.services.ipmi-fan-control = {
    description = "Set IPMI fan speed";
    path = [ pkgs.kmod pkgs.ipmitool ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ipmi-fan-control" ''
        modprobe ipmi_devintf
        modprobe ipmi_si
        sleep 5
        ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x24
      '';
    };
  };

  # Timer to run fan control 60 seconds after boot (BMC may reset settings)
  systemd.timers.ipmi-fan-control = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "60s";
      Unit = "ipmi-fan-control.service";
    };
  };
}
