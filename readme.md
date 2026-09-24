# Containerized ComfyUI on Bazzite-nvidia

[ComfyUI](https://github.com/Comfy-Org/ComfyUI) + [ComfyUI-Manager](https://github.com/comfy-org/ComfyUI-Manager) + [SageAttention 2.2.0](https://github.com/thu-ml/SageAttention) in a ~9GB Podman container.

Assumes the user is running [Bazzite-nvidia](https://bazzite.gg/) (`bazzite-dx-nvidia` is fine too) on an x86-64 processor.

This doesn't require root, it isolates ComfyUI into a container as much as possible, and takes advantage of pre-installed software and drivers on Bazzite.

## Install

Put the `Dockerfile` and `compose.yaml` files from this repository into a folder somewhere. Maybe this readme too?

Install podman-compose: `pip install podman-compose` 

Build the image: `podman-compose build`

Building the image can take a few minutes, but only ever needs to be done once.

## Run

`podman-compose up`

## User data

These folders will be automatically created and will persist even if the container is changed.

`./models` maps to `ComfyUI/models/`

`./nodes` maps to `ComfyUI/custom_nodes/`

`./output` maps to `ComfyUI/output/`

`./workflows` maps to `ComfyUI/user/default/workflows`

These can be remapped in the `compose.yaml` file - you can change your output directory to a network drive, for example.

## Intel and AMD gpu users

I don't have these to test on, but if you go into `Dockerfile` and `compose.yaml`, I left comments in how you can supposedly get those working.

## To do

- [SageAttention](https://github.com/thu-ml/SageAttention) + Triton
- [FlashAttention](https://github.com/dao-ailab/flash-attention)
