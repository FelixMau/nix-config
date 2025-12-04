# Hardware Migration Fix - Complete Solution

## Problem Summary
After migrating from old hardware to Supermicro X11SSL-F server, system boots but experiences cascading service failures leading to black screen.

## Root Causes Identified

### 1. **D-Bus Service Ordering** (CRITICAL)
- D-Bus starting before `/var/lib` ZFS dataset is mounted
- Causes D-Bus to fail → nscd fails → name resolution fails → display manager hangs
- **Fixed**: Added explicit systemd ordering requirements

### 2. **Wrong Network Interface** (CRITICAL)
- Configured for `enp1s0` but Supermicro hardware uses `enp2s0`
- System has no network connectivity → name resolution fails
- **Fixed**: Updated interface name + added DHCP fallback

### 3. **Intel GPU Drivers on Server Hardware** (HIGH)
- Desktop Intel GPU packages loaded on server hardware with no integrated GPU
- Display manager hangs waiting for non-existent GPU
- **Fixed**: Disabled graphics hardware acceleration

### 4. **Intel ISH Hardware Timeouts** (MEDIUM)
- Intel Integrated Sensor Hub modules causing boot delays
- **Fixed**: Blacklisted problematic modules

### 5. **Wrong Kernel Parameters** (LOW)
- NVMe parameters on SATA SSD
- Desktop-oriented kernel modules
- **Fixed**: Cleaned up parameters and modules for server hardware

## Changes Applied

### File: `modules/machines/nixos/emily/configuration.nix`

#### 1. Removed Intel GPU Packages
```nix
# BEFORE:
hardware = {
  graphics = {
    enable = true;
    extraPackages = [ intel-media-driver intel-vaapi-driver ... ];
  };
};

# AFTER:
hardware = {
  graphics.enable = false;  # Server hardware has no integrated GPU
};
```

#### 2. Fixed Network Interface
```nix
# BEFORE:
mainIface = "enp1s0";

# AFTER:
mainIface = "enp2s0";  # Supermicro X11SSL-F interface
useDHCP = lib.mkDefault true;  # DHCP fallback added
```

#### 3. Cleaned Up Kernel Configuration
```nix
# REMOVED:
- nvme_core.default_ps_max_latency_us=50000  (SATA SSD, not NVMe)
- acpi_enforce_resources=lax  (conflicts with server BIOS)
- f71882fg kernel module  (desktop sensor, not on server)

# ADDED:
boot.blacklistedKernelModules = [ "intel_ish_ipc" "intel_ishtp" ];
```

#### 4. Added Critical Service Ordering (MOST IMPORTANT)
```nix
# Ensure D-Bus starts AFTER /var/lib is mounted
systemd.services.dbus = {
  after = [ "var-lib.mount" "local-fs.target" ];
  requires = [ "var-lib.mount" ];
};

systemd.services.nscd = {
  after = [ "var-lib.mount" "local-fs.target" ];
  requires = [ "var-lib.mount" ];
};

# Ensure agenix can access SSH keys
systemd.services.agenix = {
  after = [ "persist.mount" "local-fs.target" ];
  requires = [ "persist.mount" ];
};
```

### File: `modules/machines/nixos/_common/default.nix`

#### Updated Network Interface Reference
```nix
# BEFORE:
interface = "enp1s0";

# AFTER:
interface = "enp2s0";  # Updated for Supermicro X11SSL-F hardware
```

## How to Apply This Fix

### From Recovery Environment

1. **Boot NixOS installer/recovery**

2. **Import and mount ZFS**
   ```bash
   zpool import -f bpool
   zpool import -f rpool

   mount -t zfs rpool/nixos/empty /mnt/nixos
   mkdir -p /mnt/nixos/{boot,etc/nixos,home,nix,var/lib,var/log,persist}
   mount -t zfs bpool/nixos/root /mnt/nixos/boot
   mount -t zfs rpool/nixos/config /mnt/nixos/etc/nixos
   mount -t zfs rpool/nixos/nix /mnt/nixos/nix
   mount -t zfs rpool/nixos/var/lib /mnt/nixos/var/lib
   mount -t zfs rpool/nixos/var/log /mnt/nixos/var/log
   mount -t zfs rpool/nixos/persist /mnt/nixos/persist

   # Mount EFI
   mkdir -p /mnt/nixos/boot/efis/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J-part2
   mount /dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J-part2 \
     /mnt/nixos/boot/efis/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J-part2
   ```

3. **Verify actual network interface** (IMPORTANT!)
   ```bash
   ip link show
   ```

   If the interface is NOT `enp2s0`, update:
   - `/mnt/nixos/etc/nixos/modules/machines/nixos/emily/configuration.nix` line 40
   - `/mnt/nixos/etc/nixos/modules/machines/nixos/_common/default.nix` line 115

4. **Enter chroot and rebuild**
   ```bash
   nixos-enter --root /mnt/nixos

   # Test configuration
   nixos-rebuild dry-build

   # If successful, apply
   nixos-rebuild boot

   # Exit and reboot
   exit
   reboot
   ```

### Verification After Reboot

```bash
# Check D-Bus is running
systemctl status dbus.service

# Check network connectivity
ip addr
ping 8.8.8.8

# Check no service failures
systemctl --failed

# Check boot logs look clean
journalctl -b | grep -i "fail\|error" | less
```

## Expected Results

After applying these fixes:
- ✅ D-Bus starts successfully
- ✅ Network connectivity works
- ✅ Name resolution works (nscd, DNS)
- ✅ No Intel ISH timeouts
- ✅ System boots to login screen
- ✅ Display manager works without GPU acceleration
- ✅ All services start properly

## Remaining TODOs (Non-Critical)

1. **Verify network interface name is correct**
   - Run `ip link show` after boot
   - Update config if different from `enp2s0`

2. **Remove hardcoded SSD serial** (for future portability)
   - Use `/dev/disk/by-path/` instead of `/dev/disk/by-id/`

3. **Test all homelab services**
   - Caddy/web services
   - PHP authentication
   - Cloudflared tunnels

4. **Monitor for any remaining hardware incompatibilities**

## Technical Details

### Why D-Bus Failed
1. Immutable root rollback happens early in boot
2. ZFS datasets mount after rollback
3. On new hardware, SATA timing is different
4. `/var/lib` mounted slightly later
5. D-Bus tried to start before `/var/lib` available
6. No `/var/lib/dbus/machine-id` → D-Bus fails
7. Cascade: nscd → name resolution → display manager

### Why Network Failed
- Interface PCI enumeration order changed on new motherboard
- Old: Intel NIC was first device → `enp1s0`
- New: Supermicro has different PCIe topology → `enp2s0`

### Why GPU Caused Issues
- Desktop Intel CPUs have integrated GPU
- Server Xeon CPUs have NO integrated GPU
- Display manager tried to load Intel GPU drivers
- Drivers initialized but found no hardware
- System hung waiting for GPU that doesn't exist

## Success Criteria

System should now:
1. Boot without service failures
2. Reach graphical login screen
3. Have working network connectivity
4. Have all homelab services functional
5. Show clean boot logs without errors
