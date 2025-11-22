{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  hl = config.homelab;
in
{
  homelab = {
    enable = true;
    baseDomain = "cloud.brick-layer";
    cloudflare.dnsCredentialsFile = "/persist/secrets/cloudflareDnsApiCredentials";
    timeZone = "Europe/Berlin";
    mounts = {
      config = "/persist/opt/services";
      slow = "/mnt/data";
      fast = "/mnt/data";
      merged = "/mnt/data";
    };
    samba = {
      enable = false;  # Disabled for initial install
      passwordFile = "/persist/secrets/sambaPassword";
      shares = {
        Backups = {
          path = "${hl.mounts.merged}/Backups";
        };
        Documents = {
          path = "${hl.mounts.merged}/Documents";
        };
        Media = {
          path = "${hl.mounts.merged}/Media";
        };
      };
    };
    services = {
      enable = true;
      # All services disabled for initial install - enable after first boot
      slskd.enable = false;
      backup.enable = false;
      keycloak.enable = false;
      radicale.enable = false;
      immich.enable = false;
      invoiceplane.enable = false;
      homepage.enable = false;
      jellyfin.enable = false;
      paperless.enable = false;
      sabnzbd.enable = false;
      sonarr.enable = false;
      radarr.enable = false;
      bazarr.enable = false;
      prowlarr.enable = false;
      jellyseerr.enable = false;
nextcloud = {
  enable = true;
  url = "cloud.brick-layer.org";
  admin = {
    username = "Felix";
    passwordFile = "/persist/secrets/nextcloudAdminPassword";
  };
  cloudflared = {
    tunnelId = "5f3b09f7-46a9-45be-8d15-5cc150776ba2";
    credentialsFile = "/persist/secrets/nextcloudCloudflared";
  };
};

      vaultwarden.enable = false;
      microbin.enable = false;
      miniflux.enable = false;
      navidrome.enable = false;
      audiobookshelf.enable = false;
      deluge.enable = false;
    };
  };
}
