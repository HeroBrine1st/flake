# Firejail profile for android-studio
# This file is overwritten after every install/update
# Persistent local customizations
include android-studio.local
# Persistent global definitions
include globals.local

noblacklist ${HOME}/.config/Google
noblacklist ${HOME}/.cache/Google
noblacklist ${HOME}/.gradle
noblacklist ${HOME}/.cache/Gradle
noblacklist ${HOME}/.AndroidStudio*
noblacklist ${HOME}/.android
noblacklist ${HOME}/.jack-server
noblacklist ${HOME}/.jack-settings
noblacklist ${HOME}/.local/share/JetBrains
noblacklist ${HOME}/.local/share/Google
noblacklist ${HOME}/.tooling
noblacklist ${HOME}/.cache/Android/Sdk
noblacklist ${HOME}/.gitconfig

whitelist ${HOME}/.config/Google
whitelist ${HOME}/.cache/Google
whitelist ${HOME}/.gradle
whitelist ${HOME}/.cache/Gradle
whitelist ${HOME}/.AndroidStudio*
whitelist ${HOME}/.android
whitelist ${HOME}/.jack-server
whitelist ${HOME}/.jack-settings
whitelist ${HOME}/.local/share/JetBrains
whitelist ${HOME}/.local/share/Google
whitelist ${HOME}/.tooling
whitelist ${HOME}/.cache/Android/Sdk
whitelist ${HOME}/Git
whitelist ${HOME}/.jdks
whitelist ${HOME}/.gitconfig
whitelist ${HOME}/.ssh/config
whitelist ${HOME}/.ssh/known_hosts
# standartised path on all machines
whitelist ${HOME}/.ssh/keys/github

read-only ${HOME}/.ssh/config
read-only ${HOME}/.ssh/known_hosts
read-only ${HOME}/.ssh/keys/github



# Allows files commonly used by IDEs
include allow-common-devel.inc

# Allow ssh (blacklisted by disable-common.inc)
include allow-ssh.inc

include disable-common.inc
include disable-programs.inc

include whitelist-var-common.inc

caps.drop all
netfilter
nodvd
nogroups
nonewprivs
noroot
notv
novideo
protocol unix,inet,inet6
# bwrap
seccomp !mount,!pivot_root,!umount2

#private-cache
# private-tmp

# noexec /tmp breaks 'Android Profiler'
#noexec /tmp
#restrict-namespaces

join-or-start android-studio

deterministic-shutdown
