function gb() {
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||') || default_branch=master
    selected_branch="$(git branch --list --format="%(refname:short)" | fzf --preview "git diff --color=always origin/$default_branch..{}")"
    if [[ -n "$selected_branch" ]]; then
        git checkout "$selected_branch"
    fi
}
