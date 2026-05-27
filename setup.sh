#!/usr/bin/env bash
#
# Bootstrap script for setting up a new macOS machine
#
# This should be idempotent so it can be run multiple times.
#
# Usage:
#   git clone https://github.com/<you>/dotfiles.git ~/Projects/dotfiles
#   cd ~/Projects/dotfiles
#   chmod +x setup.sh
#   ./setup.sh
#
# Notes:
#   - Install full Xcode from the App Store BEFORE running this script
#     (Homebrew needs the Xcode license accepted)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILURES=()

# --- Helper functions ---

print_step() {
    echo ""
    echo "=========================================="
    echo "  $1"
    echo "=========================================="
    echo ""
}

command_exists() {
    command -v "$1" &>/dev/null
}

try_run() {
    local description="$1"
    shift
    if ! "$@"; then
        FAILURES+=("$description")
        echo "  ⚠ FAILED: $description"
    fi
}

# --- 1. Xcode Command Line Tools ---

print_step "Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
    echo "Xcode Command Line Tools already installed."
else
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Waiting for Xcode Command Line Tools to finish installing..."
    echo "Press any key once the installation is complete."
    read -n 1 -s
fi

if [ -d "/Applications/Xcode.app" ]; then
    echo "Accepting Xcode license..."
    sudo xcodebuild -license accept 2>/dev/null || true
fi

# --- 2. Homebrew ---

print_step "Homebrew"

if command_exists brew; then
    echo "Homebrew already installed."
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

brew update

# --- 3. CLI Packages ---

print_step "CLI Packages (Homebrew formulae)"

PACKAGES=(
    git
    gh
)

echo "Installing packages: ${PACKAGES[*]}"
brew install "${PACKAGES[@]}" 2>/dev/null || true

# --- 4. GUI Apps (Homebrew Casks) ---

print_step "GUI Apps (Homebrew Casks)"

CASKS=(
    brave-browser
    cursor
    figma
    google-chrome
    iterm2
    microsoft-excel
    microsoft-powerpoint
    microsoft-word
    raycast
    spotify
    visual-studio-code
)

echo "Installing cask apps..."
for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        echo "  ✓ $cask already installed"
    else
        echo "  Installing $cask..."
        brew install --cask "$cask" 2>/dev/null || FAILURES+=("cask: $cask")
    fi
done

# --- 5. NVM + Node ---

print_step "NVM + Node.js"

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    try_run "nvm install" curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

if command_exists nvm; then
    echo "Installing latest Node.js via NVM..."
    nvm install node
    nvm use node
    nvm alias default node
    echo "Node $(node --version) installed."
else
    FAILURES+=("nvm: could not load after install")
fi

# --- 6. Bun ---

print_step "Bun"

if command_exists bun; then
    echo "Bun already installed, upgrading..."
    bun upgrade || true
else
    echo "Installing Bun..."
    try_run "bun install" curl -fsSL https://bun.sh/install | bash
fi

# --- 7. Oh My Zsh ---

print_step "Oh My Zsh"

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh already installed."
else
    echo "Installing Oh My Zsh..."
    try_run "oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 8. Powerlevel10k ---

print_step "Powerlevel10k"

P10K_DIR="$HOME/powerlevel10k"

if [ -d "$P10K_DIR" ]; then
    echo "Powerlevel10k already installed, pulling latest..."
    git -C "$P10K_DIR" pull || true
else
    echo "Installing Powerlevel10k..."
    try_run "powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# --- 9. MesloLGS NF Fonts (required by Powerlevel10k) ---

print_step "MesloLGS NF Fonts"

FONT_DIR="$HOME/Library/Fonts"
mkdir -p "$FONT_DIR"

MESLO_FONTS=(
    "MesloLGS%20NF%20Regular.ttf"
    "MesloLGS%20NF%20Bold.ttf"
    "MesloLGS%20NF%20Italic.ttf"
    "MesloLGS%20NF%20Bold%20Italic.ttf"
)

FONT_BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"

for font in "${MESLO_FONTS[@]}"; do
    font_file="${font//%20/ }"
    if [ -f "$FONT_DIR/$font_file" ]; then
        echo "  ✓ $font_file already installed"
    else
        echo "  Downloading $font_file..."
        curl -fsSL "$FONT_BASE_URL/$font" -o "$FONT_DIR/$font_file" || FAILURES+=("font: $font_file")
    fi
done

# --- 10. zsh-autosuggestions ---

print_step "zsh-autosuggestions"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
ZSH_AUTOSUGGEST_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"

if [ -d "$ZSH_AUTOSUGGEST_DIR" ]; then
    echo "zsh-autosuggestions already installed, pulling latest..."
    git -C "$ZSH_AUTOSUGGEST_DIR" pull || true
else
    echo "Installing zsh-autosuggestions..."
    try_run "zsh-autosuggestions" git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGEST_DIR"
fi

# --- 11. pnpm ---

print_step "pnpm"

if command_exists pnpm; then
    echo "pnpm already installed."
else
    echo "Installing pnpm..."
    npm install -g pnpm || FAILURES+=("pnpm")
fi

# --- 12. Meteor ---

print_step "Meteor"

if command_exists meteor; then
    echo "Meteor already installed."
else
    echo "Installing Meteor..."
    curl https://install.meteor.com/ | sh || FAILURES+=("meteor")
fi

# --- 13. Symlink Dotfiles ---

print_step "Symlinking Dotfiles"

symlink_file() {
    local src="$1"
    local dest="$2"

    if [ -L "$dest" ]; then
        echo "  ✓ $dest already symlinked"
    elif [ -f "$dest" ]; then
        echo "  Backing up existing $dest to ${dest}.backup"
        mv "$dest" "${dest}.backup"
        ln -s "$src" "$dest"
        echo "  ✓ Symlinked $dest"
    else
        ln -s "$src" "$dest"
        echo "  ✓ Symlinked $dest"
    fi
}

symlink_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
symlink_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
symlink_file "$DOTFILES_DIR/git/gitconfig.local.symlink" "$HOME/.gitconfig.local"

# --- 14. Git Config ---

print_step "Git Config"

if ! git config --global --get-all include.path 2>/dev/null | grep -q ".gitconfig.local"; then
    git config --global include.path "$HOME/.gitconfig.local"
    echo "  ✓ Added .gitconfig.local to git global include"
fi

git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global core.excludesfile "$DOTFILES_DIR/git/gitignore_global"

echo "  ✓ Git defaults configured (main branch, rebase pull, auto remote, global gitignore)"

# --- 15. Restore iTerm settings ---

print_step "iTerm Settings"

ITERM_PLIST="$DOTFILES_DIR/iterm/com.googlecode.iterm2.plist"
if [ -f "$ITERM_PLIST" ]; then
    echo "Restoring iTerm settings..."
    cp "$ITERM_PLIST" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    echo "  ✓ iTerm settings restored"
else
    echo "  No iTerm settings found in dotfiles."
fi

# --- 16. macOS Defaults ---

print_step "macOS Defaults"

# Fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Show filename extensions by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Require password immediately after sleep or screen saver
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# Enable tap-to-click on trackpad
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Dock: remove recent apps
defaults write com.apple.dock show-recents -bool false

# Dock: icon size 67px
defaults write com.apple.dock tilesize -int 67

# Restart Dock to apply
killall Dock 2>/dev/null || true

echo "macOS defaults configured. Some changes require a logout/restart."

# --- 17. Create folder structure ---

print_step "Folder Structure"

mkdir -p "$HOME/Projects"
echo "  ✓ ~/Projects"

# --- 18. Homebrew cleanup ---

print_step "Cleanup"

brew update
brew upgrade
brew cleanup

# --- Done ---

print_step "Setup Complete!"

if [ ${#FAILURES[@]} -gt 0 ]; then
    echo "⚠ The following items FAILED and need manual attention:"
    echo ""
    for fail in "${FAILURES[@]}"; do
        echo "  ✗ $fail"
    done
    echo ""
fi

echo "Manual steps:"
echo "  1. Import Raycast config: Raycast → Import → select raycast/Raycast.rayconfig"
echo "  2. Install Android Studio from App Store (if needed)"
echo "  3. Restart your terminal"
echo ""
