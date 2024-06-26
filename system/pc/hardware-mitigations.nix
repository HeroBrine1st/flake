{ config, lib, pkgs, custom-pkgs, ... }: {
  systemd.services = {
    "debounce-keyboard" = {
      wantedBy = ["multi-user.target"];
      script = "${custom-pkgs.debounce-keyboard}/bin/debounce-keyboard /dev/input/by-id/usb-Turing_Gaming_Keyboard_Turing_Gaming_Keyboard-event-kbd 30";
      restartIfChanged = false; # Leads to loss of keyboard
    };
  };
}