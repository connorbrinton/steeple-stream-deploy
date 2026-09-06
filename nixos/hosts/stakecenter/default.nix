{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.displayManager.gdm = {
    enable = true;
    autoSuspend = false;
  };
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"

        "hmac-sha2-512"
        "hmac-sha2-256"
      ];
    };
  };

  users.users.admin = {
    isNormalUser = true;
    description = "Admin";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  environment.systemPackages = [
    pkgs.age
    pkgs.cloudflared
    pkgs.git
    pkgs.sops
  ];

  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-ac-timeout = lib.gvariant.mkUint32 0;
          sleep-inactive-battery-type = "nothing";
          sleep-inactive-battery-timeout = lib.gvariant.mkUint32 0;
        };
      };
    }
  ];

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  sops = {
    defaultSopsFile = ../../../secrets/steeplestream.yaml;
    age.keyFile = "/root/.config/sops/age/keys.txt";

    secrets.cloudflared_token = {
      restartUnits = [ "cloudflared.service" ];
    };
  };

  systemd.services.cloudflared = {
    description = "Cloudflare Tunnel";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "notify";
      LoadCredential = "tunnel-token:${config.sops.secrets.cloudflared_token.path}";
      ExecStart = ''
        ${pkgs.cloudflared}/bin/cloudflared \
          tunnel \
          --no-autoupdate \
          run \
          --token-file %d/tunnel-token
      '';
      DynamicUser = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  services.comin = {
    enable = true;
    debug = false;
    hostname = "nixos";
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
