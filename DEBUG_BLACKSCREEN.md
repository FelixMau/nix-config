# Black Screen Recovery & Debug Guide

## Situation
System boots to black screen after applying configuration changes for new hardware.

## Changes Made Before Black Screen
1. Network interface: `enp1s0` → `enp2s0` in `modules/machines/nixos/_common/default.nix:115`
2. Kernel modules updated in `modules/machines/nixos/emily/configuration.nix:76-82`:
   - Removed: `uhci_hcd`, `ehci_pci`, `sr_mod`
   - Added: `xhci_pci`, `usb_storage`, `usbhid`

## IMMEDIATE RECOVERY STEPS

### Step 1: Boot into NixOS Installer/Recovery
1. Boot from NixOS installer USB
2. Import ZFS pools:
   ```bash
   zpool import -f bpool
   zpool import -f rpool
   ```

### Step 2: Mount the System
Run the mount script:
```bash
# Mount root
mkdir -p /mnt/nixos
mount -t zfs rpool/nixos/empty /mnt/nixos

# Create directories
mkdir -p /mnt/nixos/{boot,etc/nixos,home,nix,var/lib,var/log,persist}

# Mount all datasets
mount -t zfs bpool/nixos/root /mnt/nixos/boot
mount -t zfs rpool/nixos/config /mnt/nixos/etc/nixos
mount -t zfs rpool/nixos/home /mnt/nixos/home
mount -t zfs rpool/nixos/nix /mnt/nixos/nix
mount -t zfs rpool/nixos/var/lib /mnt/nixos/var/lib
mount -t zfs rpool/nixos/var/log /mnt/nixos/var/log
mount -t zfs rpool/nixos/persist /mnt/nixos/persist

# Mount EFI
mkdir -p /mnt/nixos/boot/efis/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J-part2
mount /dev/disk/by-id/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J-part2 /mnt/nixos/boot/efis/ata-Samsung_SSD_860_EVO_500GB_S3Z2NB0KC53819J-part2
```

### Step 3: Check Boot Logs
```bash
# Enter the system
nixos-enter --root /mnt/nixos

# Check journal from last boot
journalctl -b -1 | tail -200

# Check for boot failures
journalctl -b -1 | grep -i "fail\|error\|fatal"

# Check systemd failed units
journalctl -b -1 | grep "Failed to start"
```

## DEBUGGING CHECKLIST

### 1. Display/Console Issues
```bash
# Check if system actually booted but display is wrong
# Check dmesg for ASPEED/drm errors
dmesg | grep -i "aspeed\|drm\|console\|fb"

# Check if getty is running
systemctl status getty@tty1

# Try switching to different TTY
# Press: Ctrl+Alt+F2, Ctrl+Alt+F3, etc.
```

### 2. Network Configuration Issues
The network change might prevent boot if something waits for network:

```bash
# Check network services
systemctl status network-addresses-enp2s0
systemctl list-jobs

# Check if stuck waiting for network
journalctl -b -1 | grep -i "network\|enp"
```

**POTENTIAL FIX**: Revert network interface change:
```bash
cd /mnt/nixos/etc/nixos
# Edit: modules/machines/nixos/_common/default.nix
# Change line 115 back to: "enp1s0"
# OR add fallback: useDHCP = lib.mkDefault true;
```

### 3. Kernel Module Issues
The kernel module changes might prevent USB keyboard or display:

```bash
# Check if modules loaded
lsmod | grep -i "xhci\|usb"

# Check kernel messages
dmesg | grep -i "usb\|module"
```

**POTENTIAL FIX**: Revert kernel modules:
```bash
cd /mnt/nixos/etc/nixos
# Edit: modules/machines/nixos/emily/configuration.nix
# Restore original boot.kernelModules (lines 36-42):
kernelModules = [
  "coretemp"
  "jc42"
  "lm78"
  "f71882fg"
];
```

### 4. ZFS Import Issues
```bash
# Check ZFS import during boot
journalctl -b -1 | grep -i "zfs\|pool"

# Check if rollback failed
journalctl -b -1 | grep -i "rollback"

# Verify pools are healthy
zpool status
```

### 5. GRUB/Boot Issues
```bash
# Check GRUB configuration
cat /mnt/nixos/boot/grub/grub.cfg | grep -A5 "menuentry"

# Check kernel exists
ls -lh /mnt/nixos/boot/kernels/

# Verify EFI entry
efibootmgr -v
```

## RECOVERY ACTIONS

### Option A: Rollback to Previous Generation (SAFEST)
```bash
nixos-enter --root /mnt/nixos

# List generations
nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous
nix-env --rollback --profile /nix/var/nix/profiles/system

# Update bootloader
/nix/var/nix/profiles/system/bin/switch-to-configuration boot

# Reboot
reboot
```

### Option B: Fix Configuration and Rebuild
```bash
nixos-enter --root /mnt/nixos

# Fix issues found above in /etc/nixos/

# Test configuration
nixos-rebuild dry-build

# Apply if successful
nixos-rebuild boot

# Reboot
reboot
```

### Option C: Emergency Network-Only Boot
Add to configuration temporarily:
```bash
cd /mnt/nixos/etc/nixos
# Edit modules/machines/nixos/emily/configuration.nix

# Add after networking section:
systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
networking.useDHCP = true;
services.openssh.enable = true;

# Rebuild
nixos-rebuild boot --root /mnt/nixos

# Then SSH in after reboot to continue debugging
```

## MOST LIKELY CAUSES (Priority Order)

1. **Network interface misconfiguration** - System may be waiting for enp2s0 that doesn't exist or is named differently
   - FIX: Revert to enp1s0 OR use useDHCP

2. **Console/Display driver** - ASPEED IPMI graphics not initializing
   - FIX: Add `nomodeset` to kernel params temporarily
   - Or check IPMI/BIOS settings for display

3. **Kernel modules** - USB modules preventing keyboard/console
   - FIX: Revert to original kernelModules list

4. **Systemd service timeout** - Something waiting indefinitely
   - FIX: Check `systemctl list-jobs` and add timeouts

## Quick Commands Reference

```bash
# From installer
zpool import -f bpool && zpool import -f rpool
mount -t zfs rpool/nixos/empty /mnt/nixos
# ... mount rest ...
nixos-enter --root /mnt/nixos

# Inside system
journalctl -b -1 | grep -i error
nix-env --list-generations --profile /nix/var/nix/profiles/system
nix-env --rollback --profile /nix/var/nix/profiles/system
/nix/var/nix/profiles/system/bin/switch-to-configuration boot
```

## After Recovery

Once system boots successfully:
1. Apply changes ONE AT A TIME
2. Test each change with `nixos-rebuild test` first
3. Only make permanent with `nixos-rebuild switch` after verifying
4. Keep network changes separate from kernel module changes
