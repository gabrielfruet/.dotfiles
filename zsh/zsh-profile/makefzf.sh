#!/bin/env zsh
# makefzf.sh — sourced by sourcerer.zsh
#
# Defines fm(): a fuzzy finder for make targets with a live preview of
# each target's recipe. Lists every target in the current directory's
# Makefile; press Enter to run the chosen target with make.
#
# Keys:   Enter        run the selected target
#         Esc          cancel
#         C-/          toggle the preview pane

fm() {
    emulate -L zsh
    setopt local_options pipe_fail

    if (( $+commands[fzf] == 0 )); then
        print -u2 -- "fm: fzf is required but not installed."
        return 1
    fi
    if (( $+commands[make] == 0 )); then
        print -u2 -- "fm: make is required but not installed."
        return 1
    fi

    case "${1:-}" in
        -h|--help)
            cat <<'EOF'
fm — fuzzy find make targets

Lists every target in the current directory's Makefile and shows the
recipe for the highlighted one in a preview pane. Press Enter to run
the chosen target with `make`.

Usage: fm
EOF
            return 0
            ;;
    esac

    # Locate the Makefile
    local makefile
    for f in Makefile makefile GNUmakefile; do
        if [[ -f "$f" ]]; then
            makefile="$f"
            break
        fi
    done
    if [[ -z "$makefile" ]]; then
        print -u2 -- "fm: no Makefile found in ${PWD}"
        return 1
    fi

    # Build a small preview helper script. We use a temp file (rather
    # than a shell function) so fzf's preview subshell — which is a
    # fresh sh — can call it without depending on exported functions.
    local preview_script
    preview_script=$(mktemp -t fm-preview.XXXXXX) || return 1

    cat > "$preview_script" <<'EOF'
#!/bin/sh
target=$1
mf=${FM_MAKEFILE:-Makefile}
start=$(grep -nE "^${target}:" "$mf" 2>/dev/null | head -n1 | cut -d: -f1)
if [ -z "$start" ]; then
    printf 'No rule for target: %s\n' "$target"
    exit 0
fi
end=$(awk -v s="$start" '
    NR > s && $0 !~ "^[ \t]" && $0 ~ ":" && $0 !~ "=" {
        print NR; exit
    }' "$mf")
if [ -z "$end" ]; then
    end=$(wc -l < "$mf")
else
    end=$((end - 1))
fi
sed -n "${start},${end}p" "$mf"
EOF
    chmod +x "$preview_script"

    # Clean up the temp script on exit / interrupt
    trap "rm -f '$preview_script'" EXIT INT TERM

    # Pull the list of user-defined targets straight from the Makefile.
    # Faster and cleaner than `make -np`, which dumps built-in
    # implicit rules and internal variables.
    local targets
    targets=$(grep -E '^[A-Za-z0-9_./%+-][^:]*:' "$makefile" \
        | sed 's/:.*$//' \
        | sort -u)

    if [[ -z "$targets" ]]; then
        print -u2 -- "fm: no targets found in $makefile"
        return 1
    fi

    export FM_MAKEFILE="$makefile"
    local selected
    selected=$(print -r -- "$targets" | fzf \
        --prompt="make ❯ " \
        --preview "$preview_script {}" \
        --preview-window=right:60%:wrap \
        --height=80% \
        --border \
        --no-info \
        --bind 'ctrl-/:toggle-preview' \
        --header 'Enter: run • Esc: cancel • C-/: toggle preview')

    if [[ -n "$selected" ]]; then
        make -f "$makefile" "$selected"
    fi
}
