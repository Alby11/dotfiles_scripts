#!/usr/bin/env zsh

# Function to display messages
info() {
  echo "\033[1;32m[INFO]\033[0m $1"
}

error() {
  echo "\033[1;31m[ERROR]\033[0m $1"
  exit 1
}

# Detect the operating system
OS=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  error "Unsupported operating system."
fi

# Update and install prerequisites based on the operating system
info "Updating package list and installing prerequisites for $OS..."
case "$OS" in
ubuntu | debian)
  sudo apt update && sudo apt install -y \
    make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget \
    curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev \
    python3-openssl git
  ;;
fedora)
  sudo dnf install -y \
    make gcc zlib-devel bzip2 bzip2-devel \
    readline-devel sqlite sqlite-devel wget \
    curl llvm ncurses-devel tk-devel \
    libffi-devel xz-devel git
  ;;
arch)
  sudo pacman -Syu --noconfirm \
    base-devel openssl zlib \
    bzip2 readline sqlite wget \
    curl llvm ncurses tk \
    libffi xz git
  ;;
*)
  error "Unsupported operating system: $OS"
  ;;
esac

# Install pyenv
if ! command -v pyenv &>/dev/null; then
  info "Installing pyenv..."
  curl https://pyenv.run | bash
else
  info "pyenv is already installed."
fi

# Configure pyenv in .zshrc
info "Configuring pyenv in ~/.zshrc..."
{
  echo 'export PATH="$HOME/.pyenv/bin:$PATH"'
  echo 'eval "$(pyenv init --path)"'
  echo 'eval "$(pyenv init -)"'
  echo 'eval "$(pyenv init -)"'
  echo 'eval "$(pyenv virtualenv-init -)"'
} >>~/.zshrc

# Apply changes to current shell
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Install the latest stable Python version
info "Installing the latest stable Python version with pyenv..."
latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
pyenv install "$latest_python"
pyenv global "$latest_python"

# Install pipx
if ! command -v pipx &>/dev/null; then
  info "Installing pipx..."
  python -m pip install --user pipx
  python -m pipx ensurepath
else
  info "pipx is already installed."
fi

# Apply pipx to current shell
export PATH="$HOME/.local/bin:$PATH"

# Install poetry using pipx
if ! command -v poetry &>/dev/null; then
  info "Installing poetry with pipx..."
  pipx install poetry
else
  info "poetry is already installed."
fi

# Configure poetry to create virtual environments inside project directories
info "Configuring poetry to create virtual environments inside project directories..."
poetry config virtualenvs.in-project true

# Source .zshrc to apply all changes
info "Sourcing ~/.zshrc to apply all changes..."
source ~/.zshrc

info "Migration to pyenv, pipx, and poetry completed successfully."
