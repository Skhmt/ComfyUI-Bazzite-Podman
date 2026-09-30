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

# Create profile and chrome directory if it doesn't already exist
mkdir -p "$FIREFOX_PROFILE_DIR/chrome"

# Enable userChrome.css support via user.js
cat <<'EOF' > "$FIREFOX_PROFILE_DIR/user.js"
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.tabs.inTitlebar", 0);
EOF

# Add CSS to hide the tab bar, navigation bar, and sidebar header
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

# Start firefox, assuming it's installed via flatpak because it is in baseline Bazzite --class="ComfyUI"
flatpak run org.mozilla.firefox --profile "$FIREFOX_PROFILE_DIR" --new-window "$APP_URL" --name="ComfyUI" --no-remote &> /dev/null &
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
