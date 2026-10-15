# LineageOS 14.1 cloud build for Sony Xperia Z (yuga)

Builds an installable LineageOS 14.1 (cm-14.1, Android 7.1.2) ROM for the
Sony Xperia Z — codename **yuga** (Fusion3 / APQ8064) — entirely on GitHub
Actions, so nothing heavy is downloaded to your own machine.

## What it does

1. Frees ~30 GB on the Ubuntu 22.04 runner.
2. Installs the Android 7.1 build toolchain (`python2.7`, `openjdk-8`, `git-lfs`).
3. `repo init` on the LineageOS `cm-14.1` branch (shallow, `--depth=1`).
4. Applies `local_manifests/yuga.xml` (device tree, kernel, thermanager,
   stlport and TheMuppets vendor blobs — every repo checked to exist on cm-14.1).
5. `brunch yuga`.
6. Uploads the resulting zip + recovery/boot images as workflow artifacts.

## How to run

1. Push this repo to GitHub (or fork it).
2. Go to the **Actions** tab → **Build LineageOS 14.1 for yuga** → **Run workflow**.
3. Wait (~2–4 h). Download the `lineage-14.1-yuga` artifact when done.
4. Flash in recovery (TWRP): `adb sideload lineage-14.1-*-UNOFFICIAL-yuga.zip`.

## Verified dependency chain (cm-14.1)

| path | repository |
|------|------------|
| device/sony/yuga | LineageOS/android_device_sony_yuga |
| device/sony/fusion3-common | LineageOS/android_device_sony_fusion3-common |
| device/sony/common | LineageOS/android_device_sony_common |
| device/qcom/common | LineageOS/android_device_qcom_common |
| kernel/sony/apq8064 | LineageOS/android_kernel_sony_apq8064 |
| hardware/sony/thermanager | LineageOS/android_hardware_sony_thermanager |
| external/stlport | LineageOS/android_external_stlport |
| vendor/sony | TheMuppets/proprietary_vendor_sony |
