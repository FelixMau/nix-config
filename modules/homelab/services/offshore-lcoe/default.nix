{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = "offshore-lcoe";
  cfg = config.homelab.services.${service};
  homelab = config.homelab;

  # Use pip to install packages from requirements.txt in a venv
  # This is more practical than translating 300+ conda packages to Nix
  pythonWithPip = pkgs.python311.withPackages (ps: with ps; [
    pip
    virtualenv
  ]);

  # Build dependencies needed for cartopy, rasterio, etc.
  buildInputs = with pkgs; [
    gcc
    gfortran
    geos
    proj
    gdal
    hdf5
    netcdf
    zlib
    libpng
    freetype
  ];

  # Runtime libraries needed for pyarrow and other compiled packages
  runtimeLibs = with pkgs; [
    expat
    stdenv.cc.cc.lib  # libstdc++.so.6
    zlib
    geos
    proj
    gdal
    hdf5
    netcdf
  ];

  # Script to set up venv and install dependencies
  setupScript = pkgs.writeShellScript "setup-offshore-lcoe-venv" ''
    set -e
    VENV_DIR="/var/lib/offshore-lcoe/venv"

    if [ ! -d "$VENV_DIR" ]; then
      echo "Creating virtual environment..."
      ${pythonWithPip}/bin/python -m venv "$VENV_DIR"

      echo "Installing dependencies with build tools..."
      export PATH="${lib.makeBinPath buildInputs}:$PATH"
      export CFLAGS="-I${pkgs.geos}/include -I${pkgs.proj}/include -I${pkgs.gdal}/include -I${pkgs.hdf5}/include -I${pkgs.netcdf}/include"
      export LDFLAGS="-L${pkgs.geos}/lib -L${pkgs.proj}/lib -L${pkgs.gdal}/lib -L${pkgs.hdf5}/lib -L${pkgs.netcdf}/lib"
      export PROJ_DIR="${pkgs.proj}"
      export GEOS_DIR="${pkgs.geos}"

      "$VENV_DIR/bin/pip" install --upgrade pip

      # Install core packages needed for the app
      "$VENV_DIR/bin/pip" install \
        streamlit==1.22.0 \
        numpy==1.24.3 \
        pandas==1.5.3 \
        scipy==1.10.1 \
        geopandas==0.13.0 \
        xarray==2023.4.2 \
        netCDF4==1.6.3 \
        matplotlib==3.7.1 \
        cartopy==0.21.1 \
        rasterio==1.3.6 \
        rasterstats==0.19.0 \
        atlite==0.2.11 \
        pvlib==0.9.5 \
        h5py==3.8.0 \
        tables==3.8.0 \
        altair==4.2.2 \
        pydeck==0.8.1b0 \
        folium==0.13.0 \
        plotly \
        tqdm \
        requests \
        pyyaml

      echo "Virtual environment setup complete"
    fi
  '';

in
{
  options.homelab.services.${service} = {
    enable = lib.mkEnableOption "Offshore LCOE Streamlit application";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8501;
      description = "Port for Streamlit to listen on";
    };

    cloudflared.credentialsFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to cloudflared credentials file";
    };

    cloudflared.tunnelId = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare tunnel ID";
    };
  };

  config = lib.mkIf cfg.enable {

    # One-shot service to set up venv
    systemd.services.offshore-lcoe-setup = {
      description = "Setup Python venv for Offshore LCOE";
      wantedBy = [ "multi-user.target" ];
      before = [ "offshore-lcoe.service" ];
      serviceConfig = {
        Type = "oneshot";
        User = "offshore-lcoe";
        Group = "offshore-lcoe";
        ExecStart = setupScript;
        RemainAfterExit = true;
      };
    };

    # Main Streamlit service
    systemd.services.offshore-lcoe = {
      description = "Offshore Wind LCOE Calculator - Streamlit App";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "offshore-lcoe-setup.service" ];
      wants = [ "network-online.target" ];
      requires = [ "offshore-lcoe-setup.service" ];

      serviceConfig = {
        Type = "simple";
        User = "offshore-lcoe";
        Group = "offshore-lcoe";
        WorkingDirectory = "/opt/offshore-lcoe/scripts";
        ExecStart = ''
          /var/lib/offshore-lcoe/venv/bin/streamlit run visualization.py \
            --server.port ${toString cfg.port} \
            --server.address 127.0.0.1 \
            --server.headless true \
            --browser.gatherUsageStats false
        '';
        Restart = "on-failure";
        RestartSec = "10s";

        NoNewPrivileges = true;
        PrivateTmp = true;
      };

      environment = {
        HOME = "/var/lib/offshore-lcoe";
        STREAMLIT_SERVER_ENABLE_CORS = "false";
        STREAMLIT_SERVER_ENABLE_XSRF_PROTECTION = "true";
        LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;
      };
    };

    # User for running the service
    users.users.offshore-lcoe = {
      isSystemUser = true;
      group = "offshore-lcoe";
      home = "/var/lib/offshore-lcoe";
      createHome = true;
    };

    users.groups.offshore-lcoe = {};

    # Cloudflared tunnel configuration
    services.cloudflared.tunnels.${cfg.cloudflared.tunnelId}.ingress = {
      "lcoe.${homelab.baseDomain}" = "http://127.0.0.1:${toString cfg.port}";
    };
  };
}
