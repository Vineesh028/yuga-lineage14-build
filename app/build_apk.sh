#!/usr/bin/env bash
# Build the Nova companion APK with plain SDK tools (no Gradle).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
cd "$here"

SDK="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
BT="$SDK/build-tools/34.0.0"
AJAR="$SDK/platforms/android-35/android.jar"
JAVAC_JDK8="$HOME/Library/Java/JavaVirtualMachines/azul-1.8.0_502/Contents/Home/bin/javac"

[ -x "$JAVAC_JDK8" ] || JAVAC_JDK8="$(command -v javac)"

rm -rf build
mkdir -p build/classes build/dex
OUT="$(cd .. && pwd)/app/Nova.apk"

echo "== javac =="
find src -name '*.java' > build/sources.txt
"$JAVAC_JDK8" -source 8 -target 8 -bootclasspath "$AJAR" \
  -d build/classes @build/sources.txt 2>&1 | grep -v 'bootstrap class path' || true

echo "== d8 =="
find build/classes -name '*.class' > build/classes.txt
"$BT/d8" --min-api 25 --lib "$AJAR" --output build/dex @build/classes.txt

echo "== aapt2 link =="
"$BT/aapt2" link -o build/base.apk \
  -I "$AJAR" \
  --manifest AndroidManifest.xml \
  --min-sdk-version 25 --target-sdk-version 25

echo "== package dex =="
cd build
rm -f apk-stage.apk
cp base.apk apk-stage.apk
zip -qj apk-stage.apk dex/classes.dex

echo "== zipalign =="
"$BT/zipalign" -f 4 apk-stage.apk aligned.apk

echo "== keystore =="
if [ ! -f nova.jks ]; then
  "$(dirname "$JAVAC_JDK8")/keytool" -genkeypair -keystore nova.jks -alias nova \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass android -keypass android -storetype PKCS12 \
    -dname "CN=Nova, O=Nova, C=US" 2>&1 | tail -1 || true
fi

echo "== sign =="
"$BT/apksigner" sign --ks nova.jks --ks-pass pass:android --key-pass pass:android \
  --out "$OUT" aligned.apk

echo "== verify =="
"$BT/apksigner" verify --print-certs "$OUT" | head -3
ls -l "$OUT"
echo "OK -> $OUT"
