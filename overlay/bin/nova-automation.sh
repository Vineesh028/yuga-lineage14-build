#!/system/bin/sh
# Nova: context-aware automation daemon (root, sysfs-only actions)
logw() { /system/bin/log -t nova "$*" 2>/dev/null; }
logw "nova-automation: start (pid $$)"
last_therm=""
while true; do
  temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
  [ -n "$temp" ] && temp=$((temp/1000))

  # Thermal guard: throttle max CPU freq above 55C, restore below 45C
  if [ -n "$temp" ] && [ "$temp" -ge 55 ]; then
    if [ "$last_therm" != "on" ]; then
      for c in /sys/devices/system/cpu/cpu[0-9]*; do
        mx="$c/cpufreq/cpuinfo_max_freq"; cur="$c/cpufreq/scaling_max_freq"
        if [ -r "$mx" ] && [ -w "$cur" ]; then
          v=$(cat "$mx"); echo $((v * 60 / 100)) > "$cur" 2>/dev/null
        fi
      done
      logw "automation: thermal guard ON (${temp}C), capped to 60%"
      last_therm="on"
    fi
  elif [ -n "$temp" ] && [ "$temp" -le 45 ] && [ "$last_therm" = "on" ]; then
    for c in /sys/devices/system/cpu/cpu[0-9]*; do
      mx="$c/cpufreq/cpuinfo_max_freq"; cur="$c/cpufreq/scaling_max_freq"
      if [ -r "$mx" ] && [ -w "$cur" ]; then cat "$mx" > "$cur" 2>/dev/null; fi
    done
    logw "automation: thermal guard OFF (${temp}C), freq restored"
    last_therm="off"
  fi
  sleep 60
done
