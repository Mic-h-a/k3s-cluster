#!/bin/bash
set -e

BIN_DIR="/usr/local/bin"

# Fallback if /usr/local/bin is not writable
if [ ! -w "$BIN_DIR" ]; then
  echo "⚠️ Cannot write to $BIN_DIR, using ~/.local/bin instead"
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
  BIN_DIR="$HOME/.local/bin"
  grep -qxF 'export PATH=$HOME/.local/bin:$PATH' ~/.bashrc || echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

# Install Neovim v0.9.5
echo "📦 Installing Neovim..."
curl -LO https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
tar xzf nvim-linux64.tar.gz
mv nvim-linux64 "$HOME/.neovim"
ln -sf "$HOME/.neovim/bin/nvim" "$BIN_DIR/nvim"
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

# Git pretty diff pager
git config --global core.pager delta

# Git pretty log alias
git config --global alias.lg "log --pretty='%C(red)%h%Creset | %C(bold yellow)%d%Creset %s %C(dim white)(%cr by %an)%Creset' --graph"

# Neovim config
mkdir -p ~/.config/nvim
cat << 'EOF' > ~/.config/nvim/init.lua
-- Auto-install packer
local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
  vim.cmd [[packadd packer.nvim]]
end

require("packer").startup(function(use)
  use "wbthomason/packer.nvim"
  use "sitiom/nvim-numbertoggle"
end)

vim.o.number = true
vim.o.relativenumber = true
EOF

# Headless plugin sync (non-blocking)
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync' || echo "⚠️ Neovim plugin install failed"

# Install Homebrew (non-interactive)
if ! command -v brew >/dev/null 2>&1; then
  echo "📦 Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  BREW_INIT='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
  grep -qxF "$BREW_INIT" ~/.bashrc || echo "$BREW_INIT" >> ~/.bashrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Install sops and age
brew install sops age

# Install Git Delta for better diffs
brew install git-delta

# Install Starship prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y
grep -qxF 'eval "$(starship init bash)"' ~/.bashrc || echo 'eval "$(starship init bash)"' >> ~/.bashrc

# Starship config
mkdir -p ~/.config
cat <<'EOF' > ~/.config/starship.toml
format = "$directory$kubernetes$git_branch$git_status $character"

add_newline = true

[directory]
truncation_length = 3

[git_branch]
symbol = " "

[git_status]
style = "bold red"

[kubernetes]
symbol = "☸️ "
format = '[$symbol$context(\($namespace\))]($style) '
style = "cyan"
disabled = false
EOF


# Optional alias for nvim
grep -qxF 'alias vim="nvim"' ~/.bashrc || echo 'alias vim="nvim"' >> ~/.bashrc

# Verify installs
echo "✅ Installed versions:"
$BIN_DIR/kubectl version --client || true
$BIN_DIR/docker-compose version || true
$BIN_DIR/k9s version || echo "k9s installed"
$BIN_DIR/nvim --version | head -n 1 || echo "Neovim install failed"
