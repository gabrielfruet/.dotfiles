# Dotfile Repository 📂

## Overview
This repository contains dotfiles managed by a script using GNU Stow to symlink configurations from this repository to your home directory. It supports selective operations based on configuration located in the `pkg` file of each package.

## Repository Structure 🏗️
- Each subdirectory of the repository is considered a "package".
- A package **must** contain a file named `pkg`, which specifies custom target directories for the symlinks.

## Script Features 🛠️
- The script traverses each package directory and uses GNU Stow to create symlinks in the home directory or a specified target directory.
- It supports ignoring specific paths and provides verbose output by default.
- Substitutes dot-NAME for .NAME, this make the dotfiles more readable, as they are not hidden in this way. 

## Basic Usage 🚀
1. **Clone the repository:**
   ```sh
   git clone https://github.com/gabrielfruet/.dotfiles
   cd .dotfiles 
   ```
2. **Run the management script:**
   - To symlink all packages to their respective locations:
     ```sh
     ./stowit
     ```
   - To simulate the creation of symlinks without making any changes:
     ```sh
     ./stowit -s
     ```
   - To delete all symlinks created by the script:
     ```sh
     ./stowit -u
     ```

### Note 📝
- Ensure GNU Stow is installed on your system to use this script.
- The `-s` option simulates the stow process, which is useful for testing.
- Use the `-u` option to uninstall or remove all symlinks created by the script.

## macOS PR watcher

`~/bin` is managed by the existing `zsh` package; the `macos` package installs
the user LaunchAgent.
It checks GitHub PR URLs from today's planning note every 15 minutes and sends a
single native notification for new reviewer activity, lifecycle changes, and
failing CI.

```sh
./stowit.sh zsh
./stowit.sh macos
plutil -lint "$HOME/Library/LaunchAgents/com.gabrielfruet.obsidian-pr-watch.plist"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.gabrielfruet.obsidian-pr-watch.plist"
launchctl kickstart -k "gui/$(id -u)/com.gabrielfruet.obsidian-pr-watch"
```

The first successful run silently records the PRs in the note. Run it manually
without changing state or showing a notification with:

```sh
obsidian-pr-watch --dry-run
```

Diagnostics are written to `~/Library/Logs/obsidian-pr-watch.log`. To unload the
agent, run:

```sh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.gabrielfruet.obsidian-pr-watch.plist"
```
