#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# sync.sh - Synchronize agents from canonical source to
#           Claude Code plugin (kp-agents), Cursor, and Codex
#
# The Claude Code plugin is generated into ./plugins/kp-agents/
# and committed to git. Users install it via:
#   /plugin marketplace add KeyProd/kp-agents
#   /plugin install kp-agents@kp-agents
#
# Cursor and Codex keep the local install model via this script.
# ─────────────────────────────────────────────────────────────

AGENTS_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$AGENTS_DIR/agents"
INCLUDES_DIR="$AGENTS_DIR/includes"
DIST_DIR="$AGENTS_DIR/dist"

# Target directories
CURSOR_DIR="$HOME/.cursor/rules"
CODEX_DIR="$HOME/.codex/skills"
DIST_CURSOR_DIR="$DIST_DIR/cursor"
DIST_CODEX_DIR="$DIST_DIR/codex"

# Claude plugin target (committed to git, not installed locally)
PLUGIN_DIR="$AGENTS_DIR/plugins/kp-agents"
PLUGIN_SKILLS_DIR="$PLUGIN_DIR/skills"

MANIFEST_FILE="$AGENTS_DIR/.installed-agents"
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
INSTALL_TARGETS=true
CLEAN_ONLY=false
CLEAN_ALL=false
BUMP_MINOR=false
BUMP_MAJOR=false

PREFIX="kp"  # Prefix for Cursor/Codex artefacts (kp-brainstorm, kp-product...)

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
            --minor)
                BUMP_MINOR=true
                ;;
            --major)
                BUMP_MAJOR=true
                ;;
            -h|--help)
                cat <<'HELP_EOF'
Usage: ./sync.sh [--dist-only] [--clean | --clean-all] [--minor | --major]

Generates the Claude Code plugin (plugins/kp-agents/) from agents/*.md,
and installs Cursor rules + Codex skills locally.

Options:
  --dist-only   Generate artefacts only in ./plugins and ./dist without
                installing to ~/.cursor and ~/.codex
  --clean       Remove previously installed Cursor/Codex agents (based on manifest)
                and strip their skill folders from plugins/kp-agents/, then exit
  --clean-all   Remove ALL kp-* Cursor/Codex artefacts via glob (ignores manifest)
                and clear plugins/kp-agents/skills/, then exit
  --minor       Force a minor version bump (X.Y.Z → X.(Y+1).0). Use when
                adding a new agent or adding a significant feature.
                Mutually exclusive with --major. Cannot be combined with --clean.
  --major       Force a major version bump (X.Y.Z → (X+1).0.0). Use for
                breaking changes (e.g. removing an agent, namespace rename).
                Mutually exclusive with --minor. Cannot be combined with --clean.

Notes:
  - The Claude plugin in plugins/kp-agents/ is versioned in git and distributed
    via the marketplace (.claude-plugin/marketplace.json). This script does NOT
    install anything to ~/.claude/commands/.
  - Without --minor/--major, sync.sh auto-bumps the patch version if skill
    content has changed (SHA256 stored in plugin.json as _contentHash).
  - A manual edit of "version" in plugin.json is respected — sync.sh never
    overwrites a manual bump (detection via _lastAutoVersion field).
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

    # Validation des flags mutuellement exclusifs
    if $BUMP_MINOR && $BUMP_MAJOR; then
        err "--minor and --major are mutually exclusive, choose only one"
        exit 1
    fi

    # Validation des flags incompatibles avec --clean / --clean-all
    if ($BUMP_MINOR || $BUMP_MAJOR) && $CLEAN_ONLY; then
        err "--minor / --major cannot be combined with --clean / --clean-all"
        exit 1
    fi
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
# Generate Claude Code plugin skill (plugins/kp-agents/skills/<name>/SKILL.md)
# Format: minimal YAML frontmatter (description only) + body
# Committed to git, distributed via plugin marketplace.
# ─────────────────────────────────────────────────────────────
generate_plugin_file() {
    local outfile="$1" desc="$2" body="$3"

    cat > "$outfile" <<PLUGIN_EOF
---
description: $(yaml_quote "$desc")
---

${body}
PLUGIN_EOF
}

generate_plugin() {
    local name="$1" desc="$2" body="$3"
    local skill_dir="$PLUGIN_SKILLS_DIR/${name}"
    local outfile="$skill_dir/SKILL.md"

    mkdir -p "$skill_dir"
    generate_plugin_file "$outfile" "$desc" "$body"
    ok "Plugin  → plugins/kp-agents/skills/${name}/SKILL.md"
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
# One-shot cleanup of legacy Claude local install
# Removes dist/claude/ and ~/.claude/commands/kp-*.md from previous versions
# of sync.sh. Claude is now distributed via the plugin marketplace.
# ─────────────────────────────────────────────────────────────
cleanup_legacy_claude() {
    local changed=false

    if [[ -d "$DIST_DIR/claude" ]]; then
        rm -rf "$DIST_DIR/claude"
        log "Removed legacy dist/claude/ (Claude now distributed via plugin marketplace)"
        changed=true
    fi

    if $INSTALL_TARGETS; then
        local legacy_claude="$HOME/.claude/commands"
        if [[ -d "$legacy_claude" ]]; then
            local found
            found=$(find "$legacy_claude" -maxdepth 1 -name "${PREFIX}-*.md" 2>/dev/null | head -1)
            if [[ -n "$found" ]]; then
                rm -f "$legacy_claude"/${PREFIX}-*.md 2>/dev/null || true
                log "Removed legacy ${PREFIX}-*.md from ~/.claude/commands/ (use plugin marketplace instead)"
                changed=true
            fi
        fi
    fi

    if $changed; then
        echo ""
    fi
}

# ─────────────────────────────────────────────────────────────
# Remove a single agent's artefacts (plugin skill + Cursor/Codex dist and installs)
# ─────────────────────────────────────────────────────────────
remove_agent() {
    local name="$1"
    # Plugin skill (committed to git, removed here because the agent no longer exists)
    rm -rf "$PLUGIN_SKILLS_DIR/${name}"
    # Cursor dist + install
    rm -f "$DIST_CURSOR_DIR/${PREFIX}-${name}.mdc"
    # Codex dist + install
    rm -rf "$DIST_CODEX_DIR/${PREFIX}-${name}"
    if $INSTALL_TARGETS; then
        rm -f "$CURSOR_DIR/${PREFIX}-${name}.mdc"
        rm -rf "$CODEX_DIR/${PREFIX}-${name}"
    fi
}

# ─────────────────────────────────────────────────────────────
# Clean previously installed agents using the manifest.
# Falls back to kp-* glob if manifest is missing.
# ─────────────────────────────────────────────────────────────
glob_clean() {
    # Plugin skills (but NOT .claude-plugin/plugin.json which is static)
    rm -rf "$PLUGIN_SKILLS_DIR"/*/ 2>/dev/null || true
    # Cursor & Codex dist
    rm -f "$DIST_CURSOR_DIR"/${PREFIX}-*.mdc 2>/dev/null || true
    rm -rf "$DIST_CODEX_DIR"/${PREFIX}-*/ 2>/dev/null || true
    if $INSTALL_TARGETS; then
        rm -f "$CURSOR_DIR"/${PREFIX}-*.mdc 2>/dev/null || true
        rm -rf "$CODEX_DIR"/${PREFIX}-*/ 2>/dev/null || true
    fi
}

clean() {
    if $CLEAN_ALL; then
        log "Force cleaning ALL ${PREFIX}-* artefacts via glob..."
        glob_clean
        ok "All ${PREFIX}-* artefacts removed (plugin skills + Cursor + Codex)"
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
# Auto-bump de version du plugin kp-agents (E-0002 S-0001)
#
# Stockage : trois champs dans plugin.json
#   version          → version semver publique (lue par Claude Code client)
#   _contentHash     → SHA256 du contenu des skills générés, préfixé "sha256:"
#   _lastAutoVersion → valeur de version au dernier sync, sert à détecter
#                      un bump manuel effectué en dehors de ce script
# ─────────────────────────────────────────────────────────────

# Calcul d'un hash SHA256 stable sur plugins/kp-agents/skills/**/SKILL.md
# Fallback openssl si shasum indisponible. Renvoie "" si aucun outil.
compute_content_hash() {
    if command -v shasum >/dev/null 2>&1; then
        ( cd "$PLUGIN_DIR" && /usr/bin/find skills -type f -name "SKILL.md" | sort | xargs shasum -a 256 | shasum -a 256 | awk '{print $1}' )
    elif command -v openssl >/dev/null 2>&1; then
        ( cd "$PLUGIN_DIR" && /usr/bin/find skills -type f -name "SKILL.md" | sort | while IFS= read -r f; do
            echo "$(openssl dgst -sha256 "$f" | awk '{print $NF}')  $f"
          done | openssl dgst -sha256 | awk '{print $NF}' )
    else
        echo ""
    fi
}

# Lit un champ de premier niveau dans plugin.json (via python3, renvoie "" si absent)
# Le champ est passé en argv pour éviter l'interpolation shell.
read_plugin_json_field() {
    local field="$1"
    python3 - "$PLUGIN_JSON" "$field" <<'PYEOF'
import json, sys
path, field = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(path))
    print(d.get(field, ''))
except Exception:
    print('')
PYEOF
}

# Met à jour version / _contentHash / _lastAutoVersion dans plugin.json
# Préserve l'indentation (indent=2) et les autres champs en place.
update_plugin_json() {
    local new_version="$1" new_hash="$2" new_last_auto="$3"
    python3 - "$PLUGIN_JSON" "$new_version" "$new_hash" "$new_last_auto" <<'PYEOF'
import json, sys
path, new_version, new_hash, new_last_auto = sys.argv[1:5]
with open(path) as f:
    d = json.load(f)
d['version'] = new_version
d['_contentHash'] = new_hash
d['_lastAutoVersion'] = new_last_auto
with open(path, 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
PYEOF
}

# Incrémente un composant d'une version semver X.Y.Z
# Usage : bump_version "0.2.0" patch → 0.2.1
bump_version() {
    local current="$1" kind="$2"
    if ! [[ "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        err "Invalid version format in plugin.json: \"$current\" (expected X.Y.Z)"
        return 1
    fi
    local major="${BASH_REMATCH[1]}" minor="${BASH_REMATCH[2]}" patch="${BASH_REMATCH[3]}"
    case "$kind" in
        major) echo "$((major + 1)).0.0" ;;
        minor) echo "$major.$((minor + 1)).0" ;;
        patch) echo "$major.$minor.$((patch + 1))" ;;
        *) err "Invalid bump kind: $kind"; return 1 ;;
    esac
}

# Orchestration de l'auto-bump : lit plugin.json, compare au nouveau hash,
# et met à jour en fonction de 5 cas (init, bump manuel, flag minor/major,
# auto-patch, idempotence). Appelée depuis main() après génération des skills.
apply_version_logic() {
    local current_version current_hash last_auto new_hash
    current_version=$(read_plugin_json_field version)
    current_hash=$(read_plugin_json_field _contentHash)
    last_auto=$(read_plugin_json_field _lastAutoVersion)
    local computed; computed=$(compute_content_hash)

    # 0. Fallback : aucun outil de hash disponible
    if [[ -z "$computed" ]]; then
        warn "Hash calculation skipped (no SHA256 tool available) — version unchanged: $current_version"
        return 0
    fi
    new_hash="sha256:$computed"

    # 1. Initialisation au premier run (champs custom absents)
    if [[ -z "$current_hash" || -z "$last_auto" ]]; then
        update_plugin_json "$current_version" "$new_hash" "$current_version"
        log "Plugin content hash initialized: ${new_hash:0:19}... (version unchanged: $current_version)"
        return 0
    fi

    # 2. Bump manuel détecté : version a changé sans passer par ce script
    if [[ "$current_version" != "$last_auto" ]]; then
        update_plugin_json "$current_version" "$new_hash" "$current_version"
        log "Manual version bump detected ($last_auto → $current_version) — kept as-is, references updated"
        return 0
    fi

    # 3. Flag --minor explicite
    if $BUMP_MINOR; then
        local bumped; bumped=$(bump_version "$current_version" minor) || return 1
        update_plugin_json "$bumped" "$new_hash" "$bumped"
        ok "Plugin version bumped: $current_version → $bumped (minor, requested)"
        return 0
    fi

    # 4. Flag --major explicite
    if $BUMP_MAJOR; then
        local bumped; bumped=$(bump_version "$current_version" major) || return 1
        update_plugin_json "$bumped" "$new_hash" "$bumped"
        ok "Plugin version bumped: $current_version → $bumped (major, requested)"
        return 0
    fi

    # 5. Auto-bump patch si le hash a changé
    if [[ "$current_hash" != "$new_hash" ]]; then
        local bumped; bumped=$(bump_version "$current_version" patch) || return 1
        update_plugin_json "$bumped" "$new_hash" "$bumped"
        ok "Plugin version bumped: $current_version → $bumped (content changed)"
        return 0
    fi

    # 6. Idempotence : rien n'a changé
    log "Plugin version unchanged: $current_version (no content change)"
}

# ─────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    echo ""
    echo -e "${BLUE}━━━ kp-agents sync ━━━${NC}"
    echo ""

    # One-shot legacy cleanup (runs on every invocation, idempotent)
    cleanup_legacy_claude

    # Ensure target dirs exist
    mkdir -p "$DIST_CURSOR_DIR" "$DIST_CODEX_DIR" "$PLUGIN_SKILLS_DIR"
    if $INSTALL_TARGETS; then
        mkdir -p "$CURSOR_DIR" "$CODEX_DIR"
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
        generate_plugin "$AGENT_NAME" "$AGENT_DESC" "$body"
        generate_cursor "$AGENT_NAME" "$AGENT_DESC" "$body"
        generate_codex  "$AGENT_NAME" "$AGENT_DESC" "$body" "$AGENT_SHORT_DESC" "$AGENT_DEFAULT_PROMPT"

        synced_names+=("$AGENT_NAME")
        count=$((count + 1))
        echo ""
    done

    # Apply auto-bump logic on plugin.json (content hash, version bump if needed)
    apply_version_logic

    # Write the new manifest so next run can clean surgically
    if [[ ${#synced_names[@]} -gt 0 ]]; then
        printf '%s\n' "${synced_names[@]}" > "$MANIFEST_FILE"
    else
        rm -f "$MANIFEST_FILE"
    fi

    echo -e "${GREEN}━━━ Done: ${count} agents synced to 3 tools (plugin + cursor + codex) ━━━${NC}"
    echo ""
    echo "Usage:"
    echo "  Claude Code : install plugin via '/plugin marketplace add KeyProd/kp-agents'"
    echo "                + '/plugin install kp-agents@kp-agents', then invoke with"
    echo "                '/kp-agents:brainstorm', '/kp-agents:product', '/kp-agents:developer', ..."
    echo "  Cursor      : @kp-brainstorm (via rules picker)"
    echo "  Codex       : skills auto-détectées (kp-brainstorm, kp-product...)"
    echo "  Plugin      : artefacts générés dans ./plugins/kp-agents/skills/ (commit + push pour distribuer)"
    echo "  Dist        : artefacts générés dans ./dist/{cursor,codex}"
    if ! $INSTALL_TARGETS; then
        echo "  Install     : désactivée (--dist-only)"
    fi
    echo ""
    echo "Note Codex:"
    echo "  Redémarre Codex après sync pour recharger les skills KeyProd."
    echo ""
}

main "$@"
