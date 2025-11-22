{ config, lib, inputs, ... }:
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Use the host key for decryption
  age.identityPaths = [ "/persist/ssh/ssh_host_ed25519_key" ];

  # Define secrets - they decrypt to /run/agenix/<name>
  age.secrets = {
    cloudflareDnsApiCredentials = {
      file = ../../../secrets/cloudflareDnsApiCredentials.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    nextcloudAdminPassword = {
      file = ../../../secrets/nextcloudAdminPassword.age;
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0400";
    };
    nextcloudCloudflared = {
      file = ../../../secrets/nextcloudCloudflared.age;
      owner = "cloudflared";
      group = "cloudflared";
      mode = "0400";
    };
    sambaPassword = {
      file = ../../../secrets/sambaPassword.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    smtpPassword = {
      file = ../../../secrets/smtpPassword.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    tailscaleAuthKey = {
      file = ../../../secrets/tailscaleAuthKey.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    tgNotifyCredentials = {
      file = ../../../secrets/tgNotifyCredentials.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
    adiosBotToken = {
      file = ../../../secrets/adiosBotToken.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
