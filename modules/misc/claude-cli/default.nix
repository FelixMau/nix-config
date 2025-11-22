{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.claude-cli;

  # Wrapper script that uses npx to run claude-code
  claude-cli = pkgs.writeShellScriptBin "claude" ''
    export PATH="${pkgs.nodejs}/bin:$PATH"
    exec ${pkgs.nodejs}/bin/npx -y @anthropic-ai/claude-code@latest "$@"
  '';
in
{
  options.modules.claude-cli = {
    enable = lib.mkEnableOption "Claude CLI tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      claude-cli
      pkgs.nodejs
    ];
  };
}
