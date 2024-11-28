#!/bin/env bash

# doesnt print the [1]+done of a bg process
set +m

TIME_DIFF_SECONDS_THRESH=$((60*60*6))

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

_fetch_one_repo() {
    cd "$1" || exit && git fetch && echo "${GREEN}Done fetching$RESET $1"
}

_fetch_multiple_repos() {
    pids=()
    repos="$1"

    while IFS= read -r repo; do
        fetch_head_file="$repo/.git/FETCH_HEAD"

        fetch_head_time=$(stat -c %Y "$fetch_head_file")
        current_time=$(date +%s)

        time_diff_seconds=$((current_time - fetch_head_time))

        if [ $time_diff_seconds -gt $TIME_DIFF_SECONDS_THRESH ]; then
            days=$((time_diff_seconds/(24*60*60)))
            daystr=$(test $days -gt 0  && echo "$days days" || echo "")
            
            echo "Repository $BLUE$repo$RESET"
            echo "${YELLOW}The last 'git fetch' was more than the threshold:$RESET $daystr $(date -d @$time_diff_seconds -u +"%H:%M:%S") ago."

            _fetch_one_repo "$repo" &

            pids+=($!)
        fi
    done <<< "$repos"

    #echo "${pids[@]}"

    # wait for all pids
    for pid in "${pids[@]}"; do
        wait "$pid" || echo "Some when fetching $repo"
    done
}

# Find all Git repositories under the home directory
_find_git_repos() {
    find ~/dev ~/docs ~/.dotfiles -type d -name ".git" -exec dirname {} \;
}

_git_get_branch() {
    branch_name="$(git branch | head -n 1 | sed 's/\**\s*//')"
    [ "$branch_name" = "(no branch)" ] && echo "no-branch" || echo "$branch_name"
}

# Function to rank and label repositories
_label_repos() {
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

        branch=$(echo -e "$PURPLE$(_git_get_branch)$RESET")
        # Output rank, label, and repository path
        echo "$label $branch $repo"
    done
}

# Main function
_git_global() {
    repos=$(_find_git_repos)
    if [[ -z $repos ]]; then
        echo "No Git repositories found under the home directory."
        exit 1
    fi

    _fetch_multiple_repos "$repos"

    selected_repo=$(echo "$repos" \
        | _label_repos \
        | fzf \
        --preview "cd {$PATH_POSITION} && git -c color.status=always status" \
        --tmux center,80%\
        --preview-window=right:60% \
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

      case "$action" in
        "push")
            cd "$repo_path" || exit 1 && echo "pushing..." ; git push
            ;;
        "pull")
            cd "$repo_path" || exit 1 && echo "pulling..." ; git pull
            ;;
        "go to directory")
            cd "$repo_path" || exit 1
            ;;
        "lazygit")
            cd "$repo_path" || exit 1 && lazygit
            ;;
      esac
  fi
}

