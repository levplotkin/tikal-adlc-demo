# Tikal ADLC Agentic Dev Container
# =============================================================================
# Dev container image built inside a Coder workspace (via the Dev Containers
# CLI + Docker-in-Docker). Drop this `.devcontainer/` directory into a project
# repo (alongside scripts/setup-adlc.sh) and provision the workspace with the
# Coder template in this directory.
#
# The image carries every coding agent that can run headless (opencode,
# claude-code, codex, gemini-cli, qwen-code) plus the ADLC toolchain
# (adlc-skills-cli). Cursor / Copilot / Devin / Tabnine are configured by
# setup-adlc.sh (slash commands + event hooks) even though they are desktop
# or cloud agents.
# =============================================================================

ARG NODE_VERSION=20
ARG PYTHON_VERSION=3.11

FROM node:${NODE_VERSION}-bookworm-slim AS base

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    bash \
    zsh \
    vim \
    htop \
    jq \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Development user (matches Coder's default coder user in the workspace)
ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Python tooling for evals / SDD
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
    promptfoo \
    deepeval \
    pytest \
    pytest-asyncio \
    pytest-cov \
    pyyaml \
    jinja2 \
    rich \
    typer \
    httpx \
    pydantic \
    pydantic-settings \
    python-dotenv \
    gitpython \
    requests \
    tabulate

# Agent CLIs + ADLC toolchain (headless-capable agents).
# opencode-ai is the correct npm package (NOT @opencode/cli).
RUN npm install -g \
    opencode-ai@latest \
    @anthropic-ai/claude-code@latest \
    @openai/codex@latest \
    @google/gemini-cli@latest \
    @qwen-code/qwen-code@latest \
    adlc-skills-cli@latest \
    tsx@latest \
    typescript@latest

# Ship the ADLC provisioning script so it is always on PATH regardless of
# where the project repo is checked out.
COPY --chown=$USERNAME:$USERNAME scripts/setup-adlc.sh /usr/local/bin/setup-adlc.sh
RUN chmod +x /usr/local/bin/setup-adlc.sh

USER $USERNAME

ENV SHELL=/bin/bash
ENV PATH="/home/$USERNAME/.local/bin:${PATH}"

RUN git config --global init.defaultBranch main \
    && git config --global user.name "ADLC Developer" \
    && git config --global user.email "adlc@tikal.dev" \
    && git config --global pull.rebase false

WORKDIR /workspaces

CMD ["/bin/bash"]