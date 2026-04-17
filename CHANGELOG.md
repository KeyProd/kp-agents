# Changelog

Toutes les modifications notables de kp-agents sont listées ici. Format inspiré de [Keep a Changelog](https://keepachangelog.com/), versioning semver.

Chaque plugin de la marketplace est versionné indépendamment (`plugin.json` → champ `version`). Les tags git suivent le format `<plugin-name>-v<X.Y.Z>`.

---

## [kp-agents-v0.1.0] — 2026-04-17

Première release officielle du plugin `kp-agents`, distribué via la marketplace Claude Code `kp-agents` (hébergée sur GitHub `KeyProd/kp-agents`).

### Ajouté

- Plugin `kp-agents` au format Claude Code natif : 7 skills (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`) dans `plugins/kp-agents/skills/`
- Marketplace catalogue `.claude-plugin/marketplace.json` à la racine du repo, distribué via GitHub
- Namespaces d'invocation : `/kp-agents:brainstorm`, `/kp-agents:product`, etc. (7 commandes)
- Nouvelle section `Troubleshooting` dans `README.md` documentant :
  - Purge du cache plugin en cas d'anomalie `0 skills`
  - Migration des anciens `/kp-brainstorm` vers `/kp-agents:brainstorm`
  - Installation depuis une branche feature
- `docs/product.md` — vision produit, personas, KPIs
- `docs/architect.md` — architecture complète avec 4 ADR et diagrammes Mermaid
- `docs/project/roadmap.md` — Phase 1 (migration plugin) + Phase 2 (ouverture publique)
- Epic `E-0001 Plugin-Marketplace` avec 3 stories (S-0001, S-0002, S-0003)

### Modifié

- **Plugin renommé** : `kp-core` → `kp-agents` pour aligner le nom du plugin sur celui de la marketplace et du projet
- `sync.sh` refactoré :
  - Retrait complet de la génération et installation vers `~/.claude/commands/` (fonctions `generate_claude*` supprimées)
  - Nouvelle fonction `generate_plugin` produisant `plugins/kp-agents/skills/<name>/SKILL.md` avec frontmatter Claude plugin minimal
  - Nouvelle fonction `cleanup_legacy_claude` idempotente qui purge les résidus d'installations Claude locales antérieures
  - Flags `--clean` et `--clean-all` adaptés : préservent `plugin.json` (statique) mais purgent `plugins/kp-agents/skills/`
  - Messages d'aide (`--help`) et logs finaux mis à jour
- Documentation entièrement réalignée sur l'architecture plugin marketplace :
  - `README.md` : installation scindée entre plugin Claude et `sync.sh` (Cursor/Codex), suppression section RecetteMoi
  - `CLAUDE.md` : section Distribution, structure du projet, workflow inter-agents avec namespaces `/kp-agents:<nom>`
  - `docs/agents.md` : retrait complet de la section Pipeline RecetteMoi, namespaces mis à jour dans 8 diagrammes Mermaid

### Supprimé

- **Agents RecetteMoi** (`recettemoi-support`, `recettemoi-dev`, `recettemoi-review`) — hors périmètre du plugin
- Plugin temporaire `kp-agents-spike` (anciennement `kp-core-spike`) utilisé pour le spike de faisabilité
- Cible d'installation Claude locale dans `sync.sh` et `dist/claude/` (désormais distribué via plugin marketplace)

### Architecture

Migration achevée vers une architecture marketplace + plugin natif :
- **Claude Code** : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
- **Cursor** : `./sync.sh` installe les règles dans `~/.cursor/rules/`
- **Codex** : `./sync.sh` installe les skills dans `~/.codex/skills/`

Source unique : `agents/*.md` avec directives `{{include:xxx}}` résolues par `sync.sh`.

### Notes de migration pour utilisateurs existants

Si tu avais installé kp-agents avec une version antérieure de `sync.sh` :

1. Lance `./sync.sh` une fois — les anciens `~/.claude/commands/kp-*.md` seront automatiquement purgés (cleanup idempotent)
2. Installe le plugin via `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
3. Les anciens noms `/kp-brainstorm` deviennent `/kp-agents:brainstorm` (namespace imposé par Claude Code)

Si tu avais installé le spike `kp-agents-spike` :

1. `/plugin uninstall kp-agents-spike@kp-agents`
2. `/plugin marketplace update kp-agents`
3. `/plugin install kp-agents@kp-agents`
