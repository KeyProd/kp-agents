#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# sync.sh — Installe les règles Cursor KeyProd sur cette machine (macOS).
#
# Plus aucune génération : les 3 dossiers plats sont la source de
# vérité, déjà au format attendu par chaque outil.
#
#   claude/   → plugin Claude Code, distribué par la marketplace git
#               (/plugin marketplace add KeyProd/kp-agents)
#   codex/    → plugin Codex, distribué par la MÊME marketplace git
#               (codex plugin marketplace add KeyProd/kp-agents) — plus
#               copié par ce script depuis la 4.2.0 ; ce script retire
#               seulement les anciennes copies de ~/.codex/skills/
#   cursor/   → règles Cursor (.mdc)   → copiées dans ~/.cursor/rules/
#
# Ce script COPIE cursor/ vers ~/.cursor/rules/, nettoie les anciennes
# copies Codex, et câble le hook de pré-commit du dépôt.
# Aucun bump de version : la version (.claude-plugin/plugin.json)
# se monte à la main.
# ─────────────────────────────────────────────────────────────

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CURSOR_SRC="$REPO_DIR/cursor"

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

Installe les règles Cursor KeyProd sur cette machine :
  - cursor/*.mdc   → ~/.cursor/rules/
  - retire les anciennes copies Codex (~/.codex/skills/kp-* et jpb-*)
  - câble le hook de pré-commit du dépôt (core.hooksPath .githooks)

Claude Code et Codex passent par la marketplace git, sans ce script :
  Claude Code : /plugin marketplace add KeyProd/kp-agents
                /plugin install kp-agents@kp-agents
                /plugin install jpb-platform@kp-agents
  Codex       : codex plugin marketplace add KeyProd/kp-agents
                codex plugin add kp-agents@kp-agents
                codex plugin add jpb-platform@kp-agents

Options:
  --clean   Supprime les règles Cursor kp-* et les anciennes copies Codex kp-* / jpb-* puis sort
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
    ok "Codex   : anciennes copies ~/.codex/skills/kp-* et jpb-* supprimées"
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

# ── Anciennes copies Codex (avant la 4.2.0, Codex passait par ce script) ──
# Elles doubleraient les skills du plugin Codex : on les retire.
legacy="$(ls -d "$CODEX_DST"/kp-* "$CODEX_DST"/jpb-* 2>/dev/null || true)"
if [[ -n "$legacy" ]]; then
    log "Codex : anciennes copies retirées de $CODEX_DST (remplacées par le plugin)"
    rm -rf "$CODEX_DST"/kp-* "$CODEX_DST"/jpb-*
    echo "$legacy" | sed 's|.*/|    - |'
fi

echo
echo -e "${GREEN}━━━ Terminé : $cursor_count règles Cursor installées ━━━${NC}"
echo
echo "Cursor      : @kp-brainstorm (via le sélecteur de règles)"
echo "Claude Code : /plugin marketplace add KeyProd/kp-agents"
echo "              /plugin install kp-agents@kp-agents && /plugin install jpb-platform@kp-agents"
echo "Codex       : codex plugin marketplace add KeyProd/kp-agents"
echo "              codex plugin add kp-agents@kp-agents && codex plugin add jpb-platform@kp-agents"
echo "              (jpb-platform : gh connecté à un compte membre de KeyProd)"
