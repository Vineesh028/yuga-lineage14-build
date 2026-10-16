#!/system/bin/sh
# Nova Stage D: hardware validation (root or adb shell)
logw() { /system/bin/log -t nova "$*" 2>/dev/null; }
p() { printf "%-13s %s\n" "$1" "$2"; logw "diag $1=$2"; }
rc=0

p cpu     "$(ls -d /sys/devices/system/cpu/cpu[0-9]* 2>/dev/null | wc -l) cores"
[ -n "$(awk '/MemTotal/{print $2}' /proc/meminfo)" ] && p memory "PASS" || { p memory "FAIL"; rc=1; }
[ -b /dev/block/mmcblk0 ] && p storage "PASS" || { p storage "FAIL"; rc=1; }
[ -e /sys/class/graphics/fb0 ] && p display "PASS" || { p display "FAIL"; rc=1; }
[ "$(ls /dev/input/event* 2>/dev/null | wc -l)" -ge 1 ] && p input "PASS" || { p input "FAIL"; rc=1; }
[ -d /sys/class/sensors ] && p sensors "PASS ($(ls /sys/class/sensors | wc -l))" || p sensors "WARN"
[ "$(ls /dev/video* 2>/dev/null | wc -l)" -ge 1 ] && p camera "PASS" || p camera "WARN"
dumpsys wifi 2>/dev/null | grep -qi "Wi-Fi is" && p wifi "PASS" || p wifi "WARN"
[ -e /sys/class/bluetooth ] && p bluetooth "PASS" || p bluetooth "WARN"
[ -e /dev/snd ] || [ -e /proc/asound ] && p audio "PASS" || p audio "WARN"
[ -r /sys/class/power_supply/battery/capacity ] && p battery "PASS" || { p battery "FAIL"; rc=1; }
[ -r /sys/class/thermal/thermal_zone0/temp ] && p thermal "PASS" || p thermal "WARN"
[ -n "$(getprop gsm.version.baseband)" ] && p radio "PASS" || p radio "WARN"

[ "$rc" = "0" ] && echo "RESULT: ALL-CRITICAL-PASS" || echo "RESULT: CRITICAL-FAILURES"
exit $rc
