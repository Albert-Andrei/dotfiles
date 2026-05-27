# dotfiles

macOS dev environment setup. Run on a fresh machine:

```bash
git clone https://github.com/<you>/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./setup.sh
```

## What it does

- Xcode CLI tools + Homebrew
- Apps: Brave, Chrome, Cursor, Figma, iTerm, MS Office, Raycast, Spotify, VS Code
- NVM + latest Node, Bun, pnpm, Meteor
- Oh My Zsh + Powerlevel10k + MesloLGS NF fonts + zsh-autosuggestions
- Git config (default branch, rebase, global gitignore)
- Symlinks .zshrc, .p10k.zsh, gitconfig
- Restores iTerm settings
- macOS defaults (key repeat, tap-to-click, show extensions, no recent dock apps)

## After setup

1. Import Raycast config from `raycast/Raycast.rayconfig`
2. Restart terminal
