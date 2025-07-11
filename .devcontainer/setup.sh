#!/bin/bash
set -e

BIN_DIR="/usr/local/bin"

# Fallback als je geen sudo mag
if [ ! -w "$BIN_DIR" ]; then
  echo "⚠️ Cannot write to $BIN_DIR, using ~/.local/bin instead"
  mkdir -p ~/.local/bin
  export PATH=$HOME/.local/bin:$PATH
  BIN_DIR="$HOME/.local/bin"
  echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

# Install Neovim v0.9.5 (static release, Linux)
echo "📦 Installing Neovim..."
curl -LO https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
tar xzf nvim-linux64.tar.gz
mv nvim-linux64 "$HOME/.neovim"
ln -s "$HOME/.neovim/bin/nvim" "$BIN_DIR/nvim"
rm nvim-linux64.tar.gz

# Install kubectl
curl -LO https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl "$BIN_DIR"

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64" -o docker-compose
chmod +x docker-compose
mv docker-compose "$BIN_DIR"

# Install k9s
curl -sSL https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz | tar xz
mv k9s "$BIN_DIR"

# Set global Git identity
git config --global user.name "Micha van Haaren"
git config --global user.email "michavanhaaren@gmail.com"

# Create Neovim config directory
mkdir -p ~/.config/nvim

# Create minimal init.lua with packer and numbertoggle
cat << 'EOF' > ~/.config/nvim/init.lua
-- Auto-install packer if not present
local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  })
  vim.cmd [[packadd packer.nvim]]
end

require("packer").startup(function(use)
  use "wbthomason/packer.nvim"
  use "sitiom/nvim-numbertoggle"
end)

-- Basic settings
vim.o.number = true
vim.o.relativenumber = true
EOF

# Install plugins headlessly
nvim --headless +PackerSync +qa


# Verify installs
echo "✅ Installed versions:"
$BIN_DIR/kubectl version --client
$BIN_DIR/docker-compose version
$BIN_DIR/k9s version || echo "k9s installed"
$BIN_DIR/vim --version | head -n 1 || echo "vim install failed"

echo 'alias vim="nvim"' >> ~/.bashrc
