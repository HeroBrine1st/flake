# Firejail profile for bottles
# Persistent local customizations
include bottles.local
# Persistent global definitions
include globals.local

include allow-python3.inc

noblacklist ${HOME}/.config/MangoHud
noblacklist ${HOME}/.cache/wine


include disable-common.inc
include disable-devel.inc
include disable-interpreters.inc
include disable-programs.inc
include disable-xdg.inc

mkdir ${HOME}/.local/share/bottles
mkdir ${HOME}/.cache/nvidia
mkdir ${HOME}/.cache/wine

whitelist ${HOME}/.cache/wine
whitelist ${HOME}/.cache/nvidia
whitelist ${HOME}/.local/share/bottles
whitelist ${HOME}/.config/MangoHud
read-only ${HOME}/.config/MangoHud
whitelist /mnt/extra/Bottles
include whitelist-common.inc

include whitelist-run-common.inc
include whitelist-run-common.inc
whitelist ${RUNUSER}/at-spi
include whitelist-runuser-common.inc
include whitelist-usr-share-common.inc
include whitelist-var-common.inc

apparmor
caps.drop all
ipc-namespace
#no3d	# disable 3D acceleration
#nodvd	# disable DVD and CD devices
#nogroups	# disable supplementary user groups
#noinput	# disable input devices
nonewprivs
#noroot
#notv	# disable DVB TV devices
#nou2f	# disable U2F devices
#novideo	# disable video capture devices
protocol unix,inet,inet6,netlink,
#net eth0
netfilter
seccomp !mount,!pivot_root,!umount2
#tracelog	# send blacklist violations to syslog
#private-bin env,wine64-preloader,wine64,uname,wineserver,pgrep,kmod,lspci,grep,bash,python3.11,
#private-cache	# run with an empty ~/.cache directory
private-dev

private-tmp

dbus-user filter
dbus-system none

dbus-user.talk ca.desrt.dconf
#dbus-user.talk org.gtk.Actions
#dbus-user.talk org.freedesktop.DBus.Properties
dbus-user.talk org.a11y.Bus
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.own com.usebottles.*

# Gamemode
dbus-user.talk com.feralinteractive.GameMode

#memory-deny-write-execute

tmpfs ${HOME}/.local/share/applications

join-or-start bottles
