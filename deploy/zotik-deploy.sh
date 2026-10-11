#!/usr/bin/env bash
# ZOTIK server deploy: builds the Windows and Android apps (optionally Linux/Web) from the latest
# commit of the main branch and publishes them under $WEB_ROOT. Meant to be started by the systemd
# timer (deploy/zotik-deploy.timer); only does work when main has a commit that was not deployed yet.
#
#   zotik-deploy.sh            deploy if main changed
#   zotik-deploy.sh --force    build and publish the current main again
#
# Settings come from /etc/zotik-deploy.env (see deploy/zotik-deploy.env.example).
set -euo pipefail

ENV_FILE=${ZOTIK_DEPLOY_ENV:-/etc/zotik-deploy.env}
if [ -f "$ENV_FILE" ]; then
	# shellcheck disable=SC1090
	. "$ENV_FILE"
fi
REPO_URL=${REPO_URL:-https://github.com/ricorewioriginal-collab/zotik.git}
BRANCH=${BRANCH:-main}
STATE_DIR=${STATE_DIR:-/var/lib/zotik-deploy}
WEB_ROOT=${WEB_ROOT:-/var/www/zotik}
GODOT_VERSION=${GODOT_VERSION:-4.7-stable}
GODOT=${GODOT:-$STATE_DIR/godot/godot}
TARGETS=${TARGETS:-"windows android"}   # any of: windows android linux web
RUN_TESTS=${RUN_TESTS:-1}                # 1 = run the regression tests first, deploy only if they pass
KEEP=${KEEP:-3}                          # how many releases stay on the server
FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

export HOME=${HOME:-$STATE_DIR}
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH=${ANDROID_KEYSTORE:-$STATE_DIR/zotik.keystore}
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=${ANDROID_KEY_ALIAS:-zotik}
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=${ANDROID_KEY_PASSWORD:-zotik-deploy}

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }
has_target() { case " $TARGETS " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

mkdir -p "$STATE_DIR" "$WEB_ROOT/releases"
exec 9>"$STATE_DIR/lock"
flock -n 9 || { log "another deploy is running"; exit 0; }

SRC=$STATE_DIR/src
if [ ! -d "$SRC/.git" ]; then
	git clone --quiet --branch "$BRANCH" "$REPO_URL" "$SRC"
fi
cd "$SRC"
git fetch --quiet origin "$BRANCH"
SHA=$(git rev-parse "origin/$BRANCH")
SHORT=${SHA:0:7}
if [ "$FORCE" = 0 ]; then
	[ "$(cat "$STATE_DIR/last_deployed" 2>/dev/null || true)" = "$SHA" ] && exit 0
	[ "$(cat "$STATE_DIR/last_failed" 2>/dev/null || true)" = "$SHA" ] && exit 0  # do not retry a broken commit
fi
fail() {
	log "FAILED: $*"
	echo "$SHA" > "$STATE_DIR/last_failed"
	exit 1
}

log "deploying $SHORT"
git reset --quiet --hard "origin/$BRANCH"
git clean --quiet -fd   # keeps ignored files, so the .godot import cache survives (faster builds)

# --- version: the Android version code must grow with every build, otherwise phones refuse the update
COUNT=$(git rev-list --count HEAD)
BASE=$(grep -m1 '^config/version=' game/zotik/project.godot | cut -d'"' -f2 | cut -d. -f1-2)
VERSION="$BASE.$COUNT"
PRESETS=game/zotik/export_presets.cfg
sed -i "s|^version/code=.*|version/code=$COUNT|; s|^version/name=.*|version/name=\"$VERSION\"|" "$PRESETS"

# --- optional cloud-save OAuth client (same as the GitHub build)
if [ -n "${GOOGLE_OAUTH_CLIENT_ID:-}" ] && [ -n "${GOOGLE_OAUTH_CLIENT_SECRET:-}" ]; then
	sed -i "s|^const OAUTH_CLIENT_ID := \"\"|const OAUTH_CLIENT_ID := \"$GOOGLE_OAUTH_CLIENT_ID\"|; s|^const OAUTH_CLIENT_SECRET := \"\"|const OAUTH_CLIENT_SECRET := \"$GOOGLE_OAUTH_CLIENT_SECRET\"|" game/zotik/core/cloud_sync.gd
fi

if [ "$RUN_TESTS" = 1 ]; then
	log "running regression tests"
	GODOT="$GODOT" tools/run_regression.sh > "$STATE_DIR/last_tests.log" 2>&1 || fail "tests failed, see $STATE_DIR/last_tests.log"
fi

log "importing project"
"$GODOT" --headless --path game/zotik --import > "$STATE_DIR/last_import.log" 2>&1 || true

OUT=$(mktemp -d "$STATE_DIR/build.XXXXXX")
trap 'rm -rf "$OUT"' EXIT
mkdir -p "$OUT/windows" "$OUT/linux" "$OUT/web" "$OUT/android" "$OUT/files"
export_one() { # preset, release|debug, output path
	log "exporting $1"
	"$GODOT" --headless --path game/zotik "--export-$2" "$1" "$3" > "$STATE_DIR/last_export.log" 2>&1 || fail "export $1 failed, see $STATE_DIR/last_export.log"
	[ -s "$3" ] || fail "export $1 produced no file"
}

FILES=()
if has_target windows; then
	export_one "Windows Desktop" release "$OUT/windows/ZOTIK.exe"
	(cd "$OUT/windows" && zip -qr "$OUT/files/ZOTIK-windows-x86_64.zip" .)
	FILES+=(ZOTIK-windows-x86_64.zip)
fi
if has_target android; then
	[ -f "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" ] || fail "Android keystore missing: $GODOT_ANDROID_KEYSTORE_DEBUG_PATH (run deploy/install.sh)"
	export_one "Android" debug "$OUT/android/ZOTIK.apk"
	unzip -l "$OUT/android/ZOTIK.apk" | grep -q "lib/arm64-v8a/libgodot_android.so" || fail "APK has no arm64 library"
	cp "$OUT/android/ZOTIK.apk" "$OUT/files/ZOTIK-android-arm64.apk"
	FILES+=(ZOTIK-android-arm64.apk)
fi
if has_target linux; then
	export_one "Linux" release "$OUT/linux/ZOTIK.x86_64"
	(cd "$OUT/linux" && zip -qr "$OUT/files/ZOTIK-linux-x86_64.zip" .)
	FILES+=(ZOTIK-linux-x86_64.zip)
fi
WEB_DIR=""
if has_target web; then
	export_one "Web" release "$OUT/web/index.html"
	WEB_DIR=$OUT/web
fi

# --- publish: a new directory per release, then switch the "latest" link in one step
REL="$WEB_ROOT/releases/$VERSION-$SHORT"
rm -rf "$REL"
mkdir -p "$REL"
cp "$OUT"/files/* "$REL"/ 2>/dev/null || true
[ -n "$WEB_DIR" ] && cp -r "$WEB_DIR" "$REL/web"
{
	printf '{"version":"%s","code":%s,"commit":"%s","built":"%s","files":[' "$VERSION" "$COUNT" "$SHA" "$(date -u +%FT%TZ)"
	sep=""
	for f in "${FILES[@]}"; do printf '%s"%s"' "$sep" "$f"; sep=","; done
	printf ']}\n'
} > "$REL/latest.json"
{
	printf '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>ZOTIK Downloads</title>'
	printf '<body style="font-family:sans-serif;max-width:32em;margin:2em auto;padding:0 1em"><h1>ZOTIK – Die Splitter der Welten</h1><p>Version %s (%s)</p><ul>' "$VERSION" "$SHORT"
	for f in "${FILES[@]}"; do printf '<li><a href="%s">%s</a></li>' "$f" "$f"; done
	printf '</ul><p>Android: APK laden, Installation aus dieser Quelle erlauben, installieren. Windows: ZIP entpacken, ZOTIK.exe starten.</p></body>\n'
} > "$REL/index.html"
ln -sfn "$REL" "$WEB_ROOT/latest.new"
mv -T "$WEB_ROOT/latest.new" "$WEB_ROOT/latest"
[ -e "$WEB_ROOT/index.html" ] || ln -s latest/index.html "$WEB_ROOT/index.html"

# --- prune old releases (never the one that is live)
ls -1dt "$WEB_ROOT"/releases/*/ 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
	[ "$(readlink -f "$WEB_ROOT/latest")" = "$(readlink -f "$old")" ] || rm -rf "$old"
done

echo "$SHA" > "$STATE_DIR/last_deployed"
rm -f "$STATE_DIR/last_failed"
log "deployed $VERSION ($SHORT): ${FILES[*]}"
