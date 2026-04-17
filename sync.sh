#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# sync.sh - Synchronize agents from canonical source to
#           Claude Code, Cursor, and Codex
# ─────────────────────────────────────────────────────────────

AGENTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$AGENTS_DIR/agents"
INCLUDES_DIR="$AGENTS_DIR/includes"
DIST_DIR="$AGENTS_DIR/dist"

# Target directories
CLAUDE_DIR="$HOME/.claude/commands"
CURSOR_DIR="$HOME/.cursor/rules"
CODEX_DIR="$HOME/.codex/skills"
DIST_CLAUDE_DIR="$DIST_DIR/claude"
DIST_CURSOR_DIR="$DIST_DIR/cursor"
DIST_CODEX_DIR="$DIST_DIR/codex"
MANIFEST_FILE="$AGENTS_DIR/.installed-agents"
INSTALL_TARGETS=true
CLEAN_ONLY=false
CLEAN_ALL=false

PREFIX="kp"  # Prefix for generated commands (kp-brainstorm, kp-product...)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${BLUE}[sync]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }

yaml_quote() {
    local value="${1//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    printf '"%s"' "$value"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dist-only)
                INSTALL_TARGETS=false
                ;;
            --clean)
                CLEAN_ONLY=true
                ;;
            --clean-all)
                CLEAN_ONLY=true
                CLEAN_ALL=true
                ;;
            -h|--help)
                cat <<'HELP_EOF'
Usage: ./sync.sh [--dist-only] [--clean | --clean-all]

Options:
  --dist-only   Generate artefacts only in ./dist without installing to ~/.claude, ~/.cursor, ~/.codex
  --clean       Remove previously installed agents (based on manifest) and exit without syncing
  --clean-all   Remove ALL kp-* skills via glob (ignores manifest), then exit without syncing
HELP_EOF
                exit 0
                ;;
            *)
                err "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# ─────────────────────────────────────────────────────────────
# Parse frontmatter from a canonical agent file
# Returns: name, description (as global vars)
# ─────────────────────────────────────────────────────────────
parse_frontmatter() {
    local file="$1"
    AGENT_NAME=""
    AGENT_DESC=""
    AGENT_SHORT_DESC=""
    AGENT_DEFAULT_PROMPT=""

    local in_frontmatter=false
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break
            else
                in_frontmatter=true
                continue
            fi
        fi
        if $in_frontmatter; then
            if [[ "$line" =~ ^name:\ *(.+)$ ]]; then
                AGENT_NAME="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^description:\ *[\"\']*(.+)[\"\']*$ ]]; then
                AGENT_DESC="${BASH_REMATCH[1]}"
                AGENT_DESC="${AGENT_DESC%\"}"
                AGENT_DESC="${AGENT_DESC%\'}"
            elif [[ "$line" =~ ^short_description:\ *[\"\']*(.+)[\"\']*$ ]]; then
                AGENT_SHORT_DESC="${BASH_REMATCH[1]}"
                AGENT_SHORT_DESC="${AGENT_SHORT_DESC%\"}"
                AGENT_SHORT_DESC="${AGENT_SHORT_DESC%\'}"
            elif [[ "$line" =~ ^default_prompt:\ *[\"\']*(.+)[\"\']*$ ]]; then
                AGENT_DEFAULT_PROMPT="${BASH_REMATCH[1]}"
                AGENT_DEFAULT_PROMPT="${AGENT_DEFAULT_PROMPT%\"}"
                AGENT_DEFAULT_PROMPT="${AGENT_DEFAULT_PROMPT%\'}"
            fi
        fi
    done < "$file"
}

# ─────────────────────────────────────────────────────────────
# Extract body (everything after frontmatter)
# ─────────────────────────────────────────────────────────────
extract_body() {
    local file="$1"
    local past_frontmatter=false
    local frontmatter_count=0

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            frontmatter_count=$((frontmatter_count + 1))
            if [[ $frontmatter_count -eq 2 ]]; then
                past_frontmatter=true
                continue
            fi
            continue
        fi
        if $past_frontmatter; then
            echo "$line"
        fi
    done < "$file"
}

# ─────────────────────────────────────────────────────────────
# Resolve {{include:filename}} directives
# ─────────────────────────────────────────────────────────────
resolve_includes() {
    local content="$1"

    while [[ "$content" =~ \{\{include:([a-zA-Z0-9_-]+)\}\} ]]; do
        local include_name="${BASH_REMATCH[1]}"
        local include_file="$INCLUDES_DIR/${include_name}.md"

        if [[ -f "$include_file" ]]; then
            local include_content
            include_content=$(<"$include_file")
            content="${content//\{\{include:$include_name\}\}/$include_content}"
        else
            warn "Include not found: $include_file"
            content="${content//\{\{include:$include_name\}\}/}"
        fi
    done

    echo "$content"
}

# ─────────────────────────────────────────────────────────────
# Generate for Claude Code (~/.claude/commands/)
# Format: .md with YAML frontmatter (description)
# ─────────────────────────────────────────────────────────────
generate_claude_file() {
    local outfile="$1" desc="$2" body="$3"

    cat > "$outfile" <<CLAUDE_EOF
---
description: $(yaml_quote "$desc")
---
${body}
CLAUDE_EOF
}

generate_claude() {
    local name="$1" desc="$2" body="$3"
    local dist_outfile="$DIST_CLAUDE_DIR/${PREFIX}-${name}.md"
    local install_outfile="$CLAUDE_DIR/${PREFIX}-${name}.md"

    generate_claude_file "$dist_outfile" "$desc" "$body"
    if $INSTALL_TARGETS; then
        cp "$dist_outfile" "$install_outfile"
    fi
    ok "Claude  → /$(basename "$install_outfile" .md)"
}

# ─────────────────────────────────────────────────────────────
# Generate for Cursor (~/.cursor/rules/)
# Format: .mdc with YAML frontmatter
# ─────────────────────────────────────────────────────────────
generate_cursor_file() {
    local outfile="$1" desc="$2" body="$3"

    cat > "$outfile" <<CURSOR_EOF
---
description: $(yaml_quote "$desc")
alwaysApply: false
---
${body}
CURSOR_EOF
}

generate_cursor() {
    local name="$1" desc="$2" body="$3"
    local dist_outfile="$DIST_CURSOR_DIR/${PREFIX}-${name}.mdc"
    local install_outfile="$CURSOR_DIR/${PREFIX}-${name}.mdc"

    generate_cursor_file "$dist_outfile" "$desc" "$body"
    if $INSTALL_TARGETS; then
        cp "$dist_outfile" "$install_outfile"
    fi
    ok "Cursor  → ${PREFIX}-${name}.mdc"
}

# ─────────────────────────────────────────────────────────────
# Generate for Codex (~/.codex/skills/)
# Format: skill folder with SKILL.md + agents/openai.yaml
# ─────────────────────────────────────────────────────────────
generate_codex_skill() {
    local skill_dir="$1" name="$2" desc="$3" body="$4" short_desc="$5" default_prompt="$6"
    local skill_agents_dir="$skill_dir/agents"

    [[ -z "$short_desc" ]] && short_desc="$desc"

    local display_name
    display_name="KeyProd $(echo "${name:0:1}" | tr '[:lower:]' '[:upper:]')${name:1}"

    mkdir -p "$skill_agents_dir"

    cat > "$skill_dir/SKILL.md" <<SKILL_EOF
---
name: $(yaml_quote "${PREFIX}-${name}")
description: $(yaml_quote "$desc")
metadata:
  short-description: $(yaml_quote "$short_desc")
---

${body}
SKILL_EOF

    {
        echo 'interface:'
        echo "  display_name: $(yaml_quote "$display_name")"
        echo "  short_description: $(yaml_quote "$short_desc")"
        if [[ -n "$default_prompt" ]]; then
            echo "  default_prompt: $(yaml_quote "$default_prompt")"
        fi
        echo 'policy:'
        echo '  allow_implicit_invocation: true'
    } > "$skill_agents_dir/openai.yaml"
}

generate_codex() {
    local name="$1" desc="$2" body="$3" short_desc="$4" default_prompt="$5"
    local dist_skill_dir="$DIST_CODEX_DIR/${PREFIX}-${name}"
    local install_skill_dir="$CODEX_DIR/${PREFIX}-${name}"

    rm -rf "$dist_skill_dir"
    generate_codex_skill "$dist_skill_dir" "$name" "$desc" "$body" "$short_desc" "$default_prompt"

    if $INSTALL_TARGETS; then
        rm -rf "$install_skill_dir"
        mkdir -p "$(dirname "$install_skill_dir")"
        cp -R "$dist_skill_dir" "$install_skill_dir"
    fi

    ok "Codex   → skill ${PREFIX}-${name}"
}

# ─────────────────────────────────────────────────────────────
# Remove a single agent's artefacts (dist + install targets)
# ─────────────────────────────────────────────────────────────
remove_agent() {
    local name="$1"
    rm -f "$DIST_CLAUDE_DIR/${PREFIX}-${name}.md"
    rm -f "$DIST_CURSOR_DIR/${PREFIX}-${name}.mdc"
    rm -rf "$DIST_CODEX_DIR/${PREFIX}-${name}"
    if $INSTALL_TARGETS; then
        rm -f "$CLAUDE_DIR/${PREFIX}-${name}.md"
        rm -f "$CURSOR_DIR/${PREFIX}-${name}.mdc"
        rm -rf "$CODEX_DIR/${PREFIX}-${name}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Clean previously installed agents using the manifest.
# Falls back to kp-* glob if manifest is missing.
# ─────────────────────────────────────────────────────────────
glob_clean() {
    rm -f "$DIST_CLAUDE_DIR"/${PREFIX}-*.md 2>/dev/null || true
    rm -f "$DIST_CURSOR_DIR"/${PREFIX}-*.mdc 2>/dev/null || true
    rm -rf "$DIST_CODEX_DIR"/${PREFIX}-*/ 2>/dev/null || true
    if $INSTALL_TARGETS; then
        rm -f "$CLAUDE_DIR"/${PREFIX}-*.md 2>/dev/null || true
        rm -f "$CURSOR_DIR"/${PREFIX}-*.mdc 2>/dev/null || true
        rm -rf "$CODEX_DIR"/${PREFIX}-*/ 2>/dev/null || true
    fi
}

clean() {
    if $CLEAN_ALL; then
        log "Force cleaning ALL ${PREFIX}-* skills via glob..."
        glob_clean
        ok "All ${PREFIX}-* skills removed"
        return
    fi

    local previous=()
    if [[ -f "$MANIFEST_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && previous+=("$line")
        done < "$MANIFEST_FILE"
    fi

    if [[ ${#previous[@]} -gt 0 ]]; then
        log "Cleaning ${#previous[@]} previously installed agent(s) from manifest..."
        for name in "${previous[@]}"; do
            remove_agent "$name"
            ok "Removed: ${PREFIX}-${name}"
        done
    else
        log "No manifest found — fallback glob clean on ${PREFIX}-*"
        glob_clean
    fi
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    echo ""
    echo -e "${BLUE}━━━ kp-agents sync ━━━${NC}"
    echo ""

    # Ensure target dirs exist
    mkdir -p "$DIST_CLAUDE_DIR" "$DIST_CURSOR_DIR" "$DIST_CODEX_DIR"
    if $INSTALL_TARGETS; then
        mkdir -p "$CLAUDE_DIR" "$CURSOR_DIR" "$CODEX_DIR"
    fi

    # Clean previously installed agents (from manifest)
    clean
    echo ""

    if $CLEAN_ONLY; then
        rm -f "$MANIFEST_FILE"
        echo -e "${GREEN}━━━ Clean complete ━━━${NC}"
        echo ""
        return
    fi

    # Process each agent, collecting names for the new manifest
    local count=0
    local synced_names=()
    for agent_file in "$SOURCE_DIR"/*.md; do
        [[ -f "$agent_file" ]] || continue

        parse_frontmatter "$agent_file"

        if [[ -z "$AGENT_NAME" ]]; then
            warn "Skipping $(basename "$agent_file"): no name in frontmatter"
            continue
        fi

        log "Processing: ${AGENT_NAME}"

        # Extract body and resolve includes
        local body
        body=$(extract_body "$agent_file")
        body=$(resolve_includes "$body")

        # Generate for each tool
        generate_claude "$AGENT_NAME" "$AGENT_DESC" "$body"
        generate_cursor "$AGENT_NAME" "$AGENT_DESC" "$body"
        generate_codex  "$AGENT_NAME" "$AGENT_DESC" "$body" "$AGENT_SHORT_DESC" "$AGENT_DEFAULT_PROMPT"

        synced_names+=("$AGENT_NAME")
        count=$((count + 1))
        echo ""
    done

    # Write the new manifest so next run can clean surgically
    if [[ ${#synced_names[@]} -gt 0 ]]; then
        printf '%s\n' "${synced_names[@]}" > "$MANIFEST_FILE"
    else
        rm -f "$MANIFEST_FILE"
    fi

    echo -e "${GREEN}━━━ Done: ${count} agents synced to 3 tools ━━━${NC}"
    echo ""
    echo "Usage:"
    echo "  Claude Code : /kp-brainstorm, /kp-product, /kp-architect, /kp-developer"
    echo "  Cursor      : @kp-brainstorm (via rules picker)"
    echo "  Codex       : skills auto-détectées (kp-brainstorm, kp-product...)"
    echo "  Dist        : artefacts générés dans ./dist/{claude,cursor,codex}"
    if ! $INSTALL_TARGETS; then
        echo "  Install     : désactivée (--dist-only)"
    fi
    echo ""
    echo "Note Codex:"
    echo "  Redémarre Codex après sync pour recharger les skills KeyProd."
    echo ""
}

main "$@"
