# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a NixOS flake-based configuration for homelab servers. It manages multiple machines with extensive self-hosted services using a modular architecture.

## Common Commands

```bash
# Deploy to a host (copies config via rsync, then builds remotely)
just deploy <hostname>

# Dry run to preview changes
just dry-run <hostname>

# Copy config to host without deploying
just copy <hostname>

# Update flake inputs
just update

# Check flake validity
just check
```

## Architecture

### Flake Structure
- **flake.nix**: Entry point using flake-parts. Defines inputs (nixpkgs 25.05, home-manager, agenix, custom flakes) and imports machine configurations.
- **modules/machines/nixos/default.nix**: Auto-discovers machines by scanning for `configuration.nix` files. Each subdirectory with a `configuration.nix` becomes a NixOS configuration.

### Module Organization
- **modules/machines/nixos/**: Per-machine configurations (emily, etc.)
  - `_common/`: Shared base config (filesystems, nix settings, monitoring)
  - `<hostname>/configuration.nix`: Machine-specific hardware and services
  - `<hostname>/homelab/default.nix`: Machine's homelab service enablements
- **modules/homelab/**: Homelab framework
  - `default.nix`: Core options (mounts, user/group, baseDomain, timeZone)
  - `services/`: Individual service modules (each in its own directory)
- **modules/misc/**: Standalone modules (agenix, tailscale, zfs-root, mover, etc.)
- **modules/users/**: User configuration (bricklayer user with home-manager dots)
- **modules/dots/**: Dotfile configurations (nvim, tmux, zsh, kitty)

### Secret Management
Uses **agenix** for encrypted secrets:
- Secrets stored in private repo: `github:FelixMau/nix-private`
- Decryption key: `/persist/ssh/ssh_host_ed25519_key`
- Secrets decrypt to `/run/agenix/<name>` at runtime
- Define new secrets in `secrets/secrets.nix` and `modules/misc/agenix/default.nix`

### Homelab Services Pattern
Each service module in `modules/homelab/services/<service>/default.nix` follows this pattern:
```nix
{
  options.homelab.services.<service> = {
    enable = lib.mkEnableOption "...";
    # Service-specific options
  };
  config = lib.mkIf cfg.enable {
    # Service configuration using config.homelab.* for common paths/settings
  };
}
```

Key homelab options available to all services:
- `config.homelab.baseDomain`: Base domain for reverse proxy (e.g., "brick-layer.org")
- `config.homelab.mounts.{config,slow,fast,merged}`: Storage paths
- `config.homelab.{user,group}`: Service user/group (default: "share")
- `config.homelab.timeZone`: Timezone for services

### Reverse Proxy
Caddy handles reverse proxying with automatic HTTPS via Cloudflare DNS challenge. Services register their virtual hosts in the Caddy config.

### External Access
Some services use Cloudflare Tunnels (cloudflared) for external access without exposing ports.

### Storage Tiers
- `mounts.fast`: SSD/NVMe cache
- `mounts.slow`: HDD storage (mergerfs)
- `mounts.merged`: Combined view
- `mounts.config`: Service persistent data (/persist/opt/services)

## Adding a New Service

1. Create `modules/homelab/services/<service>/default.nix` with enable option
2. Import it in `modules/homelab/services/default.nix`
3. Enable in machine's homelab config (e.g., `modules/machines/nixos/emily/homelab/default.nix`)
4. Add any required secrets to agenix configuration
