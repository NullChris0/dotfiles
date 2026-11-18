# Dotfiles

Personal Linux configuration managed with Git and GNU Stow.

## Packages

| Package | Managed files |
| --- | --- |
| zsh | .zshrc, .zprofile, .p10k.zsh, local override example |
| git | .gitconfig |
| i3 | i3 and i3status configuration, local override example |
| kitty | Kitty terminal config |
| mise | Tool versions |
| assets | Desktop image assets |
| nvim | Neovim configuration and vim.pack lock file |

Machine-specific proxy endpoints and display commands belong in:

- ~/.config/zsh/local.zsh
- ~/.config/i3/local.conf

These files are deliberately outside the repository. Tracked .example files document their format.

## Prerequisites

Required for installation:

- Git
- GNU Stow
- Zsh
- Neovim 0.12.x
Validation additionally uses i3 and ripgrep.

The shell configuration also expects Oh My Zsh, Powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, direnv, mise, and fzf. The i3 configuration references i3status, rofi, dex, xss-lock, i3lock, NetworkManager's applet, Blueman, dunst, PulseAudio tools, xrandr, feh, picom, and Flameshot. Install these with the operating system's package manager.

Install the Zsh theme and external plugins after installing Oh My Zsh:

~~~bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
~~~

The desktop configuration uses Ubuntu Sans Mono and a Nerd Font for status icons.

## Install

~~~bash
git clone git@github.com:NullChris0/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
./scripts/bootstrap.sh
./scripts/check.sh
~~~

The bootstrap performs a Stow dry run first and stops on conflicting files. Move or back up any reported file, then run it again. It uses stow --no-folding, which leaves real configuration directories in place so local override files can coexist with managed symlinks.

## Update

Edit files through their normal paths under $HOME; managed files resolve into this repository. Then validate and commit:

~~~bash
cd "$HOME/dotfiles"
./scripts/check.sh
git status
git add --all
git commit
git push
~~~

Update Magpie without relying on its built-in proxy detection:

~~~bash
./scripts/update_magpie.sh
~~~

The script reads Magpie's configured proxy, or `MAGPIE_UPDATE_PROXY` when set,
then downloads the latest Linux release for the current architecture.

## Remove Links

~~~bash
cd "$HOME/dotfiles"
stow --dir="$PWD" --target="$HOME" --no-folding --delete \
  zsh git i3 kitty mise assets nvim espanso
~~~

Local override files are regular untracked files and remain after unstowing.
