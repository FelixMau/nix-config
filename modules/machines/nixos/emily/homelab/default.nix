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
    baseDomain = "brick-layer.org";
    cloudflare.dnsCredentialsFile = config.age.secrets.cloudflareDnsApiCredentials.path;
    timeZone = "Europe/Berlin";
    mounts = {
      config = "/persist/opt/services";
      slow = "/mnt/data";
      fast = "/mnt/data";
      merged = "/mnt/data";
    };
    samba = {
      enable = false;  # Disabled for initial install
      passwordFile = config.age.secrets.sambaPassword.path;
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
  url="cloud.brick-layer.org";
  admin = {
    username = "Felix";
    passwordFile = config.age.secrets.nextcloudAdminPassword.path;
  };
  cloudflared = {
    tunnelId = "5f3b09f7-46a9-45be-8d15-5cc150776ba2";
    credentialsFile = config.age.secrets.nextcloudCloudflared.path;
  };
};

      vaultwarden = {
        enable = true;
        cloudflared = {
          tunnelId = "5f3b09f7-46a9-45be-8d15-5cc150776ba2";
          credentialsFile = config.age.secrets.nextcloudCloudflared.path;
        };
      };
      microbin.enable = false;
      miniflux.enable = false;
      navidrome.enable = false;
      audiobookshelf.enable = false;
      landing-page = {
        cloudflared = {
          tunnelId = "5f3b09f7-46a9-45be-8d15-5cc150776ba2";
          credentialsFile = config.age.secrets.nextcloudCloudflared.path;
        };
        enable = true;
        passwordHash = "$2a$14$Kd84dW8TkTzkSZ0ORThb5.9JMkaWpb..l0S07lEAz/FOiN09qmhxi";
      };
      offshore-lcoe = {
        enable = true;
        cloudflared = {
          tunnelId = "5f3b09f7-46a9-45be-8d15-5cc150776ba2";
          credentialsFile = config.age.secrets.nextcloudCloudflared.path;
        };
      };
      deluge.enable = false;
    };
  };
}
