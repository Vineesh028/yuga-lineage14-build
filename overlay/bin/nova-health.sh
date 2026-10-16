#!/system/bin/sh
# Nova Stage D: self-diagnostics + recovery guard (root, via sysinit/init.d)
logw() { /system/bin/log -t nova "$*" 2>/dev/null; }
FAILS=0
chk() { if [ "$2" = "0" ]; then logw "health $1=OK"; else logw "health $1=FAIL"; FAILS=$((FAILS+1)); fi; }

[ -d /data ] && [ -w /data ] ; chk data $?
[ -e /dev/block/bootdevice/by-name/system ] || [ -e /dev/block/platform/msm_sdcc.1/by-name/system ]; chk systempart $?
[ -e /dev/block/bootdevice/by-name/userdata ] || [ -e /dev/block/platform/msm_sdcc.1/by-name/userdata ]; chk datapart $?
[ -e /sys/class/thermal/thermal_zone0/temp ]; chk thermal $?
[ -r /sys/class/power_supply/battery/capacity ]; chk battery $?
[ -d /sys/class/sensors ] || [ -d /sys/devices/virtual/input ]; chk input $?

if [ "$FAILS" = "0" ]; then
  logw "health: all checks passed"
else
  logw "health: $FAILS check(s) failed"
fi
