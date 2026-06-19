# kp-agents

Catalogue d'agents IA KeyProd distribué sur **Claude Code** (plugin marketplace), **Cursor** (règles locales) et **Codex** (skills locales).

## Principe

Pas de génération ni de templating : chaque outil a son **dossier dédié, au format qu'il attend directement**. Le contenu de chaque agent est écrit à plat et **dupliqué** dans les 3 dossiers.

```
claude/   → plugin Claude Code  → commit/push → distribué via le marketplace git
codex/    → skills Codex         → ~/.codex/skills/   (via sync.sh)
cursor/   → règles Cursor (.mdc) → ~/.cursor/rules/   (via sync.sh)
```

`sync.sh` n'installe que **Cursor et Codex** sur la machine locale. Claude Code passe par le marketplace git (aucun clone ni `sync.sh` côté consommateur).

## Utilisation

### Claude Code (plugin marketplace)

```
/plugin marketplace add KeyProd/kp-agents
/plugin install kp-agents@kp-agents
/reload-plugins
```

Côté Claude, chaque rôle est un **subagent** : il s'**auto-délègue** quand ta demande correspond à sa `description`, ou tu l'adresses explicitement :

```
@agent-kp-agents:kp-setup
@agent-kp-agents:kp-brainstorm
@agent-kp-agents:kp-product
@agent-kp-agents:kp-architect
@agent-kp-agents:kp-developer
@agent-kp-agents:kp-review
@agent-kp-agents:kp-documentation
@agent-kp-agents:kp-ux-ui
@agent-kp-agents:kp-test
@agent-kp-agents:kp-daily
```

Les **skills** (`kp-docs-structure`, `kp-test-implementation`, `kp-setup-git`…) portent les **actions** : les agents les chargent à la demande via l'outil `Skill`. Elles restent invocables directement (`/kp-agents:<skill>`) au besoin.

### Cursor et Codex (via sync.sh)

```bash
# Cloner le repo, puis installer en local
./sync.sh

# Supprimer les kp-* installés (~/.cursor/rules, ~/.codex/skills)
./sync.sh --clean
```

Après sync :
- **Cursor** : `@kp-brainstorm` via le sélecteur de règles
- **Codex** : skills auto-détectées (`kp-brainstorm`, `kp-product`, etc. — redémarre Codex pour recharger)

`sync.sh` câble aussi le hook de pré-commit du dépôt (`core.hooksPath .githooks`).

## Modifier ou créer un agent

Le contenu est **dupliqué dans les 3 dossiers** — il n'y a pas de source unique qui se propage. Pour chaque modification, éditer les 3 cibles en respectant leur format :

| Cible | Emplacement | Format |
|-------|-------------|--------|
| Claude — agent | `claude/agents/kp-<role>.md` | subagent : `name` + `description` + body (contexte + méthode) |
| Claude — skill | `claude/skills/kp-<skill>/SKILL.md` (+ `references/*.md`) | `name` + `description` + procédure (action) |
| Codex | `codex/kp-<nom>/SKILL.md` (+ `agents/openai.yaml`) | frontmatter `name` + `description` + `metadata` |
| Cursor | `cursor/kp-<nom>.mdc` | frontmatter `description` + `alwaysApply` |

Le préfixe `kp-` est obligatoire dans le nom de fichier ET dans le frontmatter `name:`.

> **Modèle agents / skills (Claude)** : un rôle = un **subagent** (contexte/méthode/bonnes pratiques) qui délègue les **actions** à des **skills** dédiées — partagées (`kp-sources-config`, `kp-docs-structure`, `kp-handoff`, `kp-doc-templates`) ou spécifiques (`kp-test-*`, `kp-setup-*`, `kp-doc-index`, `kp-uxui-dev-specs`). ⚠️ Appliqué à `claude/` uniquement pour l'instant ; `codex/` et `cursor/` restent monolithiques par rôle (réplication à venir).

### Publier une mise à jour

1. Éditer l'agent dans les 3 dossiers.
2. **Monter la version** à la main dans `claude/.claude-plugin/plugin.json` (patch / minor / major) + mettre à jour `CHANGELOG.md`.
3. `./sync.sh` pour installer Cursor + Codex en local.
4. `git add` + commit (le hook de pré-commit vérifie le bump) + `git tag kp-agents-v<X.Y.Z>` + push.
5. Les utilisateurs Claude reçoivent la maj au prochain `/plugin marketplace update`.

> La version est **unique** (`plugin.json`) et sert de référence pour les 3 cibles. Le bump est **manuel** : aucun mécanisme automatique.

## Hook de pré-commit

`.githooks/pre-commit` bloque tout commit qui modifie un agent ou un skill (`claude/agents/`, `claude/skills/`, `codex/`, `cursor/`) **sans** bump de `version` dans `plugin.json` (comparaison vs `HEAD`). Les commits docs / `sync.sh` passent librement.

- Activation : automatique via `./sync.sh`, ou manuellement `git config core.hooksPath .githooks`.
- Contournement ponctuel : `git commit --no-verify`.

## Structure

```
.claude-plugin/marketplace.json   Catalogue marketplace Claude Code (source: ./claude)
claude/                           Plugin Claude Code (commité)
  .claude-plugin/plugin.json      Manifeste : name, version (manuelle), description
  agents/kp-<role>.md             Subagent : contexte + méthode (10)
  skills/kp-<skill>/              SKILL.md + references/ : actions partagées & spécifiques (21)
codex/kp-<nom>/                   SKILL.md + agents/openai.yaml (monolithique par rôle)
cursor/kp-<nom>.mdc               Règle Cursor
sync.sh                           Installe cursor/ + codex/ en local (macOS)
.githooks/pre-commit              Vérifie le bump de version
docs/                             Documentation projet
```

## Agents

| Agent | Description |
|-------|-------------|
| `kp-brainstorm` | Explorer des idées, challenger des hypothèses |
| `kp-product` | Structurer en roadmap, epics et stories |
| `kp-architect` | Concevoir l'architecture technique |
| `kp-developer` | Implémenter les stories et epics |
| `kp-review` | Relire, tester, valider le code |
| `kp-documentation` | Analyser et maintenir la documentation |
| `kp-ux-ui` | Designer UX/UI et identité visuelle |
| `kp-setup` | Configurer les sources du projet (`.kp-agents.yml` / `.kp-agents.local.yml`) |
| `kp-test` | Orchestrer les tests E2E (cas Xray + test code + remontée) |
| `kp-daily` | Daily synthétique en français (sessions Claude J-1, Outlook, Teams) |

### Flux entre agents

```
kp-setup ┐
         ↓
kp-brainstorm → kp-product → kp-architect → kp-developer → kp-review → kp-documentation
                                                ↑                          ↓
                                                └──────────────────────────┘
```

`kp-setup` est transversal (auto-redirect depuis tout agent détectant une config manquante). `kp-test` s'insère après `kp-developer`. `kp-daily` est standalone. Détails dans [docs/agents.md](docs/agents.md).

## Configuration projet (`.kp-agents.yml` — optionnel)

Chaque projet peut déclarer une politique de sources : doc produit sur OneDrive, tickets dans JIRA via MCP, préférences Git d'équipe. **Par défaut (absence de fichier), le comportement est 100% local.**

```yaml
# .kp-agents.yml (commité — politique partagée par l'équipe)
product:
  mode: external          # local | external (OneDrive, ...)
  access: read-only       # read-write | read-only (pertinent si external)
tickets:
  mode: mcp               # local | mcp (JIRA via MCP)
  mcp_server: atlassian
  project_key: KP
git:
  branch_pattern: "feat/{slug}"
  auto_commit: ask        # yes | no | ask
  auto_push: no
```

```yaml
# .kp-agents.local.yml (gitignoré — chemins machine-spécifiques et override local)
product:
  path: /Users/alice/OneDrive/MonProjet
tickets:
  project_key: POC        # override local pour pousser dans un projet sandbox
```

Invoque `/kp-agents:kp-setup` pour configurer ces fichiers interactivement — l'agent est audit-first et ne modifie rien sans confirmation.

> **Important** : `.kp-agents.local.yml` doit être gitignoré. Ne jamais committer de chemin machine-spécifique.

## Troubleshooting

### `0 skills` au reload-plugins après install

Si `/reload-plugins` annonce `0 skills` juste après `/plugin install kp-agents@kp-agents`, le cache local du plugin est sans doute stale. Purge-le puis réinstalle :

```bash
rm -rf ~/.claude/plugins/cache/kp-agents
```

```
/plugin marketplace remove kp-agents
/plugin marketplace add KeyProd/kp-agents
/plugin install kp-agents@kp-agents
/reload-plugins
```

### Installer une branche feature (pour tester)

```
/plugin marketplace add KeyProd/kp-agents@refactor/ma-branche
/plugin install kp-agents@kp-agents
```

### Le commit est bloqué par le hook de pré-commit

Le hook exige un bump de `version` (`plugin.json`) dès qu'un skill change. Monte la version + mets à jour le `CHANGELOG.md`, ou contourne ponctuellement avec `git commit --no-verify` (commits sans impact skill).
