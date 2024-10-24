# Persistent global definitions
include globals.local

ignore whitelist ${DOWNLOADS}
ignore disable-mnt
ignore dbus-user none
ignore dbus-system none

whitelist /mnt/tmp
blacklist /dev/snd

mkdir ${HOME}/.config/vesktop
whitelist ${HOME}/.config/vesktop

include electron.profile

join-or-start vesktop
