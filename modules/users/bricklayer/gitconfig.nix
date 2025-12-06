{
  inputs,
  lib,
  config,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "FelixMau";
    userEmail = "fmau@posteo.de";

    extraConfig = {
      core = {
        sshCommand = "ssh -o 'IdentitiesOnly=yes' -i ~/.ssh/id_ed25519";
      };
    };
    includes = [
      {
        path = "~/.config/git/includes";
        condition = "gitdir:~/Workspace/Projects/";
      }
    ];
  };
}
