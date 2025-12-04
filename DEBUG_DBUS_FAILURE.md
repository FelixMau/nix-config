CRITICAL: System Booting But D-Bus and Core Services Failing

OBSERVED SYMPTOMS:
- System boots but shows black screen
- D-Bus System Message Bus failing repeatedly
- nscd.service failing (Name Service Cache Daemon)
- Host and Network Name Lookups failed
- User and Group Name Lookups failed
- resolvconf update failed
- Intel ISH hardware warnings

PRIORITY INVESTIGATION:

1. CHECK D-BUS SERVICE STATUS
   ```bash
   systemctl status dbus.service -l
   journalctl -u dbus.service -b -1 | tail -100
   ```

   Common D-Bus failure causes:
   - /run/dbus not writable
   - Machine ID missing/corrupt
   - User/group resolution broken
   - Filesystem mount issues

2. VERIFY CRITICAL MOUNTS
   ```bash
   mount | grep -E "(run|var|tmp)"
   ls -la /run/dbus/ 2>/dev/null || echo "PROBLEM: /run/dbus missing"
   ls -la /var/lib/dbus/ 2>/dev/null || echo "PROBLEM: /var/lib/dbus missing"
   df -h | grep -E "(run|var|tmp)"
   ```

3. CHECK MACHINE ID
   ```bash
   cat /etc/machine-id
   ls -la /var/lib/dbus/machine-id
   ```
   If missing or broken:
   ```bash
   systemd-machine-id-setup
   dbus-uuidgen --ensure
   ```

4. VERIFY USER/GROUP RESOLUTION
   ```bash
   getent passwd root
   getent group root
   getent passwd messagebus
   getent group messagebus
   id messagebus
   ```

   If user resolution broken, check:
   ```bash
   ls -la /etc/passwd /etc/group /etc/shadow
   cat /etc/nsswitch.conf
   ```

5. CHECK FILESYSTEM PERMISSIONS
   ```bash
   ls -la /run/
   ls -la /var/lib/
   ls -la /tmp/

   # D-Bus needs these writable
   test -w /run && echo "OK: /run writable" || echo "PROBLEM: /run not writable"
   test -w /var/lib && echo "OK: /var/lib writable" || echo "PROBLEM: /var/lib not writable"
   ```

6. ZFS DATASET ISSUES
   ```bash
   zfs list
   zfs get mounted,mountpoint rpool/nixos/var/lib

   # Check if /var/lib is properly mounted
   mount | grep /var/lib
   ```

7. CHECK SYSTEMD ORDERING
   ```bash
   systemctl list-dependencies dbus.service
   systemctl show dbus.service | grep -E "(Before|After|Requires|Wants)"
   ```

ROOT CAUSE ANALYSIS:

The issue is likely ONE of these:

A. **ZFS /var/lib Dataset Not Mounted Before D-Bus Starts**
   - Check: `mount | grep /var/lib`
   - Fix: Ensure proper systemd mount ordering

B. **Immutable Root Breaking /run or /var**
   - The rollback might be clearing needed directories
   - Check: Is /run a tmpfs? Is /var/lib persisted?

C. **Missing messagebus User/Group**
   - Check: `id messagebus`
   - D-Bus runs as messagebus user

D. **Corrupt Machine ID**
   - Check: `/etc/machine-id` exists and is valid UUID

E. **NSS (Name Service Switch) Broken**
   - Check: `/etc/nsswitch.conf`
   - nscd depends on working user/group lookups

RECOVERY ACTIONS:

If D-Bus failing due to /var/lib mount timing:
```bash
# Add to configuration.nix
systemd.services.dbus = {
  after = [ "var-lib.mount" ];
  requires = [ "var-lib.mount" ];
};
```

If machine-id missing:
```bash
systemd-machine-id-setup
dbus-uuidgen --ensure
```

If /run permissions wrong:
```bash
# /run should be tmpfs
mount -t tmpfs tmpfs /run -o mode=0755,nosuid,nodev
```

If NSS/user resolution broken:
```bash
# Check if systemd-sysusers ran
systemctl status systemd-sysusers.service

# Manually create messagebus user if needed
useradd -r -d /run/dbus -s /bin/false -g messagebus messagebus 2>/dev/null || true
```

TESTING AFTER FIXES:
```bash
# Test D-Bus manually
systemctl start dbus.service
systemctl status dbus.service

# If works, rebuild
nixos-rebuild boot
```

DELIVERABLES NEEDED:
1. Root cause of D-Bus failure (from logs and checks above)
2. State of /run, /var/lib mounts
3. Machine ID status
4. messagebus user existence
5. Specific fix applied
6. Verification that D-Bus starts after fix

NOTE: The network interface changes are SECONDARY. D-Bus must work first or nothing else will function properly (including display managers, login managers, etc.)
