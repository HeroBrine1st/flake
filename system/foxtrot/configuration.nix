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
          version = "20251118.0-19-gd25a12513";
          src = pkgs.fetchFromGitHub {
            owner = "google";
            repo = "gvisor";
            rev = "c426a4c6d753ce2bf405de125b0486adfef12877";
            hash = "sha256-DCgU4Jv40w2ItgrQv3mBWJ4r51qQx8BIUEsa0bX3sQs=";
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
      (pkgs.kata-runtime.overrideAttrs(old: {
        # For some reason they did not enable it back after fix
        hardeningDisable = [];
        # I know about -p3 and --directory, no both won't work (in latter case /build/source/tests is read-only)
        src = pkgs.stdenv.mkDerivation rec {
          src = pkgs.fetchFromGitHub {
            owner = "kata-containers";
            repo = "kata-containers";
            rev = "758471cbddeff44297ca5a3db9340bad0c3360ef"; # pull/11749/head
            hash = "sha256-tH395Uz1vdm/9rvFVKcfycMEuSDfWJ9S798n0wb7EBg=";
          };
          name = src.name;

          phases = [ "unpackPhase" "patchPhase" "installPhase" ];
          installPhase = "cp --archive . $out";
        };
      }))
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