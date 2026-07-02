#!/usr/bin/env bash
# Mark ShikshaPortal issues as Done on GitHub Project #2 (kanha55).
# Auth: GITHUB_TOKEN (with project scopes) or `gh auth login` / `gh auth refresh`.

set -euo pipefail

OWNER="kanha55"
PROJECT_NUM=2
REPO="${GITHUB_REPOSITORY:-kanha55/shikshaportal}"

# Issues to mark Done (merged tasks)
DONE_ISSUES=(1 2 3 4 5 6 7 8 9 10 11 14 15 17 18 19 20)

need_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
  fi
}

check_gh_auth() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is required. Install with: brew install gh"
    exit 1
  fi

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "Using GITHUB_TOKEN for authentication."
    export GH_TOKEN="$GITHUB_TOKEN"
    return 0
  fi

  echo "Using gh CLI authentication (no GITHUB_TOKEN set)."
  if ! gh auth status >/dev/null 2>&1; then
    echo "Not logged in to gh. Run:"
    echo "  gh auth login -h github.com -s read:project,project"
    exit 1
  fi
}

check_project_scopes() {
  local auth_output
  auth_output=$(gh auth status 2>&1 || true)

  if echo "$auth_output" | grep -qE 'read:project|project'; then
    return 0
  fi

  echo "Missing GitHub project scopes."
  echo ""
  echo "If using gh auth, run:"
  echo "  gh auth refresh -h github.com -s read:project,project"
  echo ""
  echo "If using GITHUB_TOKEN, create a PAT with read:project and project scopes, then:"
  echo "  export GITHUB_TOKEN=ghp_..."
  echo "  ./scripts/update-project-board-done.sh"
  exit 1
}

main() {
  need_jq
  check_gh_auth
  check_project_scopes

  echo "Fetching project metadata (owner=$OWNER, project #$PROJECT_NUM)..."
  local project_id fields_json status_field_id done_option_id items_json
  project_id=$(gh project view "$PROJECT_NUM" --owner "$OWNER" --format json --jq '.id')
  echo "Project ID: $project_id"

  fields_json=$(gh project field-list "$PROJECT_NUM" --owner "$OWNER" --format json)
  status_field_id=$(echo "$fields_json" | jq -r '.fields[] | select(.name == "Status") | .id')
  done_option_id=$(echo "$fields_json" | jq -r '.fields[] | select(.name == "Status") | .options[] | select(.name == "Done") | .id')

  if [[ -z "$status_field_id" || "$status_field_id" == "null" ]]; then
    echo "Could not find Status field. Available fields:"
    echo "$fields_json" | jq -r '.fields[].name'
    exit 1
  fi

  if [[ -z "$done_option_id" || "$done_option_id" == "null" ]]; then
    echo "Could not find Done option. Status options:"
    echo "$fields_json" | jq -r '.fields[] | select(.name == "Status") | .options[].name'
    exit 1
  fi

  echo "Status field: $status_field_id | Done option: $done_option_id"
  echo "Fetching project items..."
  items_json=$(gh project item-list "$PROJECT_NUM" --owner "$OWNER" --format json --limit 100)

  local updated=0 skipped=0
  local -a not_found=()

  for issue in "${DONE_ISSUES[@]}"; do
    local item_id current
    item_id=$(echo "$items_json" | jq -r --argjson n "$issue" \
      '.items[] | select(.content.type == "Issue" and .content.number == $n) | .id' | head -1)

    if [[ -z "$item_id" || "$item_id" == "null" ]]; then
      not_found+=("$issue")
      continue
    fi

    current=$(echo "$items_json" | jq -r --arg id "$item_id" \
      '.items[] | select(.id == $id) | .status // .fieldValues[]? | select(.name? == "Status") | .name // empty' 2>/dev/null || true)

    if [[ "$current" == "Done" ]]; then
      echo "  #${issue}: already Done — skip"
      ((skipped++)) || true
      continue
    fi

    echo "  #${issue}: setting Done (item $item_id)"
    gh project item-edit \
      --id "$item_id" \
      --project-id "$project_id" \
      --field-id "$status_field_id" \
      --single-select-option-id "$done_option_id"
    ((updated++)) || true
  done

  echo ""
  echo "=== Summary ==="
  echo "Repo:            $REPO"
  echo "Updated to Done: $updated"
  echo "Already Done:    $skipped"
  if [[ ${#not_found[@]} -gt 0 ]]; then
    echo "Not on board:    ${not_found[*]}"
  fi
}

main "$@"
