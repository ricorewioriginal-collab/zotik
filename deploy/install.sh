#!/usr/bin/env bash
# One-time setup of the ZOTIK deploy on a fresh Debian/Ubuntu VPS. Run as root:
#   sudo bash install.sh
# Installs Godot + export templates, the Android SDK, a signing key, the deploy script, a systemd timer
# (checks main every 5 minutes) and an nginx site that serves the downloads.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root (sudo bash install.sh)"; exit 1; }

GODOT_VERSION=${GODOT_VERSION:-4.7-stable}
TEMPLATE_DIR_NAME=${TEMPLATE_DIR_NAME:-4.7.stable}
ANDROID_CMDLINE_TOOLS=${ANDROID_CMDLINE_TOOLS:-commandlinetools-linux-11076708_latest.zip}
ANDROID_PACKAGES=${ANDROID_PACKAGES:-"platform-tools build-tools;34.0.0 build-tools;35.0.1 platforms;android-34 platforms;android-35"}
STATE_DIR=/var/lib/zotik-deploy
WEB_ROOT=/var/www/zotik
HERE=$(cd "$(dirname "$0")" && pwd)

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git unzip zip curl ca-certificates openjdk-17-jdk-headless nginx util-linux

id zotik-deploy >/dev/null 2>&1 || useradd --system --home-dir "$STATE_DIR" --shell /usr/sbin/nologin zotik-deploy
mkdir -p "$STATE_DIR" "$WEB_ROOT"
chown -R zotik-deploy: "$STATE_DIR" "$WEB_ROOT"
JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")

as_deploy() { sudo -u zotik-deploy -H env HOME="$STATE_DIR" JAVA_HOME="$JAVA_HOME" "$@"; }

# --- Godot and export templates
if [ ! -x "$STATE_DIR/godot/godot" ]; then
	base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}"
	tmp=$(mktemp -d)
	curl -fsSL -o "$tmp/godot.zip" "$base/Godot_v${GODOT_VERSION}_linux.x86_64.zip"
	curl -fsSL -o "$tmp/tpl.tpz" "$base/Godot_v${GODOT_VERSION}_export_templates.tpz"
	mkdir -p "$STATE_DIR/godot" "$STATE_DIR/.local/share/godot/export_templates/$TEMPLATE_DIR_NAME"
	unzip -q "$tmp/godot.zip" -d "$STATE_DIR/godot"
	mv "$STATE_DIR/godot/Godot_v${GODOT_VERSION}_linux.x86_64" "$STATE_DIR/godot/godot"
	unzip -q "$tmp/tpl.tpz" -d "$tmp/tpl"
	for f in windows_release_x86_64.exe linux_release.x86_64 web_nothreads_release.zip android_debug.apk android_release.apk version.txt; do
		mv "$tmp/tpl/templates/$f" "$STATE_DIR/.local/share/godot/export_templates/$TEMPLATE_DIR_NAME/"
	done
	rm -rf "$tmp"
fi

# --- Android SDK
SDK=$STATE_DIR/android-sdk
if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
	tmp=$(mktemp -d)
	curl -fsSL -o "$tmp/cmd.zip" "https://dl.google.com/android/repository/$ANDROID_CMDLINE_TOOLS"
	mkdir -p "$SDK/cmdline-tools"
	unzip -q "$tmp/cmd.zip" -d "$tmp/x"
	mv "$tmp/x/cmdline-tools" "$SDK/cmdline-tools/latest"
	rm -rf "$tmp"
fi
chown -R zotik-deploy: "$STATE_DIR"
yes | as_deploy "$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" --licenses >/dev/null || true
# shellcheck disable=SC2086
as_deploy "$SDK/cmdline-tools/latest/bin/sdkmanager" --sdk_root="$SDK" $ANDROID_PACKAGES

mkdir -p "$STATE_DIR/.config/godot"
printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/android_sdk_path = "%s"\nexport/android/java_sdk_path = "%s"\n' "$SDK" "$JAVA_HOME" > "$STATE_DIR/.config/godot/editor_settings-4.7.tres"

# --- signing key: created ONCE and kept. Every APK must be signed with the same key, otherwise Android
# refuses to install it over the old version. Back this file up!
if [ ! -f "$STATE_DIR/zotik.keystore" ]; then
	keytool -genkeypair -keystore "$STATE_DIR/zotik.keystore" -storepass zotik-deploy -alias zotik -keypass zotik-deploy \
		-keyalg RSA -keysize 2048 -validity 10000 -dname "CN=ZOTIK,O=ZOTIK,C=DE"
fi

# --- script, settings, timer, web server
install -m 755 "$HERE/zotik-deploy.sh" /usr/local/bin/zotik-deploy
[ -f /etc/zotik-deploy.env ] || install -m 640 -o root -g zotik-deploy "$HERE/zotik-deploy.env.example" /etc/zotik-deploy.env
install -m 644 "$HERE/zotik-deploy.service" "$HERE/zotik-deploy.timer" /etc/systemd/system/
install -m 644 "$HERE/nginx-zotik.conf" /etc/nginx/sites-available/zotik
ln -sf /etc/nginx/sites-available/zotik /etc/nginx/sites-enabled/zotik
chown -R zotik-deploy: "$STATE_DIR" "$WEB_ROOT"
nginx -t && systemctl reload nginx
systemctl daemon-reload
systemctl enable --now zotik-deploy.timer
echo
echo "Fertig. Erster Build sofort:  sudo systemctl start zotik-deploy.service   (Log: journalctl -u zotik-deploy -f)"
echo "Downloads:  http://<server>/   (APK: /latest/ZOTIK-android-arm64.apk)"
echo "WICHTIG: $STATE_DIR/zotik.keystore sichern. Die bisherigen APKs waren mit einem anderen Schlüssel signiert:"
echo "         die alte Android-App einmal deinstallieren, danach installieren sich alle Updates direkt darüber."
