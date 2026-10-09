#!/usr/bin/env bash
# GS NullOut | GhostStrats
# Portable 60-second idle shutdown. No installation or network needed.
# Linux desktops: GNOME idle monitor, existing xprintidle, or Python + X11/Xss.
# On other desktops, optional MANUAL heartbeat mode (not system-wide idle).

LIMIT=60
WARN=15
TEST=0
MODE=auto
for arg in "$@"; do
    case "$arg" in
        --test) TEST=1; LIMIT=10; WARN=5 ;;
        --manual) MODE=manual ;;
        *) echo "Usage: bash gsnull.sh [--test] [--manual]"; exit 2 ;;
    esac
done

PURPLE=$'\033[1;35m'
YELLOW=$'\033[1;33m'
RED=$'\033[1;31m'
RESET=$'\033[0m'

# Read idle milliseconds from GNOME's existing desktop service.
gnome_idle() {
    local result dest
    for dest in org.gnome.Mutter.IdleMonitor org.gnome.Shell; do
        result=$(gdbus call --session \
            --dest "$dest" \
            --object-path /org/gnome/Mutter/IdleMonitor/Core \
            --method org.gnome.Mutter.IdleMonitor.GetIdletime \
            2>/dev/null) || continue
        # GNOME returns something like (uint64 12500,).
        # Read the value AFTER the type, not the 64 in "uint64".
        if [[ $result =~ uint(32|64)[[:space:]]+([0-9]+) ]]; then
            printf '%s\n' "${BASH_REMATCH[2]}"
            return 0
        fi
    done
    return 1
}

# Use the already-present X11 libraries via Python, without pip/apt.
# Only available in an X11 session with Python 3, libX11 and libXss.
x11_idle() {
    python3 - <<'PY' 2>/dev/null
import ctypes
import sys
class Info(ctypes.Structure):
    _fields_ = [('window', ctypes.c_ulong), ('state', ctypes.c_int),
                ('kind', ctypes.c_int), ('since', ctypes.c_ulong),
                ('idle', ctypes.c_ulong), ('event_mask', ctypes.c_ulong)]
try:
    x11 = ctypes.CDLL('libX11.so.6')
    xss = ctypes.CDLL('libXss.so.1')
    x11.XOpenDisplay.restype = ctypes.c_void_p
    x11.XOpenDisplay.argtypes = [ctypes.c_char_p]
    dpy = x11.XOpenDisplay(None)
    if not dpy:
        sys.exit(1)
    x11.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
    x11.XDefaultRootWindow.restype = ctypes.c_ulong
    xss.XScreenSaverAllocInfo.restype = ctypes.POINTER(Info)
    xss.XScreenSaverQueryInfo.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.POINTER(Info)]
    xss.XScreenSaverQueryInfo.restype = ctypes.c_int
    info = xss.XScreenSaverAllocInfo()
    if not info or not xss.XScreenSaverQueryInfo(dpy, x11.XDefaultRootWindow(dpy), info):
        sys.exit(1)
    print(info.contents.idle)
    x11.XFree.argtypes = [ctypes.c_void_p]
    x11.XFree(ctypes.cast(info, ctypes.c_void_p))
    x11.XCloseDisplay.argtypes = [ctypes.c_void_p]
    x11.XCloseDisplay(dpy)
except (OSError, AttributeError):
    sys.exit(1)
PY
}

backend=""
if [[ $MODE != manual ]]; then
    if command -v gdbus >/dev/null 2>&1 && gnome_idle >/dev/null; then
        backend=gnome
    elif [[ -n ${DISPLAY:-} && ${XDG_SESSION_TYPE:-x11} != wayland ]] \
        && command -v xprintidle >/dev/null 2>&1 \
        && xprintidle >/dev/null 2>&1; then
        backend=xprintidle
    elif [[ -n ${DISPLAY:-} && ${XDG_SESSION_TYPE:-x11} != wayland ]] \
        && command -v python3 >/dev/null 2>&1 \
        && x11_idle >/dev/null; then
        backend=x11
    fi
fi

if [[ -z $backend ]]; then
    if [[ $MODE != manual ]]; then
        echo 'This desktop has no supported system-wide inactivity monitor.'
        echo 'Nothing has been installed or changed.'
        echo 'Manual fallback only counts keys pressed IN THIS TERMINAL.'
        echo 'Mouse movement or work in other apps will NOT reset it.'
        if [[ ! -t 0 ]]; then exit 1; fi
        read -r -p 'Use manual heartbeat mode anyway? [y/N] ' choice
        [[ $choice == [Yy] ]] || exit 1
    fi
    if [[ ! -t 0 ]]; then echo 'Manual mode requires a terminal.'; exit 1; fi
    backend=manual
fi

read_idle() {
    case $backend in
        gnome) gnome_idle ;;
        xprintidle) xprintidle ;;
        x11) x11_idle ;;
    esac
}

warn_sound() {
    # Some terminals mute the bell. Installed desktop sound tools are optional.
    printf '\a'
    if command -v canberra-gtk-play >/dev/null 2>&1; then
        canberra-gtk-play --id=dialog-warning >/dev/null 2>&1 &
    elif command -v paplay >/dev/null 2>&1 \
        && [[ -r /usr/share/sounds/freedesktop/stereo/dialog-warning.oga ]]; then
        paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga >/dev/null 2>&1 &
    fi
}

on_stop() { printf '\nStopped GS NullOut.\n'; exit 0; }
trap on_stop INT TERM

printf '%sGS NULLOUT | BY GHOSTSTRATS%s\n' "$PURPLE" "$RESET"
printf 'Portable idle shutdown | %s seconds | %s\n' "$LIMIT" "$backend"
printf 'Ctrl+C to stop. %s\n\n' "$([[ $TEST == 1 ]] && echo 'SAFE TEST: no shutdown' || echo 'Save work: shutdown is enabled')"

started=$SECONDS
last_key=$SECONDS
beeped=0
while :; do
    if [[ $backend == manual ]]; then
        # Read a keystroke with a 1-second timeout (Bash built-in).
        if IFS= read -r -s -n 1 -t 1 _pressed; then
            last_key=$SECONDS
        fi
        idle_seconds=$((SECONDS - last_key))
    else
        ms=$(read_idle) || {
            printf '\nIdle monitor stopped responding. Shutdown canceled.\n'
            exit 1
        }
        if [[ ! $ms =~ ^[0-9]+$ ]]; then
            printf '\nInvalid idle reading. Shutdown canceled.\n'
            exit 1
        fi
        idle_seconds=$((ms / 1000))
        # Never treat pre-launch idle time as time spent with the app open.
        running=$((SECONDS - started))
        if (( idle_seconds > running )); then idle_seconds=$running; fi
    fi

    remaining=$((LIMIT - idle_seconds))
    if (( remaining <= 0 )); then
        printf '\r\033[K%sGS NULLOUT | 00:00 | SHUTDOWN%s\n' "$RED" "$RESET"
        if (( TEST )); then
            echo 'TEST COMPLETE: computer was NOT shut down.'
            exit 0
        fi
        echo 'Requesting power off...'
        if command -v systemctl >/dev/null 2>&1; then
            systemctl poweroff || { echo 'Shutdown request failed.'; exit 1; }
        elif command -v poweroff >/dev/null 2>&1; then
            poweroff || { echo 'Shutdown request failed.'; exit 1; }
        else
            echo 'No shutdown command available.'
            exit 1
        fi
        exit 0
    fi

    if (( remaining <= WARN )); then
        if (( ! beeped )); then warn_sound; beeped=1; fi
        printf '\r\033[K%sWARNING: SHUTDOWN IN %02d SECONDS%s' "$RED" "$remaining" "$RESET"
    else
        beeped=0
        printf '\r\033[K%sGS NULLOUT | %02d:%02d%s' "$YELLOW" "$((remaining / 60))" "$((remaining % 60))" "$RESET"
    fi
    if [[ $backend != manual ]]; then sleep 1; fi
done
