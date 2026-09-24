# https://github.com/Comfy-Org/ComfyUI#manual-install-windows-linux

FROM python:3.13.15-bookworm

# prevent interactive prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# override PEP 668 to allow pip installs inside the Docker container
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# install Python, git, and required build tools in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# clone ComfyUI
RUN git clone https://github.com/Comfy-Org/ComfyUI.git /app

WORKDIR /app

# Nvidia
RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

# AMD
# RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm7.2

# install ComfyUI dependencies
RUN pip install --no-cache-dir -r requirements.txt

# install ComfyUI-Manager
RUN pip install --no-cache-dir -r manager_requirements.txt

# pre-install common custom node dependencies (fixes warnings & boot delays)
# - matplotlib: required by Comfyroll & image custom nodes
# - matrix-nio: disables ComfyUI-Manager matrix sharing warning
# - PyOpenGL: silences OpenGL acceleration warnings
RUN pip install --no-cache-dir \
    matplotlib \
    matrix-nio \
    PyOpenGL

# clean up pip cache
# RUN pip cache purge

# default ComfyUI port
EXPOSE 8188

# explicitly listen to 0.0.0.0 and use port 8188, even though those are the defaults
# --enable-manager is for ComfyUI-Manager and --enable-cors-header is necessary for it to work in a container
CMD ["sh", "-c", "exec python /app/main.py --enable-manager --enable-cors-header --listen 0.0.0.0 --port 8188"]
