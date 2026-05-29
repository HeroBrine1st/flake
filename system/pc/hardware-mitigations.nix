{ config, lib, pkgs, flake, ... }: {
  systemd.services = {
    "debounce-keyboard" = {
      wantedBy = ["multi-user.target"];
      script = "${flake.pkgs.debounce-keyboard}/bin/debounce-keyboard /dev/input/by-id/usb-Turing_Gaming_Keyboard_Turing_Gaming_Keyboard-event-kbd 30";
      restartIfChanged = false; # Leads to loss of keyboard
    };
  };
}