#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# sync.sh — Installe les skills KeyProd sur cette machine (macOS).
#
# Plus aucune génération : les 3 dossiers plats sont la source de
# vérité, déjà au format attendu par chaque outil.
#
#   claude/   → plugin Claude Code, distribué via le marketplace git
#               (PAS d'install locale ici — voir /plugin marketplace)
#   cursor/   → règles Cursor (.mdc)   → copiées dans ~/.cursor/rules/
#   codex/    → skills Codex           → copiées dans ~/.codex/skills/
#   jpb-platform/codex/ → skills Codex du plugin jpb-platform (jpb-*)
#                         → copiées dans ~/.codex/skills/
#
# Ce script se contente de COPIER cursor/ et codex/ vers leurs
# emplacements locaux, et de câbler le hook de pré-commit du dépôt.
# Aucun bump de version : la version (claude/.claude-plugin/plugin.json)
# se monte à la main.
# ─────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CURSOR_SRC="$REPO_DIR/cursor"
CODEX_SRC="$REPO_DIR/codex"
JPB_CODEX_SRC="$REPO_DIR/jpb-platform/codex"

CURSOR_DST="$HOME/.cursor/rules"
CODEX_DST="$HOME/.codex/skills"

CLEAN_ONLY=false

# Colors
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[sync]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  !${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; }

usage() {
    cat <<'HELP'
Usage: ./sync.sh [--clean]

Installe les skills KeyProd sur cette machine :
  - cursor/*.mdc   → ~/.cursor/rules/
  - codex/kp-*/    → ~/.codex/skills/
  - jpb-platform/codex/jpb-*/ → ~/.codex/skills/
  - câble le hook de pré-commit du dépôt (core.hooksPath .githooks)

Claude Code n'est PAS installé localement : il passe par le marketplace
  /plugin marketplace add KeyProd/kp-agents
  /plugin install kp-agents@kp-agents

Options:
  --clean   Supprime les artefacts kp-* et jpb-* installés (~/.cursor/rules, ~/.codex/skills) puis sort
  -h, --help
HELP
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean) CLEAN_ONLY=true ;;
        -h|--help) usage; exit 0 ;;
        *) err "Option inconnue : $1"; usage; exit 1 ;;
    esac
    shift
done

# ── Nettoyage des artefacts kp-* et jpb-* installés (toujours fait avant une (ré)install) ──
clean_targets() {
    rm -f "$CURSOR_DST"/kp-*.mdc 2>/dev/null || true
    rm -rf "$CODEX_DST"/kp-* "$CODEX_DST"/jpb-* 2>/dev/null || true
}

if $CLEAN_ONLY; then
    log "Suppression des skills KeyProd installés…"
    clean_targets
    ok "Cursor  : ~/.cursor/rules/kp-*.mdc supprimés"
    ok "Codex   : ~/.codex/skills/kp-* et jpb-* supprimés"
    exit 0
fi

# ── Câblage du hook de pré-commit (idempotent) ──
if [[ -d "$REPO_DIR/.git" ]] || git -C "$REPO_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    current_hooks_path="$(git -C "$REPO_DIR" config --local core.hooksPath || true)"
    if [[ "$current_hooks_path" != ".githooks" ]]; then
        git -C "$REPO_DIR" config core.hooksPath .githooks
        ok "Hook    : core.hooksPath → .githooks"
    fi
    chmod +x "$REPO_DIR/.githooks/pre-commit" 2>/dev/null || true
fi

# ── Install Cursor ──
log "Cursor → $CURSOR_DST"
mkdir -p "$CURSOR_DST"
rm -f "$CURSOR_DST"/kp-*.mdc 2>/dev/null || true
cursor_count=0
for f in "$CURSOR_SRC"/kp-*.mdc; do
    [[ -e "$f" ]] || continue
    cp "$f" "$CURSOR_DST/"
    ok "$(basename "$f")"
    cursor_count=$((cursor_count + 1))
done

# ── Install Codex ──
log "Codex → $CODEX_DST"
mkdir -p "$CODEX_DST"
rm -rf "$CODEX_DST"/kp-* "$CODEX_DST"/jpb-* 2>/dev/null || true
codex_count=0
for d in "$CODEX_SRC"/kp-*/ "$JPB_CODEX_SRC"/jpb-*/; do
    [[ -d "$d" ]] || continue
    name="$(basename "$d")"
    cp -R "$d" "$CODEX_DST/$name"
    rm -f "$CODEX_DST/$name/.DS_Store" 2>/dev/null || true
    ok "skill $name"
    codex_count=$((codex_count + 1))
done

echo
echo -e "${GREEN}━━━ Terminé : $cursor_count règles Cursor + $codex_count skills Codex installées ━━━${NC}"
echo
echo "Claude Code : plugin via le marketplace git"
echo "              /plugin marketplace add KeyProd/kp-agents"
echo "              /plugin install kp-agents@kp-agents"
echo "              /plugin install jpb-platform@kp-agents"
echo "Cursor      : @kp-brainstorm (via le sélecteur de règles)"
echo "Codex       : skills auto-détectées (redémarre Codex pour les recharger) — jpb-* : gh connecté à KeyProd requis"
