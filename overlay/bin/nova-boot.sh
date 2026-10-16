#!/system/bin/sh
# Nova boot orchestrator (started by /system/etc/init.d/90nova, root)
logw() { /system/bin/log -t nova "$*" 2>/dev/null; }
logw "nova-boot: waiting for framework"

i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 90 ]; do
  sleep 2; i=$((i+1))
done

/system/bin/nova-tune.sh
/system/bin/nova-health.sh
/system/bin/nova-diagnostics.sh >/dev/null 2>&1

# start the context-aware automation daemon once
if [ -z "$(ps | grep '[n]ova-automation')" ]; then
  /system/bin/nova-automation.sh &
fi

logw "nova-boot: done"
