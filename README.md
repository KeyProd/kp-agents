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

Côté Claude, chaque rôle est une **skill** — pas de subagent. Invoque-la directement :

```
/kp-agents:kp-setup
/kp-agents:kp-brainstorm
/kp-agents:kp-product
/kp-agents:kp-architect
/kp-agents:kp-developer
/kp-agents:kp-review
/kp-agents:kp-documentation
/kp-agents:kp-ux-ui
/kp-agents:kp-test
/kp-agents:kp-daily
```

Cinq **skills partagées** (`kp-sources-config`, `kp-docs-structure`, `kp-handoff`, `kp-doc-templates`, `kp-validation-criteres`) portent ce qui est commun à plusieurs rôles : les rôles les chargent à la demande via l'outil `Skill`. Ce qui est propre à un seul rôle vit dans ses `references/*.md`.

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
| Claude — rôle | `claude/skills/kp-<role>/SKILL.md` (+ `references/*.md`) | `name` + `description` (déclencheurs) + persona/méthode/routage |
| Claude — skill partagée | `claude/skills/kp-<nom>/SKILL.md` | `name` + `description` (usage) + procédure commune |
| Codex | `codex/kp-<nom>/SKILL.md` (+ `agents/openai.yaml`) | frontmatter `name` + `description` + `metadata`, corps inliné |
| Cursor | `cursor/kp-<nom>.mdc` | frontmatter `description` + `alwaysApply`, corps inliné |

Le préfixe `kp-` est obligatoire dans le nom de fichier ET dans le frontmatter `name:`.

> **Modèle 100 % skills (Claude)** : un rôle = une **skill**. Le contenu **transverse à plusieurs rôles** part en skill partagée (chargée via l'outil `Skill`) ; le contenu **propre à un rôle** reste dans ses `references/*.md` (lus via `Read`). ⚠️ `codex/` et `cursor/` n'ont pas de sous-fichiers : tout y est **inliné**, monolithique par rôle.

### Publier une mise à jour

1. Éditer l'agent dans les 3 dossiers. **Nouvel agent** → créer `claude/skills/kp-<nom>/SKILL.md` (le manifeste pointe le dossier `./claude/skills/`, rien à déclarer) et `codex/kp-<nom>/agents/openai.yaml`.
2. **Monter la version** à la main dans `.claude-plugin/plugin.json` (patch / minor / major) + mettre à jour `CHANGELOG.md`.
3. `./sync.sh` pour installer Cursor + Codex en local.
4. `git add` + commit (le hook de pré-commit vérifie le bump) + `git tag kp-agents-v<X.Y.Z>` + push.
5. Les utilisateurs Claude reçoivent la maj au prochain `/plugin marketplace update`.

> La version est **unique** (`plugin.json`) et sert de référence pour les 3 cibles. Le bump est **manuel** : aucun mécanisme automatique.

## Hook de pré-commit

`.githooks/pre-commit` bloque tout commit qui modifie un skill (`claude/skills/`, `codex/`, `cursor/`) **sans** bump de `version` dans `plugin.json` (comparaison vs `HEAD`). Les commits docs / `sync.sh` passent librement.

- Activation : automatique via `./sync.sh`, ou manuellement `git config core.hooksPath .githooks`.
- Contournement ponctuel : `git commit --no-verify`.

## Structure

```
.claude-plugin/
  marketplace.json                Catalogue marketplace (source: ./ → le repo est le plugin)
  plugin.json                     Manifeste : name, version (manuelle), skills[] → ./claude/skills/
claude/                           Contenu du plugin Claude Code (commité)
  skills/kp-<role>/               Skill de rôle (10) : SKILL.md + references/ (procédures du rôle)
  skills/kp-<partagée>/           Skill partagée (5) : sources-config, docs-structure, handoff,
                                    doc-templates, validation-criteres
codex/kp-<nom>/                   SKILL.md + agents/openai.yaml (monolithique, inliné)
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
