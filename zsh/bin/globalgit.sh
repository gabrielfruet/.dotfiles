#!/bin/env bash


BLUE='\033[94m'
RED='\033[91m'
YELLOW='\033[93m'
GREEN='\033[92m'
PURPLE='\e[0;35m'
RESET='\033[0m'

GIT_BRANCH_UNICODE="$(echo -e "$PURPLE $RESET")"

PATH_POSITION=3

UNCOMITTED_LABEL=$(echo -e "${RED}[Uncommitted]${RESET}")
UNPUSHED_LABEL=$(echo -e "${BLUE}[Behind]${RESET}")
UNPULLED_LABEL=$(echo -e "${YELLOW}[Ahead]${RESET}")
CLEAN_LABEL=$(echo -e "${GREEN}[Clean]${RESET}")

# Find all Git repositories under the home directory
find_git_repos() {
    find ~/dev ~/docs ~/.dotfiles -type d -name ".git" -exec dirname {} \;
}

get_branch() {
    git branch | head -n 1 | sed 's/\**\s*//' 
}

# Function to rank and label repositories
rank_and_label_repos() {
    while read -r repo; do
        cd "$repo" || continue
        git_output=$(git status --porcelain --branch 2>/dev/null || echo "")

        if [[ -z $git_output ]]; then
            # Skip non-Git directories or inaccessible repos
            continue
        fi

        label=""

        # Check for uncommitted changes or untracked files
        if echo "$git_output" | grep -qE '^(\?\?| M| M|A|D|R|C)'; then
            label="$label$UNCOMITTED_LABEL"
        fi

        # Check for unpushed commits
        if echo "$git_output" | grep -q '\[.*behind.*\]'; then
            label="$label$UNPUSHED_LABEL"
        fi

        # Check for unpulled commits
        if echo "$git_output" | grep -q '\[.*ahead.*\]'; then
            label="$label$UNPULLED_LABEL"
        fi

        # Check if its clean
        if [ -z "$label" ]; then
            label="$CLEAN_LABEL"
        fi

        branch=$(echo -e "$PURPLE$(get_branch)$RESET")
        # Output rank, label, and repository path
        echo "$label $branch $repo"
    done
}

# Main function
main() {
    repos=$(find_git_repos)
    if [[ -z $repos ]]; then
        echo "No Git repositories found under the home directory."
        exit 1
    fi

  # Use fzf to select a repository
  export FZF_GIT_COLOR=auto
  selected_repo=$(echo "$repos" \
      | rank_and_label_repos \
      | fzf \
        --preview "cd {$PATH_POSITION} && git -c color.status=always status" \
        --preview-window=up:40% \
        --bind=ctrl-u:preview-half-page-up \
        --bind=ctrl-d:preview-half-page-down \
        --layout=reverse \
        --ansi\
    )
  if [[ -n $selected_repo ]]; then
      repo_path=$(echo "$selected_repo" | awk "{print \$$PATH_POSITION}")
      if [[ -z $repo_path ]]; then
          echo "No repository selected."
          exit 1
      fi

      action=$(gum filter "push" "pull" "go to directory" "lazygit" --placeholder="action...")

      if [[ -z $action ]]; then
          echo "No action selected."
          exit 1
      fi

      cmd=""

      case "$action" in
        "push")
            cmd="cd \"$repo_path\" || exit 1 && echo \"pushing...\" ; git push"
            ;;
        "pull")
            cmd="cd \"$repo_path\" || exit 1 && echo \"pulling...\" ; git pull"
            ;;
        "go to directory")
            cmd="cd \"$repo_path\" || exit 1"
            ;;
        "lazygit")
            cmd="cd \"$repo_path\" || exit 1 && lazygit"
            ;;
      esac
      if [[ "$1" = "echo" ]]; then
          echo "$cmd"
      else
          eval "$cmd"
      fi

      cd "$repo_path" || exit
  fi
}

main "$1"

