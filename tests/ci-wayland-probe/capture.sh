#!/bin/sh
# Manual diagnostic only: no project imports, builds, assertions or retries.
set -eu
probe=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
output=$(mktemp -d "$probe/logs.XXXXXX")
mkdir -m 700 "$output/runtime" "$output/config" "$output/data" "$output/cache" "$output/state"
export XDG_RUNTIME_DIR="$output/runtime" XDG_CONFIG_HOME="$output/config"
export XDG_DATA_HOME="$output/data" XDG_CACHE_HOME="$output/cache" XDG_STATE_HOME="$output/state"
export QT_FORCE_STDERR_LOGGING=1 QT_DEBUG_PLUGINS=1 WAYLAND_DEBUG=1
export LIBGL_ALWAYS_SOFTWARE=1 KWIN_COMPOSE=O2 QSG_RHI_BACKEND=opengl
export WAYLAND_DISPLAY=kos-ci-probe DISPLAY=
export KOS_PROBE_DIR="$probe" KOS_PROBE_OUTPUT="$output"
unset WAYLAND_SOCKET QT_QUICK_BACKEND QML_IMPORT_PATH QML2_IMPORT_PATH
cat > "$output/session.sh" <<'EOF'
#!/bin/sh
exec env QT_QPA_PLATFORM=wayland quickshell -p "$KOS_PROBE_DIR" --no-color > "$KOS_PROBE_OUTPUT/client.log" 2>&1
EOF
chmod 700 "$output/session.sh"
{
    kwin_wayland --version
    quickshell --version
    command -v getcap >/dev/null && getcap "$(command -v kwin_wayland)"
    command -v pacman >/dev/null && pacman -Q kwin quickshell qt6-base qt6-wayland
    command -v qtpaths6 >/dev/null && qtpaths6 --qt-version
    true
} > "$output/versions.log" 2>&1
status=0
timeout --kill-after=3s 20s dbus-run-session -- env QT_QPA_PLATFORM=offscreen \
    kwin_wayland --virtual --width 800 --height 600 --no-lockscreen \
    --no-global-shortcuts --no-kactivities --socket "$WAYLAND_DISPLAY" \
    --exit-with-session "$output/session.sh" > "$output/server.log" 2>&1 || status=$?
printf 'exit=%s\nlogs=%s\n' "$status" "$output"
exit "$status"
