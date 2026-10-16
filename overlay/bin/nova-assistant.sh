#!/system/bin/sh
# Nova Stage C: offline assistant (rules-based, on-device only, no network).
# Usable from a terminal/on-device shell:  nova-assistant.sh "battery"
say() { echo "Nova: $*"; /system/bin/log -t nova "assistant: $*" 2>/dev/null; }
lc=$(echo "$*" | tr 'A-Z' 'a-z')

case "$lc" in
  *battery*)   say "battery $(cat /sys/class/power_supply/battery/capacity 2>/dev/null)%, $(cat /sys/class/power_supply/battery/status 2>/dev/null)";;
  *diagnostic*|*hardware*) /system/bin/nova-diagnostics.sh;;
  *health*)    say "run 'logcat -s nova' to see health output";;
  *temp*)      say "thermal $(( $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null) / 1000 ))C";;
  *storage*|*space*) df -h /data /system 2>/dev/null;;
  *memory*|*ram*) awk '/MemTotal|MemFree|MemAvailable/{printf "%s %d MB\n",$1,$2/1024}' /proc/meminfo;;
  *time*)      say "$(date '+%A %H:%M, %d %B %Y')";;
  *wifi*)      dumpsys wifi 2>/dev/null | grep -m1 -i "Wi-Fi is";;
  *reboot*recovery*) say "rebooting to recovery"; reboot recovery;;
  *reboot*)    say "rebooting"; reboot;;
  *help*|"")   say "commands: battery, diagnostics, health, temperature, storage, memory, time, wifi, reboot";;
  *)           say "I don't understand '$*'. Say 'help'.";;
esac
