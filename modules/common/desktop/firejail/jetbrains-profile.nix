{ writeTextFile, lib, ideName, ... }: let
  ownDirs = paths:
    (lib.strings.concatMapStringsSep "\n" (path: "noblacklist ${path}") paths)
    + "\n\n" +
    (lib.strings.concatMapStringsSep "\n" (path: "mkdir ${path}") paths)
    + "\n\n" +
    (lib.strings.concatMapStringsSep "\n" (path: "whitelist ${path}") paths);
  ownFiles = paths:
    (lib.strings.concatMapStringsSep "\n" (path: "noblacklist ${path}") paths)
    + "\n\n" +
    (lib.strings.concatMapStringsSep "\n" (path: "mkfile ${path}") paths)
    + "\n\n" +
    (lib.strings.concatMapStringsSep "\n" (path: "whitelist ${path}") paths);
  HOME = "\${HOME}";
in writeTextFile {
  name = "${ideName}.profile";
  # TODO sometimes it does not delete lock file .config/JetBrains/*/.lock
  # and on next launch it complains that IDE is still running with caused by being "unable to bind to address"
  # restarting outside firejail removes that file, so it is fixable
  text = ''
    # Firejail profile for ${ideName}
    # This file is overwritten after every install/update
    # Persistent local customizations
    include ${ideName}.local
    # Persistent global definitions
    include globals.local

    ${ownDirs ([
      "${HOME}/.cache/Gradle"
      "${HOME}/.android"
      "${HOME}/.cache/Android/Sdk"
      "${HOME}/Git"
      "${HOME}/.jdks"
      "${HOME}/.skiko"
      "${HOME}/.continue"
    ] ++ (if ideName == "android-studio" then [
      "${HOME}/.config/Google"
      "${HOME}/.cache/Google"
      "${HOME}/.local/share/Google"
    ] else [
      "${HOME}/.local/share/JetBrains"
      "${HOME}/.config/JetBrains"
      "${HOME}/.cache/JetBrains"
      "${HOME}/.java" # that's where settings are stored at least for intellij idea!
    ]) ++ (lib.optionals (ideName == "android-studio" || ideName == "idea-community") [
      "${HOME}/.pub-cache"
    ]))}
    ${ownFiles [
      "${HOME}/.gitconfig"
      "${HOME}/.zsh_history"
    ]}

    whitelist ${HOME}/.ssh/config
    whitelist ${HOME}/.ssh/known_hosts
    # standartised path on all machines
    whitelist ${HOME}/.ssh/keys/github
    # standartised path on all machines
    whitelist ${HOME}/.ssh/keys/forgejo

    read-only ${HOME}/.ssh/config
    read-only ${HOME}/.ssh/known_hosts
    read-only ${HOME}/.ssh/keys/github
    read-only ${HOME}/.ssh/keys/forgejo

    # Allows files commonly used by IDEs
    include allow-common-devel.inc

    # Allow ssh (blacklisted by disable-common.inc)
    include allow-ssh.inc

    include disable-common.inc
    
    ignore blacklist ${HOME}/.cache/JetBrains/CLion*
    ignore blacklist ${HOME}/.cache/JetBrains/PyCharm*
    ignore blacklist ${HOME}/.config/JetBrains/CLion*
    ignore blacklist ${HOME}/.config/JetBrains/PyCharm*
    ignore blacklist ${HOME}/.local/share/JetBrains
    include disable-programs.inc

    include whitelist-common.inc
    include whitelist-var-common.inc

    caps.drop all
    netfilter
    nodvd
    nogroups
    nonewprivs
    noroot
    notv
    novideo
    protocol unix,inet,inet6,netlink
    # bwrap: !mount,!pivot_root,!umount2
    # chromium (extensions): !chroot
    seccomp !mount,!pivot_root,!umount2,!chroot

    #private-cache
    # private-tmp

    # noexec /tmp breaks 'Android Profiler'
    #noexec /tmp
    #restrict-namespaces

    dbus-user filter
    dbus-user.talk org.freedesktop.secrets.*

    # IDE somehow breaks EGL libraries (running in the same profile without IDE works)
    # I am finamp contributor
    #${lib.optionalString (ideName == "android-studio" || ideName == "idea-community") "dbus-user.own com.unicornsonlsd.finamp"}
    #${lib.optionalString (ideName == "android-studio" || ideName == "idea-community") "dbus-user.own org.mpris.MediaPlayer2.*"}

    name ${ideName}

    tab
  '';
}
