# Use a base image
FROM mcr.microsoft.com/devcontainers/base:trixie

# Install system dependencies needed by mise and the tools it manages (like Node.js, Python, etc.)
# The exact dependencies may vary based on the tools you plan to use
RUN apt-get update && apt-get -y --no-install-recommends install \
    sudo curl git ca-certificates build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev libyaml-dev wget unzip \
    ca-certificates openssh-client lsb-release libncursesw5-dev xz-utils tk-dev \
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev gettext \
    && rm -rf /var/lib/apt/lists/*

# Set the shell to bash with pipefail option for safe script execution
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install mise CLI using the official script
USER vscode
RUN curl https://mise.run | sh
ENV PATH="/home/vscode/.local/bin:$PATH"
