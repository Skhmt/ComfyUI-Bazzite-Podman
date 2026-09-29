#!/usr/bin/env bash
echo "ComfyUI loader"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_URL="http://localhost:8188"
FIREFOX_PROFILE_DIR="$HOME/.var/app/org.mozilla.firefox/cache/comfyui-profile"

cleanup() {
    echo "Stopping ComfyUI container..."
    podman-compose down
    # rm -rf "$FIREFOX_PROFILE_DIR" # don't clean this up to save preferences
}
trap cleanup EXIT INT TERM

echo "Running podman-compose..."
# 1. Native GUI progress dialog while starting container
(
    podman-compose up -d > /dev/null 2>&1

    until curl -s --head --fail "$APP_URL" > /dev/null; do
        sleep 1
    done
) | zenity --progress \
           --title="ComfyUI" \
           --text="Starting services, please wait..." \
           --pulsate \
           --auto-close \
           --width=350 2>/dev/null

# Check if zenity was canceled or closed by the user
ZENITY_STATUS=${PIPESTATUS[1]}

if [ $ZENITY_STATUS -ne 0 ]; then
    echo "Startup canceled by user."
    exit 1  # Triggers the 'cleanup' trap to run podman-compose down
fi

echo "Container is up"

FLAGS="--user-data-dir=$PROFILE_DIR"

echo "Launching browser..."

# 1. Create profile and chrome directory
mkdir -p "$FIREFOX_PROFILE_DIR/chrome"

# 2. Enable userChrome.css support via user.js
cat <<EOF > "$FIREFOX_PROFILE_DIR/user.js"
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.inTitlebar", 0);
EOF

# 3. Add CSS to hide the tab bar, navigation bar, and sidebar header
cat <<EOF > "$FIREFOX_PROFILE_DIR/chrome/userChrome.css"
/* Hide the Tab Bar */
#TabsToolbar {
    visibility: collapse !important;
}

/* Hide the Address Bar and Navigation Controls */
#nav-bar {
    visibility: collapse !important;
}
EOF

flatpak run org.mozilla.firefox --profile "$FIREFOX_PROFILE_DIR" --new-window "$APP_URL" --no-remote > /dev/null 2>&1 &
echo "Firefox flatpak launched"

echo "Waiting for browser window to register..."

# Wait for the browser process/window running the app to spawn
until pgrep -f "$APP_URL" > /dev/null; do
    sleep 0.5
done

echo "App window active. Monitoring process..."

# Hold script execution while any browser process is referencing localhost:8188
while pgrep -f "$APP_URL" > /dev/null; do
    sleep 2
done

echo "App window closed!"
