Goals:

- Parity with GNOME
- Initial compartmentalization (e.g. status bar does not access user data such as SSH keys so it can be isolated into its own namespace)

# Preventing normal operation

## Inside session

Those issues interfere with normal work and require additional keypresses to fix.

### Hyprland

- Does not support multiple maximized windows in floating mode (`fullscreen, 1`). Requires maximizing window each time it is brought to front. This is **the main issue** and until fixed the hyprland is not usable (it then requires multiple monitors and in my case it needs likely 7 of them).
  Possibly fixed by moving all windows to own workspaces, however interaction between windows from different workspaces is questionable.
- Does not support bringing focused window to top automatically (focused window can be fully hidden behind another window - that's something that is not expected in 2025! Aside from this, this is HUGE security hole). Requires remaximizing or "alterzorder". Can be fixed with a script but this is not serious (probably patch to hyprshell is better).

### Hyprshell

- Alt-tab behavior loses "Alt" release if you release it quick enough
- Does not launch applications (likely uwsm problem)

### Status bar

Probably needs to be written from scratch.

### Notifications

Nonexistent

### Screenshotting/screencasting

Nonexistent

### Polkit authentication

Broken, systemd-run doesn't see it

## Outside session

### UWSM

- Creates a circular dependency between wayland-session@.target <-> wayland-wm@.service.
  wayland-wm BindsTo wayland-session while wayland-session requires wayland-wm, meaning both require each other and, as such, prevent unit stopping.
  To end user this leads to inability to log out and even log in (hanging up) if such session is still active. Possibly triggered by masking of xdg autostart service.  
  Should be easily fixable though.