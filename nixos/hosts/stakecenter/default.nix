{ config, pkgs, steeple-stream, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "steeple-stream-stakecenter";
  networking.firewall.enable = true;

  time.timeZone = "America/New_York";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  environment.systemPackages = [
    pkgs.git
    pkgs.age
    pkgs.sops
    pkgs.cloudflared
  ];

  sops.defaultSopsFile = ../../../secrets/stakecenter.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;

  sops.secrets."cloudflared/tunnelToken" = { };
  sops.secrets."steepleStream/sessionSecret" = { };
  sops.secrets."steepleStream/googleClientId" = { };
  sops.secrets."steepleStream/googleClientSecret" = { };
  sops.secrets."steepleStream/adminEmails" = { };
  sops.secrets."steepleStream/operatorEmails" = { };

  sops.templates."steeple-stream.env" = {
    owner = "steeple-stream";
    group = "steeple-stream";
    mode = "0400";
    content = ''
      STEEPLE_PROFILE=camera-control
      STEEPLE_PUBLIC_BASE_URL=https://broadcasts.example.org
      STEEPLE_GOOGLE_CLIENT_ID=${config.sops.placeholder."steepleStream/googleClientId"}
      STEEPLE_GOOGLE_CLIENT_SECRET=${config.sops.placeholder."steepleStream/googleClientSecret"}
      STEEPLE_ADMIN_EMAILS=${config.sops.placeholder."steepleStream/adminEmails"}
      STEEPLE_OPERATOR_EMAILS=${config.sops.placeholder."steepleStream/operatorEmails"}
      STEEPLE_SESSION_SECRET=${config.sops.placeholder."steepleStream/sessionSecret"}
      STEEPLE_TRUSTED_PROXY=1
    '';
  };

  services.steeple-stream = {
    enable = true;
    package = steeple-stream.packages.${pkgs.system}.steeple-stream;
    host = "127.0.0.1";
    port = 8080;
    publicBaseUrl = "https://broadcasts.example.org";
    publicWebRtc = false;
    environmentFile = config.sops.templates."steeple-stream.env".path;
  };

  systemd.services.cloudflared-steeple-stream = {
    description = "Cloudflare Tunnel for Steeple Stream";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      LoadCredential = "tunnel-token:${config.sops.secrets."cloudflared/tunnelToken".path}";
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/tunnel-token";
      Restart = "on-failure";
      RestartSec = 5;
      DynamicUser = true;
    };
  };

  services.comin = {
    enable = true;
    debug = false;
    hostname = "steeple-stream-stakecenter";
    remotes = [{
      name = "origin";
      url = "https://github.com/connorbrinton/steeple-stream-deploy.git";
      branches.main.name = "main";
      branches.main.operation = "switch";
      poller.period = 60;
    }];
  };

  system.stateVersion = "26.05";
}
