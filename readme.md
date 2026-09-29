# Containerized ComfyUI on Bazzite

[ComfyUI](https://github.com/Comfy-Org/ComfyUI) + [ComfyUI-Manager](https://github.com/comfy-org/ComfyUI-Manager) + [SageAttention](https://github.com/thu-ml/SageAttention) (for nvidia)

This simplifies the install, makes it look like a standalone application, isolates ComfyUI into a container as much as possible, and takes advantage of pre-installed software and drivers on Bazzite, like:

- Firefox flatpak
- Podman
- Gum (for the installer)
- Zenity (for the launcher)
- GPU drivers
- KDE or GNOME

This assumes the user is running [Bazzite](https://bazzite.gg/) (`bazzite-dx` is fine too) on an x86-64 processor and has a GPU.

## Install

Clone this repo into the folder you want to have your user data in.

Run `chmod +x install.sh && ./install.sh` or make it executable via right-click things and double-click it.

If you're using a 40 or 50 series nvidia gpu, open `compose.yaml` and un-comment the `command:` line to use SageAttention.

## Run like an application

Run the ComfyUI application like any installed application.

## User data

These folders will be automatically created and will persist even if the container is changed.

`./models` maps to `ComfyUI/models/`

`./nodes` maps to `ComfyUI/custom_nodes/`

`./output` maps to `ComfyUI/output/`

`./user` maps to `ComfyUI/user/` - workflows are in `user/default/workflows`

These can be remapped in the `compose.yaml` file - you can change your output directory to a network drive, for example.

## AMD

I don't have an AMD GPU test on, but it *should* work.

## Building nvidia image

Instead of automatically downloading the pre-built nvidia image from github, you can build it by downloading the `Dockerfile` and running `podman-compose build`. 

This is really not necessary unless you want to make changes.

## Manual running as a server with full console logs

If you want to run it normally as a command line application and use the UI with your browser of choice, you can just grab 
the compose file for your particular GPU vendor, put it in a folder you want your data to be in, and run `podman-compose -f [amd/intel/nvidia].yaml up`.
