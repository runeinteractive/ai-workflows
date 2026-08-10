#!/usr/bin/env bash
# Install ai-workflows for Cursor (user home) or into a project.
#
# Usage:
#   ./scripts/install.sh user [cursor|all]
#   ./scripts/install.sh project /path/to/project [cursor|claude|chatgpt|all]
set -euo pipefail

SCOPE="${1:-user}"
PACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACK_SKILLS="$PACK_ROOT/adapters/cursor/skills"

workflow_names() {
  local d
  for d in "$PACK_SKILLS"/*/; do
    [[ -d "$d" ]] || continue
    basename "$d"
  done | sort
}

assert_prompt_parity() {
  local name
  while IFS= read -r name; do
    if [[ ! -f "$PACK_ROOT/prompts/$name.md" ]]; then
      echo "Skill '$name' has no matching prompts/$name.md" >&2
      exit 1
    fi
  done < <(workflow_names)
}

install_cursor_user() {
  local skills_root="${HOME}/.cursor/skills"
  local rules_root="${HOME}/.cursor/rules"
  mkdir -p "$skills_root" "$rules_root"

  local name src dest
  while IFS= read -r name; do
    src="$PACK_SKILLS/$name/SKILL.md"
    [[ -f "$src" ]] || continue
    dest="$skills_root/$name"
    mkdir -p "$dest"
    sed "s|../../../../prompts/|${PACK_ROOT}/prompts/|g" "$src" > "$dest/SKILL.md"
  done < <(workflow_names)

  cat > "$rules_root/engineering.mdc" <<EOF
---
description: Core engineering standards for AI assistants
alwaysApply: true
---

Read and apply \`${PACK_ROOT}/rules/engineering.md\` for the whole session,
including the daily workflow loop. Prefer \`${PACK_ROOT}/prompts/\` for structured tasks.
EOF

  echo "Cursor (user): skills -> $skills_root"
  echo "Cursor (user): rule  -> $rules_root/engineering.mdc"
  echo "Prompts stay in pack: $PACK_ROOT/prompts/"
}

copy_pack() {
  local project_root="$1"
  local vendor="$project_root/.ai-workflows"
  mkdir -p "$vendor/prompts" "$vendor/rules"
  cp -f "$PACK_ROOT"/prompts/*.md "$vendor/prompts/"
  cp -f "$PACK_ROOT"/rules/*.md "$vendor/rules/"
  cp -f "$PACK_ROOT/LICENSE" "$vendor/LICENSE"
  local names adapter
  names="$(workflow_names | paste -sd ', ' - 2>/dev/null || workflow_names | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
  adapter="$2"
  cat > "$vendor/README.md" <<EOF
# ai-workflows

Vendored install from \`$PACK_ROOT\`.
Installed: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Adapter request: $adapter
Workflows: $names

Re-run the install script to refresh prompts and rules.
See LICENSE in this folder.
EOF
}

install_cursor_project() {
  local project_root="$1"
  local skills_root="$project_root/.cursor/skills"
  local rules_root="$project_root/.cursor/rules"
  mkdir -p "$skills_root" "$rules_root"

  local name src dest
  while IFS= read -r name; do
    src="$PACK_SKILLS/$name/SKILL.md"
    [[ -f "$src" ]] || continue
    dest="$skills_root/$name"
    mkdir -p "$dest"
    sed 's|\.\./\.\./\.\./\.\./prompts/|../../../.ai-workflows/prompts/|g' "$src" > "$dest/SKILL.md"
  done < <(workflow_names)

  cat > "$rules_root/engineering.mdc" <<'EOF'
---
description: Core engineering standards for AI assistants
alwaysApply: true
---

Read and apply `.ai-workflows/rules/engineering.md` for the whole session,
including the daily workflow loop. Prefer `.ai-workflows/prompts/` for structured tasks.
EOF

  echo "Cursor (project): skills -> .cursor/skills/, rule -> .cursor/rules/engineering.mdc"
}

install_claude_project() {
  local project_root="$1"
  {
    echo '## AI workflows'
    echo
    echo 'Always apply `.ai-workflows/rules/engineering.md` (including the daily loop).'
    echo
    echo 'When the user asks for a structured task, read and follow the matching prompt:'
    echo
    echo '| Workflow | File |'
    echo '| -------- | ---- |'
    while IFS= read -r name; do
      echo "| $name | \`.ai-workflows/prompts/$name.md\` |"
    done < <(workflow_names)
    echo
    echo 'Do not invent a parallel process. Chain workflows when asked (e.g. commit and open a PR).'
  } > "$project_root/CLAUDE.ai-workflows.md"
  echo "Claude: wrote CLAUDE.ai-workflows.md - merge into CLAUDE.md"
}

install_chatgpt_project() {
  local project_root="$1"
  local list
  list="$(workflow_names | paste -sd ', ' - 2>/dev/null || workflow_names | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
  cat > "$project_root/CHATGPT.ai-workflows.md" <<EOF
Follow .ai-workflows/rules/engineering.md on every task (including the daily loop).

For structured work, open the matching file under .ai-workflows/prompts/: $list.

Ask which workflow if unclear. Do not invent a parallel process.
EOF
  echo "ChatGPT: wrote CHATGPT.ai-workflows.md - paste into project instructions"
}

assert_prompt_parity

echo "Pack:  $PACK_ROOT"
echo "Scope: $SCOPE"

case "$SCOPE" in
  user)
    ADAPTER="${2:-cursor}"
    echo "Adapter: $ADAPTER"
    case "$ADAPTER" in
      cursor|all) ;;
      *)
        echo "Scope 'user' only supports Cursor. Use: $0 user cursor" >&2
        exit 1
        ;;
    esac
    if [[ "$ADAPTER" == "all" ]]; then
      echo "Note: user scope installs Cursor only (claude/chatgpt are project-oriented)."
    fi
    install_cursor_user
    echo "Done. Restart Cursor (or open a new window) so user skills/rules load."
    ;;
  project)
    PROJECT="${2:-}"
    ADAPTER="${3:-cursor}"
    if [[ -z "$PROJECT" ]]; then
      echo "Usage: $0 project /path/to/project [cursor|claude|chatgpt|all]" >&2
      exit 1
    fi
    case "$ADAPTER" in
      cursor|claude|chatgpt|all) ;;
      *)
        echo "Adapter must be cursor, claude, chatgpt, or all" >&2
        exit 1
        ;;
    esac
    PROJECT_ROOT="$(cd "$PROJECT" && pwd)"
    echo "Project: $PROJECT_ROOT"
    echo "Adapter: $ADAPTER"
    copy_pack "$PROJECT_ROOT" "$ADAPTER"
    echo "Vendored prompts/rules/LICENSE -> .ai-workflows/"
    case "$ADAPTER" in
      cursor) install_cursor_project "$PROJECT_ROOT" ;;
      claude) install_claude_project "$PROJECT_ROOT" ;;
      chatgpt) install_chatgpt_project "$PROJECT_ROOT" ;;
      all)
        install_cursor_project "$PROJECT_ROOT"
        install_claude_project "$PROJECT_ROOT"
        install_chatgpt_project "$PROJECT_ROOT"
        ;;
    esac
    echo "Done."
    ;;
  *)
    echo "Usage:" >&2
    echo "  $0 user [cursor|all]" >&2
    echo "  $0 project /path/to/project [cursor|claude|chatgpt|all]" >&2
    exit 1
    ;;
esac
