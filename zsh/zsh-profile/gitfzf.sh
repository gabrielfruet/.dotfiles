function gb() {
    selected_branch="$(git branch --list --format="%(refname:short)" | fzf --preview "git diff --color=always main..{}")"
    if [[ -n "$selected_branch" ]]; then
        git checkout "$selected_branch"
    fi
}
