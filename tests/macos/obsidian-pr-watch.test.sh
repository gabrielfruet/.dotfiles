#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$ROOT_DIR/zsh/bin/obsidian-pr-watch"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-pr-watch-test.XXXXXX")"
FAKE_BIN="$TEMP_DIR/bin"
NOTE="$TEMP_DIR/note.md"
STATE="$TEMP_DIR/state.json"
NOTIFICATIONS="$TEMP_DIR/notifications"
SCENARIO="$TEMP_DIR/scenario"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/osascript" <<'EOF'
#!/bin/bash
last=""
second_last=""
for argument in "$@"; do
  second_last="$last"
  last="$argument"
done
printf '%s\n%s\n---\n' "$last" "$second_last" >> "$NOTIFICATIONS"
EOF
chmod +x "$FAKE_BIN/osascript"

cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/bash
set -euo pipefail

endpoint=""
for argument in "$@"; do
  case "$argument" in
    user|repos/*) endpoint="$argument" ;;
  esac
done
scenario="$(cat "$SCENARIO")"

case "$endpoint" in
  user)
    printf '%s\n' 'gabrielfruet'
    ;;
  repos/acme/widget/pulls/7)
    if [ "$scenario" = baseline ]; then
      printf '%s\n' '{"title":"Widget fix","state":"open","merged_at":null,"head":{"sha":"sha-1"}}'
    else
      printf '%s\n' '{"title":"Widget fix","state":"closed","merged_at":"2026-07-31T12:00:00Z","head":{"sha":"sha-2"}}'
    fi
    ;;
  repos/acme/widget/pulls/7/reviews?per_page=100)
    if [ "$scenario" = baseline ]; then
      printf '%s\n' '[[{"id":1,"state":"PENDING","user":{"login":"reviewer"}}]]'
    else
      printf '%s\n' '[[{"id":1,"state":"APPROVED","user":{"login":"reviewer"}},{"id":2,"state":"CHANGES_REQUESTED","user":{"login":"teammate"}}]]'
    fi
    ;;
  repos/acme/widget/issues/7/comments?per_page=100)
    if [ "$scenario" = baseline ]; then
      printf '%s\n' '[[]]'
    else
      printf '%s\n' '[[{"id":10,"user":{"login":"commenter"}}]]'
    fi
    ;;
  repos/acme/widget/pulls/7/comments?per_page=100)
    if [ "$scenario" = baseline ]; then
      printf '%s\n' '[[]]'
    else
      printf '%s\n' '[[{"id":11,"user":{"login":"reviewer"}}]]'
    fi
    ;;
  repos/acme/widget/commits/sha-1/status)
    printf '%s\n' '{"state":"success"}'
    ;;
  repos/acme/widget/commits/sha-2/status)
    printf '%s\n' '{"state":"failure"}'
    ;;
  repos/acme/widget/commits/sha-1/check-runs?filter=latest\&per_page=100|repos/acme/widget/commits/sha-2/check-runs?filter=latest\&per_page=100)
    printf '%s\n' '[{"check_runs":[]}]'
    ;;
  *)
    printf 'unexpected endpoint: %s\n' "$endpoint" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/gh"

run_watcher() {
  GH_BIN="$FAKE_BIN/gh" OSASCRIPT_BIN="$FAKE_BIN/osascript" NOTIFICATIONS="$NOTIFICATIONS" SCENARIO="$SCENARIO" \
    "$SCRIPT" --note "$NOTE" --state-file "$STATE"
}

assert_contains() {
  grep -F -- "$1" "$2" >/dev/null || {
    printf 'expected %s in %s\n' "$1" "$2" >&2
    exit 1
  }
}

cat > "$NOTE" <<'EOF'
# Daily note

- [PR](https://github.com/acme/widget/pull/7?plain=1#top)
- duplicate https://github.com/acme/widget/pull/7
- ignored https://github.com/acme/widget/issues/7
EOF

printf '%s\n' baseline > "$SCENARIO"
run_watcher
[ -f "$STATE" ]
[ ! -f "$NOTIFICATIONS" ]
jq -e '.prs["https://github.com/acme/widget/pull/7"].head_sha == "sha-1"' "$STATE" >/dev/null

# Identical data remains quiet.
run_watcher
[ ! -f "$NOTIFICATIONS" ]

printf '%s\n' updated > "$SCENARIO"
run_watcher
[ "$(grep -c '^---$' "$NOTIFICATIONS")" -eq 1 ]
assert_contains 'PR updates (1)' "$NOTIFICATIONS"
assert_contains 'reviewer approved' "$NOTIFICATIONS"
assert_contains 'teammate requested changes' "$NOTIFICATIONS"
assert_contains 'commenter added a PR comment' "$NOTIFICATIONS"
assert_contains 'reviewer added an inline review comment' "$NOTIFICATIONS"
assert_contains 'PR merged' "$NOTIFICATIONS"
assert_contains 'CI is failing' "$NOTIFICATIONS"

# The same changed snapshot is deduplicated.
run_watcher
[ "$(grep -c '^---$' "$NOTIFICATIONS")" -eq 1 ]

printf 'obsidian-pr-watch tests passed\n'
