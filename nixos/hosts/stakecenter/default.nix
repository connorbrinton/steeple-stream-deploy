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

  # The pinned nixpkgs has cloudflared 2026.1.1. Use Cloudflare's verified
  # upstream Linux amd64 release containing the eMudhra trust-store fix
  # (first shipped in 2026.10.2), without updating unrelated NixOS packages.
  nixpkgs.overlays = [
    (_final: prev: {
      cloudflared = prev.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "cloudflared";
        version = "2026.10.7";
        src = prev.fetchurl {
          url = "https://github.com/cloudflare/cloudflared/releases/download/${finalAttrs.version}/cloudflared-linux-amd64";
          # SHA256 from Cloudflare's official GitHub release asset and notes.
          hash = "sha256-H5n7UYuD3sK6jYcKfMmR2Cp35hlilaPSdUuhern5GHI=";
        };
        dontUnpack = true;
        dontPatchELF = true;
        dontStrip = true;
        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/cloudflared"
          runHook postInstall
        '';
        meta = prev.cloudflared.meta;
      });
    })
  ];

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

    secrets.google_client_secret = { };
    secrets.steeple_session_secret = { };

    templates."steeple-stream.env" = {
      owner = "steeple-stream";
      group = "steeple-stream";
      mode = "0400";
      restartUnits = [ "steeple-stream.service" ];
      content = ''
        STEEPLE_GOOGLE_CLIENT_SECRET=${config.sops.placeholder.google_client_secret}
        STEEPLE_SESSION_SECRET=${config.sops.placeholder.steeple_session_secret}
      '';
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

  # WebRTC media uses direct UDP to the Beelink from devices on the chapel LAN.
  # WHEP signaling still passes through the existing Cloudflare HTTPS tunnel.
  networking.firewall.allowedUDPPorts = [ 8189 ];

  services.steeple-stream = {
    enable = true;
    host = "127.0.0.1";
    publicBaseUrl = "https://broadcasts.brintonium.com";
    publicWebRtc = true;
    trustedProxy = true;
    environmentFile = config.sops.templates."steeple-stream.env".path;
  };

  systemd.services.steeple-stream.environment = {
    NDI_CONFIG_DIR = "/etc/steeple-stream/ndi";
    STEEPLE_PROFILE = "camera-control";
    STEEPLE_AUTH_MODE = "google";
    STEEPLE_GOOGLE_CLIENT_ID = "919880998796-pr2cumdobajbm3c8ekg3ilo648hsftkf.apps.googleusercontent.com";
    STEEPLE_ADMIN_EMAILS = "connor@brintonium.com";
    STEEPLE_CHANNEL_ID = "stakecenter";
  };

  # The camera's default UDP transport does not deliver media on this network.
  # Disabling the optional transports selects NDI's base single-TCP connection.
  environment.etc."steeple-stream/ndi/ndi-config.v1.json".text = builtins.toJSON {
    ndi = {
      rudp.recv.enable = false;
      tcp.recv.enable = false;
      unicast.recv.enable = false;
      multicast.recv.enable = false;
    };
  };

  system.stateVersion = "26.05";
}
