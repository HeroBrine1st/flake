include tlauncher.local
include globals.local

ignore noexec ${HOME}

mkdir ${HOME}/.minecraft
mkdir ${HOME}/.tlauncher
noblacklist ${HOME}/.minecraft
noblacklist ${HOME}/.tlauncher
whitelist ${HOME}/.minecraft
whitelist ${HOME}/.tlauncher

# bwrap
noblacklist /proc/sys/kernel/overflowuid
noblacklist /proc/sys/kernel/overflowgid

include disable-common.inc
include disable-devel.inc
include disable-exec.inc
include disable-interpreters.inc
include disable-proc.inc
include disable-programs.inc
include disable-shell.inc
include disable-xdg.inc


caps.drop all
machine-id
nodvd
nogroups
noinput
nonewprivs
noprinters
noroot
novideo

notv
nou2f
protocol unix,inet,inet6
# bwrap
seccomp !mount,!pivot_root,!umount2

disable-mnt
private-dev
private-tmp

dbus-user none
dbus-system none

join-or-start tlauncher