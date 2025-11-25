{ config, lib, inputs, ... }:
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  # Use the host key for decryption
  age.identityPaths = [ "/persist/ssh/ssh_host_ed25519_key" ];

  # Define secrets - they decrypt to /run/agenix/<name>
  age.secrets = {
  # Secrets are stored in private repo: github:FelixMau/nix-private
    cloudflareDnsApiCredentials = {
      file = "${inputs.nix-private}/cloudflareDnsApiCredentials.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    nextcloudAdminPassword = {
      file = "${inputs.nix-private}/nextcloudAdminPassword.age";
      owner = "nextcloud";
      group = "nextcloud";
      mode = "0400";
    };
    nextcloudCloudflared = {
      file = "${inputs.nix-private}/nextcloudCloudflared.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    sambaPassword = {
      file = "${inputs.nix-private}/sambaPassword.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    smtpPassword = {
      file = "${inputs.nix-private}/smtpPassword.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    tailscaleAuthKey = {
      file = "${inputs.nix-private}/tailscaleAuthKey.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    tgNotifyCredentials = {
      file = "${inputs.nix-private}/tgNotifyCredentials.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    adiosBotToken = {
      file = "${inputs.nix-private}/adiosBotToken.age";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    landingPageHtpasswd = {
      file = "${inputs.nix-private}/landingPageHtpasswd.age";
      owner = "caddy";
      group = "caddy";
      mode = "0400";
    };
  };
}
