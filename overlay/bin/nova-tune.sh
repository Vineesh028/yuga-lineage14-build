#!/system/bin/sh
# Nova Stage A: performance + battery tuning (runs as root via sysinit/init.d)
logw() { /system/bin/log -t nova "$*" 2>/dev/null; }
logw "nova-tune: start"

# --- CPU governors -> interactive ---
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
  [ -w "$cpu/cpufreq/scaling_governor" ] && echo interactive > "$cpu/cpufreq/scaling_governor" 2>/dev/null
done

# --- interactive governor tuning ---
P=/sys/devices/system/cpu/cpufreq/interactive
[ -w "$P/timer_rate" ]        && echo 20000 > "$P/timer_rate"
[ -w "$P/min_sample_time" ]   && echo 20000 > "$P/min_sample_time"
[ -w "$P/go_hispeed_load" ]   && echo 90 > "$P/go_hispeed_load"
[ -w "$P/above_hispeed_delay" ] && echo 20000 > "$P/above_hispeed_delay"
[ -w "$P/target_loads" ]      && echo "90 600000:80 1200000:85 1500000:95" > "$P/target_loads"
[ -w "$P/io_is_busy" ]        && echo 1 > "$P/io_is_busy"

# --- I/O scheduler + read-ahead on internal storage ---
for q in /sys/block/mmcblk0/queue; do
  if [ -w "$q/scheduler" ]; then
    if grep -q row "$q/scheduler" 2>/dev/null; then echo row > "$q/scheduler"
    elif grep -q cfq "$q/scheduler" 2>/dev/null; then echo cfq > "$q/scheduler"; fi
  fi
  [ -w "$q/read_ahead_kb" ] && echo 2048 > "$q/read_ahead_kb"
  [ -w "$q/nr_requests" ]   && echo 128  > "$q/nr_requests"
done

# --- VM tuning ---
echo 10 > /proc/sys/vm/dirty_ratio 2>/dev/null
echo 5  > /proc/sys/vm/dirty_background_ratio 2>/dev/null
echo 8192 > /proc/sys/vm/min_free_kbytes 2>/dev/null
echo 60 > /proc/sys/vm/swappiness 2>/dev/null

# --- zram (if present) ---
if [ -e /sys/block/zram0/disksize ]; then
  echo 268435456 > /sys/block/zram0/disksize 2>/dev/null
  mkswap /dev/block/zram0 >/dev/null 2>&1
  swapon /dev/block/zram0 >/dev/null 2>&1 && logw "nova-tune: zram 256MB enabled"
fi

logw "nova-tune: done (gov=interactive, io tuned)"
