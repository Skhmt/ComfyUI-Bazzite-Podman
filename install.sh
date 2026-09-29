#!/usr/bin/env bash

# This assumes pip, podman, and whiptail are installed, which they should be.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

SHORTCUT_NAME="ComfyUI.desktop"
DESKTOP_CONTENT="[Desktop Entry]
Type=Application
Name=ComfyUI
Comment=Run ComfyUI
Exec=$SCRIPT_DIR/launch.sh
Icon=$SCRIPT_DIR/comfyui.png
Terminal=false
StartupWMClass=comfyui-app
Categories=Graphics;"

# Define container images for each hardware target
IMAGE_INTEL="docker.io/yanwk/comfyui-boot:xpu"
IMAGE_AMD="docker.io/yanwk/comfyui-boot:rocm7"
IMAGE_NVIDIA="ghcr.io/skhmt/comfyui-bazzite-podman:main"

# Make launch.sh executable
chmod +x $SCRIPT_DIR/launch.sh

SELECTION=$(gum choose "Intel" "Nvidia" "AMD" "CANCEL" --header "Select your GPU architecture:") || {
    echo "Operation cancelled by user."
    exit 0
}

case "$SELECTION" in
    Intel)
        echo "Intel selected"
        cp -f intel.yaml compose.yaml
        podman pull $IMAGE_INTEL
        ;;
    Nvidia)
        echo "Nvidia selected"
        cp -f nvidia.yaml compose.yaml
        podman pull $IMAGE_NVIDIA
        ;;
    AMD)
        echo "AMD selected"
        cp -f amd.yaml compose.yaml
        podman pull $IMAGE_AMD
        ;;
    CANCEL)
        echo "Operation cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice." >&2
        exit 1
        ;;
esac

echo "Checking for podman-compose..."
if ! command -v podman-compose &> /dev/null; then
    echo "Installing podman-compose"
    pip install podman-compose
else
    echo "Found."
fi

# Target installation directories
TARGET_DIRS=(
    "$HOME/.local/share/applications"
)

# Install to each directory
for dir in "${TARGET_DIRS[@]}"; do
    # Ensure directory exists
    mkdir -p "$dir"

    FILE_PATH="${dir}/${SHORTCUT_NAME}"
    echo "Creating shortcut at $FILE_PATH"

    printf "%s\n" "$DESKTOP_CONTENT" >| "$FILE_PATH"

    chmod +x "$FILE_PATH"

    # Enable launch trust if on Desktop (GNOME extension support)
    if [[ "$dir" == *"Desktop"* ]] && command -v gio &> /dev/null; then
        gio set "$FILE_PATH" metadata::trusted true 2> /dev/null || true
    fi
done

# Refresh desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2> /dev/null || true
fi

echo "Finished."
