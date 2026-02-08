{ pkgs, lib, config, ... }: {
  boot.tmp.useTmpfs = true;

  security.sudo-rs.wheelNeedsPassword = false;

  # Set your time zone.
  time.timeZone = "Europe/Moscow";

  zramSwap.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";

  users.users.herobrine1st = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2ubhbGB+qP76VLId1wi/WhgDjnwt4zOnlorbFYv0vx herobrine1st@DESKTOP-IJK2GUG"
    ];
  };

  environment.systemPackages = with pkgs; [
    ctop
    rclone
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [ "herobrine1st" ];
      AuthenticationMethods = "publickey,keyboard-interactive";
    };
  };

  # TODO move to run0 and use only googleAuthenticator factor there
  security.pam.services.sshd = {
    # does not work
    #googleAuthenticator.enable = true;
    #unixAuth = lib.mkForce false; # without that it isn't even added
    # This works
    rules = {
      auth = {
        "google_authenticator" = {
          enable = true;
          control = "required";
          modulePath = "${pkgs.google-authenticator}/lib/security/pam_google_authenticator.so";
          order = 11000;
          settings = {
            no_increment_hotp = false;
            forward_pass = false;
            nullok = false;
            echo_verification_code = true;
          };
        };

        # that was the only rule in auth section
        deny.control = let
          actualModulePath = config.security.pam.services.sshd.rules.auth.deny.modulePath;
          expectedModulePath = "${config.security.pam.package}/lib/security/pam_deny.so";
        in assert actualModulePath == expectedModulePath; lib.mkForce "optional";
      };
    };
  };


  services.udisks2.enable = true;

  services.cron.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    package = pkgs.docker_28;
    liveRestore = false;
    storageDriver = "btrfs";
    daemon.settings = {
      dns = ["1.1.1.1"];
      runtimes = let
        gvisor = pkgs.gvisor.overrideAttrs rec {
          version = "20260126.0-16-gf87a10ed3";
          src = pkgs.fetchFromGitHub {
            owner = "google";
            repo = "gvisor";
            rev = "0bd9aedd142c213b4c718156e1e1c6e68c91a17c";
            hash = "sha256-c8p4pvR8j9TiFnuQdn7nIZkVmRQAf6ICzsBxjB9cPt8=";
          };
          vendorHash = "sha256-Ey4M3NK/+AVkr7r0aA+kAfNk1yVfnDn3Izy7u74HFkE=";
        };
      in {
        runsc = {
          path = "${gvisor}/bin/runsc";
          runtimeArgs = [ "--platform=kvm" ];
        };
        runsc-net-raw = {
          path = "${gvisor}/bin/runsc";
          runtimeArgs = [ "--platform=kvm" "--net-raw" ];
        };
      };
    };
    extraPackages = [
      # docker run --runtime io.containerd.kata.v2
#      (pkgs.kata-runtime.overrideAttrs(old: {
#        # For some reason they did not enable it back after fix
#        hardeningDisable = [];
#        # I know about -p3 and --directory, no both won't work (in latter case /build/source/tests is read-only)
#        src = pkgs.fetchFromGitHub {
#          owner = "kata-containers";
#          repo = "kata-containers";
#          rev = "4fe59cf0992375d6aca44dfe05f9192f98de5a50"; # pull/11749/head
#          hash = "sha256-tWHiNiebQgTEAkFx8Kt+ABlyJNnxK5r4/prvEeTW8JU=";
#        };
#      }))
    ];
  };

  environment.etc."htoprc".source = ./htoprc;

  system.stateVersion = "24.11";

   # run0 still does not work on nixos 25.05
   security.sudo-rs = {
     enable = true;
     execWheelOnly = true;
   };
}