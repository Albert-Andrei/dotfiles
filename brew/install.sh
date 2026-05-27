#!/usr/bin/env bash
#
# Homebrew package installation (standalone)
# This is also called by the main setup.sh script.
#

set -e

echo "Checking if Homebrew is already installed..."

if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "Homebrew is already installed."
fi

brew update

# CLI tools
PACKAGES=(
    git
    gh
)

echo "Installing CLI packages..."
brew install "${PACKAGES[@]}" || true

# GUI apps
CASKS=(
    brave-browser
    cursor
    figma
    google-chrome
    iterm2
    microsoft-excel
    microsoft-powerpoint
    microsoft-word
    musescore
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
        brew install --cask "$cask" || echo "  ⚠ Failed: $cask"
    fi
done

echo "Updating and upgrading Homebrew..."
brew update
brew upgrade
brew cleanup

echo "Homebrew setup complete."
