package org.nova.dashboard;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.hardware.Camera;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.location.LocationManager;
import android.media.AudioManager;
import android.net.wifi.WifiManager;
import android.os.BatteryManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.StatFs;
import android.provider.Settings;
import android.telephony.TelephonyManager;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class MainActivity extends Activity {

    private TextView out;
    private EditText input;
    private WifiManager wifi;
    private AudioManager audio;

    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        wifi = (WifiManager) getSystemService(Context.WIFI_SERVICE);
        audio = (AudioManager) getSystemService(Context.AUDIO_SERVICE);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.parseColor("#0b1020"));
        root.setPadding(28, 28, 28, 28);

        TextView title = new TextView(this);
        title.setText("Nova \u2014 smart home");
        title.setTextColor(Color.parseColor("#7cf7d0"));
        title.setTextSize(22f);
        root.addView(title);

        TextView sub = new TextView(this);
        sub.setText("offline \u00b7 private \u00b7 self-diagnosing");
        sub.setTextColor(Color.parseColor("#6d7fa3"));
        sub.setTextSize(12f);
        root.addView(sub);

        out = new TextView(this);
        out.setTextColor(Color.parseColor("#d7e1ff"));
        out.setTextSize(14f);
        out.setPadding(0, 16, 0, 16);
        out.setText(refreshStatus());
        ScrollView sc = new ScrollView(this);
        sc.addView(out);
        root.addView(sc, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f));

        input = new EditText(this);
        input.setHint("ask Nova\u2026 (battery, diagnostics, wifi off, brightness low)");
        input.setTextColor(Color.WHITE);
        input.setHintTextColor(Color.parseColor("#8899bb"));
        root.addView(input);

        root.addView(btn("Ask Nova", new View.OnClickListener() {
            public void onClick(View v) { ask(input.getText().toString()); }
        }));
        root.addView(btn("Run hardware diagnostics", new View.OnClickListener() {
            public void onClick(View v) { out.setText(diagnostics()); }
        }));
        root.addView(btn("Refresh status", new View.OnClickListener() {
            public void onClick(View v) { out.setText(refreshStatus()); }
        }));

        setContentView(root);
    }

    private Button btn(String label, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(label);
        b.setAllCaps(false);
        b.setOnClickListener(l);
        return b;
    }

    private int batteryPct() {
        IntentFilter f = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
        Intent i = registerReceiver(null, f);
        if (i == null) return -1;
        int lvl = i.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int scale = i.getIntExtra(BatteryManager.EXTRA_SCALE, 100);
        return (int) (lvl * 100f / scale);
    }

    private String batteryStatus() {
        IntentFilter f = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
        Intent i = registerReceiver(null, f);
        if (i == null) return "?";
        int s = i.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
        switch (s) {
            case BatteryManager.BATTERY_STATUS_CHARGING: return "charging";
            case BatteryManager.BATTERY_STATUS_FULL: return "full";
            case BatteryManager.BATTERY_STATUS_DISCHARGING: return "discharging";
            default: return "idle";
        }
    }

    private String refreshStatus() {
        StringBuilder s = new StringBuilder();
        s.append(date()).append("\n\n");
        s.append("Battery   ").append(batteryPct()).append("%  ").append(batteryStatus()).append("\n");
        s.append("Storage   ").append(mb(free(Environment.getDataDirectory()))).append(" MB free /data\n");
        s.append("System    ").append(mb(free(new File("/system")))).append(" MB free\n");
        s.append("WiFi      ").append(wifi != null && wifi.isWifiEnabled() ? "on" : "off").append("\n");
        s.append("Device    ").append(Build.MODEL).append("  (").append(Build.VERSION.RELEASE).append(")\n");
        s.append("Sensors   ").append(sensorCount()).append(" available\n");
        s.append("Health    ").append(healthHint()).append("\n");
        s.append("\nTip: this screen is the launcher. Press Home to use it as your home screen.");
        return s.toString();
    }

    private String diagnostics() {
        StringBuilder s = new StringBuilder();
        s.append("== Nova hardware validation ==\n\n");
        int crit = 0;

        int cores = Runtime.getRuntime().availableProcessors();
        crit += line(s, "CPU", cores >= 2, cores + " cores");

        int sensors = sensorCount();
        line(s, "Sensors", sensors > 0, sensors + " found");

        int cams = camCount();
        line(s, "Camera", cams > 0, cams + " camera(s)");

        boolean wifiOk = wifi != null;
        crit += line(s, "WiFi", wifiOk, wifiOk ? "adapter present" : "missing");

        BluetoothAdapter bt = BluetoothAdapter.getDefaultAdapter();
        line(s, "Bluetooth", bt != null, bt != null ? "adapter present" : "missing");

        LocationManager lm = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        line(s, "GPS", lm != null, lm != null ? "location service present" : "missing");

        boolean audioOk = audio != null;
        crit += line(s, "Audio", audioOk, audioOk ? "service present" : "missing");

        TelephonyManager tm = (TelephonyManager) getSystemService(Context.TELEPHONY_SERVICE);
        line(s, "Radio", tm != null, tm != null ? "telephony present" : "missing");

        long tot = new File("/data").getTotalSpace();
        crit += line(s, "Storage", tot > 0, mb(tot) + " MB /data total");

        line(s, "Display", true, "initialised");

        s.append("\n").append(crit == 0 ? "RESULT: ALL CRITICAL PASS" : "RESULT: " + crit + " CRITICAL FAIL");
        return s.toString();
    }

    private int line(StringBuilder s, String name, boolean ok, String detail) {
        s.append(pad(name)).append(ok ? "PASS" : "FAIL").append("  ").append(detail).append("\n");
        return ok ? 0 : 1;
    }

    private String pad(String n) {
        StringBuilder b = new StringBuilder(n);
        while (b.length() < 11) b.append(' ');
        return b.toString();
    }

    private void ask(String cmd) {
        if (cmd == null) cmd = "";
        String q = cmd.trim().toLowerCase(Locale.US);
        String r;
        if (q.isEmpty()) r = help();
        else if (q.contains("battery")) r = "Battery is " + batteryPct() + "%, " + batteryStatus() + ".";
        else if (q.contains("diagnos") || q.contains("hardware")) { out.setText(diagnostics()); return; }
        else if (q.contains("storage") || q.contains("space")) r = mb(free(Environment.getDataDirectory())) + " MB free on /data.";
        else if (q.contains("memory") || q.contains("ram")) r = "Free RAM " + mb(freeRAM()) + " MB.";
        else if (q.contains("sensor")) r = sensorCount() + " sensors available.";
        else if (q.contains("time") || q.contains("date")) r = date();
        else if (q.contains("wifi on")) { if (wifi != null) wifi.setWifiEnabled(true); r = "WiFi on."; }
        else if (q.contains("wifi off")) { if (wifi != null) wifi.setWifiEnabled(false); r = "WiFi off."; }
        else if (q.contains("brightness high")) { setBrightness(255); r = "Brightness high."; }
        else if (q.contains("brightness low")) { setBrightness(40); r = "Brightness low."; }
        else if (q.contains("brightness auto")) { Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE, 1); r = "Auto brightness on."; }
        else if (q.contains("volume")) r = "Media volume " + (audio == null ? "?" : audio.getStreamVolume(AudioManager.STREAM_MUSIC)) + ".";
        else if (q.contains("sleep") || q.contains("lock")) r = "Say 'wifi off' or 'brightness low' to save power.";
        else if (q.contains("hello") || q.contains("hi")) r = "Hello. I run entirely on this phone.";
        else r = "Sorry, I don't understand \"" + cmd + "\". Say 'help'.";

        out.setText("> " + cmd + "\n\n" + r + "\n\n\u2014 \u2014 \u2014\n" + refreshStatus());
    }

    private String help() {
        return "I can do:\n" +
               "  battery            \u2014 battery level & state\n" +
               "  diagnostics        \u2014 test the hardware\n" +
               "  storage / memory   \u2014 free space, RAM\n" +
               "  sensors            \u2014 sensor count\n" +
               "  time               \u2014 current date & time\n" +
               "  wifi on/off        \u2014 toggle WiFi\n" +
               "  brightness high/low/auto\n" +
               "  volume             \u2014 media volume\n" +
               "Everything is processed on-device; nothing is sent anywhere.";
    }

    private void setBrightness(int v) {
        try {
            Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS, v);
            Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE, 0);
        } catch (Exception ignored) { }
    }

    private int sensorCount() {
        SensorManager sm = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        if (sm == null) return 0;
        List<Sensor> l = sm.getSensorList(Sensor.TYPE_ALL);
        return l == null ? 0 : l.size();
    }

    private int camCount() {
        try { return Camera.getNumberOfCameras(); } catch (Exception e) { return 0; }
    }

    private long freeRAM() {
        android.app.ActivityManager am = (android.app.ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        android.app.ActivityManager.MemoryInfo mi = new android.app.ActivityManager.MemoryInfo();
        if (am != null) am.getMemoryInfo(mi);
        return mi.availMem;
    }

    private long free(File f) {
        try { StatFs s = new StatFs(f.getPath()); return s.getAvailableBlocksLong() * s.getBlockSizeLong(); }
        catch (Throwable t) { return -1; }
    }

    private String mb(long bytes) { return bytes < 0 ? "?" : String.valueOf(bytes / (1024 * 1024)); }

    private String healthHint() {
        if (batteryPct() < 0) return "unknown";
        return batteryPct() > 15 ? "good" : "low battery";
    }

    private String date() {
        return new SimpleDateFormat("EEEE d MMMM yyyy, HH:mm", Locale.US).format(new Date());
    }
}
