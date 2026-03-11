#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/github_pr.sh
source "$SCRIPT_DIR/lib/github_pr.sh"

usage() {
  cat <<'EOF'
Usage:
  ./pr.sh info <PR_URL> [--json]
  ./pr.sh cicd <PR_URL> [--json]
  ./pr.sh files <PR_URL> [--json]
  ./pr.sh errors <PR_URL> [--json] [--logs]
  ./pr.sh mine [state] [--json]

States:
  open | closed | merged | all
EOF
}

join_csv() {
  local value="$1"

  if [[ -z "$value" ]]; then
    echo "-"
  else
    echo "$value"
  fi
}

parse_pr_command_args() {
  COMMAND_PR_URL=""
  COMMAND_JSON=0
  COMMAND_LOGS=0

  while (($# > 0)); do
    case "$1" in
      --json)
        COMMAND_JSON=1
        ;;
      --logs)
        COMMAND_LOGS=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        if [[ -z "$COMMAND_PR_URL" ]]; then
          COMMAND_PR_URL="$1"
        else
          fail "Unexpected argument: $1"
        fi
        ;;
    esac
    shift
  done

  if [[ -z "$COMMAND_PR_URL" ]]; then
    fail "Missing PR URL"
  fi

  if ! parse_pr_url "$COMMAND_PR_URL"; then
    fail "Invalid PR URL. Expected: https://github.com/owner/repo/pull/123"
  fi
}

print_info_text() {
  local pr_json="$1"

  echo "$pr_json" | jq -r '
    def csv(values): if (values | length) == 0 then "-" else (values | join(", ")) end;
    [
      "PR: \(.base.repo.owner.login)/\(.base.repo.name)#\(.number)",
      "Title: \(.title)",
      "State: \(.state)",
      "Author: \(.user.login)",
      "Draft: \(.draft)",
      "Branch: \(.head.ref) -> \(.base.ref)",
      "Commits: \(.commits)",
      "Files: \(.changed_files)",
      "Diff: +\(.additions) / -\(.deletions)",
      "Labels: \(csv(.labels | map(.name)))",
      "Reviewers: \(csv(.requested_reviewers | map(.login)))",
      "URL: \(.html_url)"
    ] | join("\n")
  '
}

command_info() {
  parse_pr_command_args "$@"
  require_gh_auth
  require_jq

  local pr_json
  pr_json="$(get_pr_json)"

  if [[ "$COMMAND_JSON" -eq 1 ]]; then
    echo "$pr_json" | jq '{
      number,
      title,
      state,
      draft,
      author: .user.login,
      owner: .base.repo.owner.login,
      repo: .base.repo.name,
      baseRef: .base.ref,
      headRef: .head.ref,
      headSha: .head.sha,
      labels: [.labels[].name],
      reviewers: [.requested_reviewers[].login],
      changedFiles: .changed_files,
      additions,
      deletions,
      commits,
      url: .html_url
    }'
    return 0
  fi

  print_info_text "$pr_json"
}

command_files() {
  parse_pr_command_args "$@"
  require_gh_auth
  require_jq

  local files_json
  files_json="$(gh api "repos/$GITHUB_PR_OWNER/$GITHUB_PR_REPO/pulls/$GITHUB_PR_NUMBER/files?per_page=100")"

  if [[ "$COMMAND_JSON" -eq 1 ]]; then
    echo "$files_json" | jq '[.[] | {
      path: .filename,
      status,
      additions,
      deletions,
      changes
    }]'
    return 0
  fi

  local total
  total="$(echo "$files_json" | jq 'length')"

  echo "PR: $(repo_ref)#$GITHUB_PR_NUMBER"
  echo "Files changed: $total"
  echo "$files_json" | jq -r '.[] | "- \(.status): \(.filename) (+\(.additions)/-\(.deletions))"'
}

command_cicd() {
  parse_pr_command_args "$@"
  require_gh_auth
  require_jq

  local head_sha workflow_json
  head_sha="$(get_pr_head_sha)"
  workflow_json="$(gh api "repos/$GITHUB_PR_OWNER/$GITHUB_PR_REPO/actions/runs?head_sha=$head_sha&per_page=20")"

  if [[ "$COMMAND_JSON" -eq 1 ]]; then
    echo "$workflow_json" | jq --arg head_sha "$head_sha" '{
      headSha: $head_sha,
      runs: [
        .workflow_runs[] | {
          name,
          status,
          conclusion,
          event,
          branch: .head_branch,
          url: .html_url,
          createdAt: .created_at,
          updatedAt: .updated_at
        }
      ]
    }'
    return 0
  fi

  local total failed pending
  total="$(echo "$workflow_json" | jq '.workflow_runs | length')"
  failed="$(echo "$workflow_json" | jq '[.workflow_runs[] | select(.conclusion == "failure")] | length')"
  pending="$(echo "$workflow_json" | jq '[.workflow_runs[] | select(.status != "completed")] | length')"

  echo "PR: $(repo_ref)#$GITHUB_PR_NUMBER"
  echo "Head SHA: $head_sha"
  echo "Workflow runs: $total"
  echo "Failed: $failed"
  echo "Pending: $pending"
  echo "$workflow_json" | jq -r '.workflow_runs[] | "- \(.name): \(.conclusion // .status) | \(.html_url)"'
}

get_failed_checks_json() {
  local head_sha="$1"
  gh api "repos/$GITHUB_PR_OWNER/$GITHUB_PR_REPO/commits/$head_sha/check-runs"
}

get_check_annotations_json() {
  local check_id="$1"

  if ! gh api "repos/$GITHUB_PR_OWNER/$GITHUB_PR_REPO/check-runs/$check_id/annotations?per_page=20" 2>/dev/null; then
    empty_json_array
  fi
}

extract_log_summary_lines() {
  local job_id="$1"
  local logs

  logs="$(gh run view --repo "$(repo_ref)" --job "$job_id" --log-failed 2>/dev/null || true)"

  if [[ -z "$logs" ]]; then
    return 0
  fi

  printf '%s\n' "$logs" \
    | tr -d '\r' \
    | grep -E 'AssertionError|^FAILED| FAILED |Error:|Traceback|F[0-9]{3}\b|E[0-9]{3}\b' \
    | awk '!seen[$0]++' \
    | head -10 || true
}

get_failed_jobs_json() {
  local workflow_json="$1"
  local include_logs="$2"
  local tmp_file

  tmp_file="$(mktemp)"

  echo "$workflow_json" | jq -c '.workflow_runs[] | select(.conclusion == "failure")' | while read -r run_json; do
    local run_id workflow_name jobs_url jobs_json
    run_id="$(echo "$run_json" | jq -r '.id')"
    workflow_name="$(echo "$run_json" | jq -r '.name')"
    jobs_url="$(echo "$run_json" | jq -r '.jobs_url')"
    jobs_json="$(gh api "$jobs_url")"

    echo "$jobs_json" | jq -c '.jobs[] | select(.conclusion == "failure")' | while read -r job_json; do
      local job_id summary_json summary_lines item_json
      job_id="$(echo "$job_json" | jq -r '.id')"

      if [[ "$include_logs" -eq 1 ]]; then
        summary_lines="$(extract_log_summary_lines "$job_id")"
        if [[ -n "$summary_lines" ]]; then
          summary_json="$(printf '%s\n' "$summary_lines" | jq -R . | jq -s 'map(select(length > 0))')"
        else
          summary_json='[]'
        fi
      else
        summary_json='[]'
      fi

      item_json="$(jq -n \
        --arg workflow "$workflow_name" \
        --argjson runId "$run_id" \
        --argjson job "$job_json" \
        --argjson summary "$summary_json" \
        '{
          runId: $runId,
          workflow: $workflow,
          id: $job.id,
          name: $job.name,
          status: $job.status,
          conclusion: $job.conclusion,
          url: ($job.html_url // ""),
          summary: $summary
        }')"

      echo "$item_json" >> "$tmp_file"
    done
  done

  json_array_from_file "$tmp_file"
  rm -f "$tmp_file"
}

command_errors() {
  parse_pr_command_args "$@"
  require_gh_auth
  require_jq

  local head_sha check_runs_json workflow_json
  local failed_checks_file failed_checks_json failed_jobs_json

  head_sha="$(get_pr_head_sha)"
  check_runs_json="$(get_failed_checks_json "$head_sha")"
  workflow_json="$(gh api "repos/$GITHUB_PR_OWNER/$GITHUB_PR_REPO/actions/runs?head_sha=$head_sha&per_page=20")"
  failed_checks_file="$(mktemp)"

  echo "$check_runs_json" | jq -c '.check_runs[] | select(.conclusion == "failure")' | while read -r check_json; do
    local check_id annotations_json item_json
    check_id="$(echo "$check_json" | jq -r '.id')"
    annotations_json="$(get_check_annotations_json "$check_id")"

    item_json="$(jq -n \
      --argjson check "$check_json" \
      --argjson annotations "$annotations_json" \
      '{
        id: $check.id,
        name: ($check.name // "Unknown"),
        conclusion: ($check.conclusion // "unknown"),
        url: ($check.details_url // ""),
        annotations: [
          $annotations[]? | {
            level: .annotation_level,
            path: (.path // ""),
            line: (.start_line // 0),
            message: (.message // "")
          }
        ]
      }')"

    echo "$item_json" >> "$failed_checks_file"
  done

  failed_checks_json="$(json_array_from_file "$failed_checks_file")"
  rm -f "$failed_checks_file"
  failed_jobs_json="$(get_failed_jobs_json "$workflow_json" "$COMMAND_LOGS")"

  if [[ "$COMMAND_JSON" -eq 1 ]]; then
    jq -n \
      --arg owner "$GITHUB_PR_OWNER" \
      --arg repo "$GITHUB_PR_REPO" \
      --argjson number "$GITHUB_PR_NUMBER" \
      --arg headSha "$head_sha" \
      --argjson failedChecks "$failed_checks_json" \
      --argjson failedJobs "$failed_jobs_json" \
      '{
        owner: $owner,
        repo: $repo,
        number: $number,
        headSha: $headSha,
        failedChecks: $failedChecks,
        failedJobs: $failedJobs
      }'
    return 0
  fi

  local failed_check_count failed_job_count
  failed_check_count="$(echo "$failed_checks_json" | jq 'length')"
  failed_job_count="$(echo "$failed_jobs_json" | jq 'length')"

  echo "PR: $(repo_ref)#$GITHUB_PR_NUMBER"
  echo "Head SHA: $head_sha"
  echo "Failed checks: $failed_check_count"
  echo "Failed jobs: $failed_job_count"

  if [[ "$failed_check_count" -eq 0 && "$failed_job_count" -eq 0 ]]; then
    echo "No failed CI/CD jobs found."
    return 0
  fi

  if [[ "$failed_check_count" -gt 0 ]]; then
    echo ""
    echo "Checks"
    echo "$failed_checks_json" | jq -r '.[] | "- \(.name) | \(.conclusion) | \(.url)"'
    echo "$failed_checks_json" | jq -r '.[] | .annotations[:5][]? | "  * [\(.level)] \(.path):\(.line) \(.message)"'
  fi

  if [[ "$failed_job_count" -gt 0 ]]; then
    echo ""
    echo "Jobs"
    echo "$failed_jobs_json" | jq -r '.[] | "- \(.workflow) / \(.name) | \(.conclusion) | \(.url)"'

    if [[ "$COMMAND_LOGS" -eq 1 ]]; then
      echo "$failed_jobs_json" | jq -r '.[] | .summary[]? | "  * " + .'
    fi
  fi
}

command_mine() {
  require_gh_auth
  require_jq

  local state="open"
  local json=0

  while (($# > 0)); do
    case "$1" in
      open|closed|merged|all)
        state="$1"
        ;;
      --json)
        json=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Unexpected argument: $1"
        ;;
    esac
    shift
  done

  local states result_json
  case "$state" in
    open)
      states='[OPEN]'
      ;;
    closed)
      states='[CLOSED]'
      ;;
    merged)
      states='[MERGED]'
      ;;
    all)
      states='[OPEN, CLOSED, MERGED]'
      ;;
  esac

  result_json="$(gh api graphql --field query="
{
  viewer {
    pullRequests(first: 20, states: $states, orderBy: {field: UPDATED_AT, direction: DESC}) {
      nodes {
        title
        url
        state
        isDraft
        createdAt
        updatedAt
        repository {
          name
          owner {
            login
          }
        }
      }
    }
  }
}")"

  if [[ "$json" -eq 1 ]]; then
    echo "$result_json" | jq --arg state "$state" '{
      state: $state,
      prs: [
        .data.viewer.pullRequests.nodes[] | {
          owner: .repository.owner.login,
          repo: .repository.name,
          title,
          url,
          state,
          draft: .isDraft,
          createdAt,
          updatedAt
        }
      ]
    }'
    return 0
  fi

  local total
  total="$(echo "$result_json" | jq '.data.viewer.pullRequests.nodes | length')"

  echo "Your PRs: $state"
  echo "Total: $total"
  echo "$result_json" | jq -r '.data.viewer.pullRequests.nodes[] |
    "- \(.repository.owner.login)/\(.repository.name) | " +
    (if .isDraft then "[DRAFT] " else "" end) +
    "\(.title) | \(.state) | \(.updatedAt[0:10]) | \(.url)"'
}

main() {
  local command="${1:-}"

  if [[ -z "$command" ]]; then
    usage
    exit 1
  fi

  shift || true

  case "$command" in
    info)
      command_info "$@"
      ;;
    cicd)
      command_cicd "$@"
      ;;
    files)
      command_files "$@"
      ;;
    errors)
      command_errors "$@"
      ;;
    mine)
      command_mine "$@"
      ;;
    -h|--help)
      usage
      ;;
    *)
      fail "Unknown command: $command"
      ;;
  esac
}

main "$@"
