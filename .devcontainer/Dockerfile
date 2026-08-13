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

# Development user. The base node image already provides a `node` user at
# UID/GID 1000 — which matches the workspace's coder uid — so reuse it instead
# of creating a conflicting `coder` user (groupadd would exit 4 on GID clash).
# Granting passwordless sudo for the lifecycle scripts.
ARG USERNAME=node
RUN echo "$USERNAME ALL=\(root\) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Python tooling for evals / SDD. --break-system-packages: Debian bookworm's
# pip blocks system-env installs (PEP 668) — acceptable in an ephemeral image.
RUN pip install --no-cache-dir --break-system-packages --upgrade pip \
    && pip install --no-cache-dir --break-system-packages \
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
# where the project repo is checked out. The `node` user owns it.
COPY scripts/setup-adlc.sh /usr/local/bin/setup-adlc.sh
RUN chown node:node /usr/local/bin/setup-adlc.sh \
    && chmod +x /usr/local/bin/setup-adlc.sh

USER node

ENV SHELL=/bin/bash
ENV PATH="/home/$USERNAME/.local/bin:${PATH}"

RUN git config --global init.defaultBranch main \
    && git config --global user.name "ADLC Developer" \
    && git config --global user.email "adlc@tikal.dev" \
    && git config --global pull.rebase false

WORKDIR /workspaces

CMD ["/bin/bash"]