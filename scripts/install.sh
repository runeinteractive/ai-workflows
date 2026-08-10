#!/usr/bin/env bash
# Install ai-workflows into a project (prompts + rules + optional adapters).
# Usage: ./scripts/install.sh /path/to/project [cursor|claude|chatgpt|all]
set -euo pipefail

PROJECT="${1:-}"
ADAPTER="${2:-cursor}"

if [[ -z "$PROJECT" ]]; then
  echo "Usage: $0 /path/to/project [cursor|claude|chatgpt|all]" >&2
  exit 1
fi

case "$ADAPTER" in
  cursor|claude|chatgpt|all) ;;
  *)
    echo "Adapter must be cursor, claude, chatgpt, or all" >&2
    exit 1
    ;;
esac

PACK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_ROOT="$(cd "$PROJECT" && pwd)"
VENDOR="$PROJECT_ROOT/.ai-workflows"
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

copy_pack() {
  mkdir -p "$VENDOR/prompts" "$VENDOR/rules"
  cp -f "$PACK_ROOT"/prompts/*.md "$VENDOR/prompts/"
  cp -f "$PACK_ROOT"/rules/*.md "$VENDOR/rules/"
  cp -f "$PACK_ROOT/LICENSE" "$VENDOR/LICENSE"
  local names
  names="$(workflow_names | paste -sd ', ' - 2>/dev/null || workflow_names | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
  cat > "$VENDOR/README.md" <<EOF
# ai-workflows

Vendored install from \`$PACK_ROOT\`.
Installed: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Adapter request: $ADAPTER
Workflows: $names

Re-run the install script to refresh prompts and rules.
See LICENSE in this folder.
EOF
}

install_cursor() {
  local skills_root="$PROJECT_ROOT/.cursor/skills"
  local rules_root="$PROJECT_ROOT/.cursor/rules"
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

  echo "Cursor: skills -> .cursor/skills/, rule -> .cursor/rules/engineering.mdc"
}

install_claude() {
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
  } > "$PROJECT_ROOT/CLAUDE.ai-workflows.md"
  echo "Claude: wrote CLAUDE.ai-workflows.md - merge into CLAUDE.md"
}

install_chatgpt() {
  local list
  list="$(workflow_names | paste -sd ', ' - 2>/dev/null || workflow_names | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')"
  cat > "$PROJECT_ROOT/CHATGPT.ai-workflows.md" <<EOF
Follow .ai-workflows/rules/engineering.md on every task (including the daily loop).

For structured work, open the matching file under .ai-workflows/prompts/: $list.

Ask which workflow if unclear. Do not invent a parallel process.
EOF
  echo "ChatGPT: wrote CHATGPT.ai-workflows.md - paste into project instructions"
}

echo "Pack:    $PACK_ROOT"
echo "Project: $PROJECT_ROOT"
echo "Adapter: $ADAPTER"

assert_prompt_parity
copy_pack
echo "Vendored prompts/rules/LICENSE -> .ai-workflows/"

case "$ADAPTER" in
  cursor) install_cursor ;;
  claude) install_claude ;;
  chatgpt) install_chatgpt ;;
  all)
    install_cursor
    install_claude
    install_chatgpt
    ;;
esac

echo "Done."
