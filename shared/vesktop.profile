ignore whitelist ${DOWNLOADS}
ignore disable-mnt
ignore dbus-user none
ignore dbus-system none

whitelist /mnt/tmp
blacklist /dev/snd

whitelist ${HOME}/.config/vesktop

include electron.profile

join-or-start vesktop