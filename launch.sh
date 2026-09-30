#!/usr/bin/env bash
echo "ComfyUI loader"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_URL="http://localhost:8188"
FIREFOX_PROFILE_DIR="$HOME/.var/app/org.mozilla.firefox/cache/comfyui-profile"
PROFILE_DIR="$HOME/.var/app/org.chromium.Chromium/data/comfyui-profile"

cleanup() {
    echo "Stopping ComfyUI container..."
    podman-compose down
}
trap cleanup EXIT INT TERM

echo "Running podman-compose..."
# 1. Native GUI progress dialog while starting container
(
    podman-compose up -d &> /dev/null

    until curl -s --head --fail "$APP_URL" > /dev/null; do
        sleep 1
    done
) | zenity --progress \
           --title="ComfyUI" \
           --text="Starting services, please wait..." \
           --pulsate \
           --auto-close \
           --width=350 2> /dev/null

# Check if zenity was canceled or closed by the user
ZENITY_STATUS=${PIPESTATUS[1]}

if [ $ZENITY_STATUS -ne 0 ]; then
    echo "Startup canceled by user."
    exit 1  # Triggers the 'cleanup' trap to run podman-compose down
fi

echo "Container is up"

echo "Launching browser..."

if flatpak info org.chromium.Chromium &> /dev/null; then
    mkdir -p "$PROFILE_DIR"
    flatpak run \
        --env=GDK_BACKEND=x11 \
        org.chromium.Chromium \
        --ozone-platform=x11 \
        --user-data-dir="$PROFILE_DIR" \
        --class="ComfyUI" \
        --app="$APP_URL" &> /dev/null &
    echo "Chromium flatpak launched"

elif flatpak info com.google.Chrome &> /dev/null; then
    PROFILE_DIR="$HOME/.var/app/com.google.Chrome/data/comfyui-profile"
    mkdir -p "$PROFILE_DIR"
    flatpak run \
        --env=GDK_BACKEND=x11 \
        com.google.Chrome \
        --ozone-platform=x11 \
        --user-data-dir="$PROFILE_DIR" \
        --class="ComfyUI" \
        --app="$APP_URL" &> /dev/null &
    echo "Chrome flatpak launched"

elif flatpak info com.microsoft.Edge &> /dev/null; then
    PROFILE_DIR="$HOME/.var/app/com.microsoft.Edge/data/comfyui-profile"
    mkdir -p "$PROFILE_DIR"
    flatpak run \
        --env=GDK_BACKEND=x11 \
        com.microsoft.Edge \
        --ozone-platform=x11 \
        --user-data-dir="$PROFILE_DIR" \
        --class="ComfyUI" \
        --app="$APP_URL" &> /dev/null &
    echo "Edge flatpak launched"

else
    # Create profile and chrome directory if it doesn't already exist
    mkdir -p "$FIREFOX_PROFILE_DIR/chrome"

    # Enable userChrome.css support via user.js
    cat <<'EOF' > "$FIREFOX_PROFILE_DIR/user.js"
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.inTitlebar", 0);
EOF

    # Add CSS to hide the tab bar, navigation bar, and sidebar header
    cat <<'EOF' > "$FIREFOX_PROFILE_DIR/chrome/userChrome.css"
/* Hide the Tab Bar */
#TabsToolbar {
    visibility: collapse !important;
}

/* Hide the Address Bar and Navigation Controls */
#nav-bar {
    visibility: collapse !important;
}
EOF

    # Start firefox, assuming it's installed via flatpak because it is in baseline Bazzite --class="ComfyUI"
    flatpak run org.mozilla.firefox \
        --profile "$FIREFOX_PROFILE_DIR" \
        --new-window "$APP_URL" \
        --name="ComfyUI" \
        --class="ComfyUI" \
        --no-remote &> /dev/null &

    echo "Firefox flatpak launched"
fi

echo "Waiting for browser window to register..."

# Wait for the browser process/window running the app to spawn
# PROFILE_DIR is for chromium browsers, APP_URL is for firefox
until pgrep -f "$PROFILE_DIR" > /dev/null || pgrep -f "$APP_URL" > /dev/null; do
    sleep 0.5
done

echo "App window active. Monitoring process..."

# Monitor for either the Chromium profile path OR Firefox profile path
while pgrep -f "$PROFILE_DIR" > /dev/null || pgrep -f "$APP_URL" > /dev/null; do
    sleep 2
done

echo "App window closed!"
