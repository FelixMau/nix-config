{ lib, ... }:
{
  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 14d";
      persistent = true;
    };
    optimise = {
      automatic = true;
      dates = [ "daily" ];
    };

    settings = {
      experimental-features = lib.mkDefault [
        "nix-command"
        "flakes"
      ];
      # Limit parallelism to prevent OOM on 8GB RAM
      max-jobs = 2;
      cores = 2;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };
}
