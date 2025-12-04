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
  boot = {
    zfs.forceImportRoot = true;
    kernelParams = [
      "pcie_aspm=force"
      "consoleblank=60"
      # Removed nvme_core parameter - using SATA SSD, not NVMe
      # Removed acpi_enforce_resources - may conflict with Supermicro BIOS
    ];
    # Blacklist problematic Intel ISH modules causing boot delays
    blacklistedKernelModules = [ "intel_ish_ipc" "intel_ishtp" ];
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
      # FIXME: Verify actual interface name on new hardware with: ip link show
      # Supermicro X11SSL-F typically has enp2s0 or enp3s0
      mainIface = "enp2s0";  # Changed from enp1s0 for new hardware
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
      immutable = true;
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
  systemd.services.agenix = lib.mkIf config.age.secrets != {} {
    after = [ "persist.mount" "local-fs.target" ];
    requires = [ "persist.mount" ];
  };
}
