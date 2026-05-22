# kp-agents

Système de distribution multi-cibles pour agents IA KeyProd. Définir un agent une seule fois, le déployer sur **Claude Code** (via un plugin marketplace installable), **Cursor** (règles importées localement) et **Codex** (skills importées localement).

## Principe

```
agents/*.md  ──→  sync.sh  ──→  plugins/kp-agents/  → commit/push → Claude Code via marketplace
                            ──→  dist/cursor/      → ~/.cursor/rules/
                            ──→  dist/codex/       → ~/.codex/skills/
```

Un seul fichier source par agent dans `agents/`. Le script `sync.sh` :
- **Génère le plugin `kp-agents`** dans `plugins/kp-agents/` (versionné dans git, distribué via le marketplace Claude Code)
- **Installe les règles Cursor** dans `~/.cursor/rules/`
- **Installe les skills Codex** dans `~/.codex/skills/`

## Utilisation

### Claude Code (plugin marketplace)

L'installation se fait directement depuis le repo git — aucun clone ni `sync.sh` nécessaire côté consommateur :

```
/plugin marketplace add KeyProd/kp-agents
/plugin install kp-agents@kp-agents
/reload-plugins
```

Puis invoque les agents avec le namespace `kp-agents:` (chaque skill est lui-même préfixé `kp-` pour garantir son unicité — convention v2.0.0) :

```
/kp-agents:kp-setup
/kp-agents:kp-brainstorm
/kp-agents:kp-product
/kp-agents:kp-architect
/kp-agents:kp-developer
/kp-agents:kp-review
/kp-agents:kp-documentation
/kp-agents:kp-ux-ui
/kp-agents:kp-e2e
/kp-agents:kp-daily
```

### Cursor et Codex (via sync.sh)

```bash
# Cloner le repo, puis générer et installer
./sync.sh

# Générer sans installer (artefacts dans plugins/ et dist/ uniquement)
./sync.sh --dist-only

# Nettoyer les agents installés lors du précédent sync (via manifeste)
./sync.sh --clean

# Nettoyer TOUS les artefacts kp-* (glob, indépendant du manifeste)
./sync.sh --clean-all
```

Après sync :
- **Cursor** : `@kp-brainstorm` via le sélecteur de règles
- **Codex** : skills auto-détectées (`kp-brainstorm`, `kp-product`, etc.)

**Note** : `sync.sh` ne dépose plus rien dans `~/.claude/commands/` — la distribution Claude Code passe exclusivement par le plugin marketplace. Si tu avais des `kp-*.md` installés par une version antérieure de `sync.sh`, ils sont automatiquement purgés au premier run.

### Manifeste de synchronisation

À chaque run, `sync.sh` écrit la liste des agents installés dans `.installed-agents` (fichier local, non versionné). Cela permet au run suivant de supprimer proprement les agents qui ont été retirés de `agents/` entre-temps.

- `--clean` lit ce manifeste et retire chirurgicalement chaque agent (plugin skills + Cursor + Codex)
- `--clean-all` ignore le manifeste et supprime tout ce qui commence par `kp-*` dans les 3 cibles (utile pour repartir de zéro)

## Créer un agent

Créer `agents/kp-mon-agent.md` (le préfixe `kp-` est désormais obligatoire dans le nom de fichier ET dans le frontmatter `name:` — convention v2.0.0) :

```yaml
---
name: kp-mon-agent
description: "Description longue pour les outils IA"
short_description: "Description courte pour les listes"
default_prompt: "Prompt suggéré à l'utilisateur."
---

# Contenu de l'agent

Instructions, processus, règles...
```

Lancer `./sync.sh` — le plugin Claude exposera l'agent comme `/kp-agents:kp-mon-agent`, Cursor comme `@kp-mon-agent`, Codex avec la skill `kp-mon-agent`.

### Publier une mise à jour Claude Code

1. Modifier l'agent source dans `agents/kp-<nom>.md`
2. Lancer `./sync.sh` pour régénérer `plugins/kp-agents/skills/kp-<nom>/SKILL.md`. **La version patch est bumpée automatiquement** si le contenu des skills a changé (via un hash SHA256 stocké dans `_contentHash`).
   - Pour l'ajout d'un nouvel agent ou une feature notable : `./sync.sh --minor` (`X.Y.Z` → `X.(Y+1).0`)
   - Pour une rupture (retrait d'agent, renommage de namespace) : `./sync.sh --major` (`X.Y.Z` → `(X+1).0.0`)
   - `--minor` et `--major` sont mutuellement exclusifs et ne se combinent pas avec `--clean` / `--clean-all`.
3. `git add agents/ plugins/ && git commit && git tag kp-agents-v<X.Y.Z> && git push --tags`
4. Les utilisateurs reçoivent la mise à jour au prochain `/plugin marketplace update` (ou automatiquement selon leur config)

**Note** : un bump manuel de `version` dans `plugin.json` (édition directe) est **respecté** par `sync.sh` — il ne re-bumpe pas par-dessus. Le mécanisme compare `version` à `_lastAutoVersion` pour détecter les bumps manuels.

## Includes

Les agents peuvent réutiliser des blocs partagés avec `{{include:nom}}` :

```markdown
{{include:docs-structure}}
```

Les fichiers d'include sont dans `includes/*.md`. Les directives sont **résolues par `sync.sh`** — les artefacts générés dans `plugins/`, `dist/cursor/` et `dist/codex/` contiennent du markdown final sans dépendances.

## Structure

```
agents/            Source de vérité (un .md par agent)
includes/          Templates partagés ({{include:nom}})
.claude-plugin/
  marketplace.json Catalogue du marketplace Claude Code (statique)
plugins/           Plugins Claude Code (COMMITÉS dans git)
  kp-agents/
    .claude-plugin/plugin.json  Manifeste statique (name, version, description)
    skills/        Skills générés par sync.sh (SKILL.md par agent)
dist/              Artefacts Cursor / Codex (NON commités, .gitignore)
  cursor/          Règles Cursor (.mdc)
  codex/           Skills Codex (SKILL.md + openai.yaml)
sync.sh            Script de synchronisation
docs/              Documentation projet (vision, architecture, epics, stories)
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
| `kp-e2e` | Générer et maintenir des tests E2E browser (Playwright + Playwright MCP) dans `devel/` |
| `kp-daily` | Générer un daily synthétique en français (sessions Claude J-1, Outlook, Teams) |

### Flux entre agents

```
kp-setup ┐
         ↓
kp-brainstorm → kp-product → kp-architect → kp-developer → kp-review → kp-documentation
                                                ↑                          ↓
                                                └──────────────────────────┘
```

`kp-setup` est transversal : auto-redirect depuis tout agent détectant une config manquante. `kp-daily` est un agent standalone (pas dans le pipeline de dev). Détails dans [docs/agents.md](docs/agents.md).

## Configuration projet (`.kp-agents.yml` — optionnel)

**v1.1.0** — Chaque projet peut déclarer une politique de sources : doc produit sur OneDrive, tickets dans JIRA via MCP, préférences Git d'équipe. **Par défaut (absence de fichier), le comportement est 100% local — rétro-compatible avec toute version antérieure.**

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

> **Important** : `.kp-agents.local.yml` doit être gitignoré (l'agent `setup` le fait automatiquement). Ne jamais committer de chemin machine-spécifique.

## Troubleshooting

### `0 skills` au reload-plugins après install

Si `/reload-plugins` annonce `0 skills` au lieu du nombre attendu juste après `/plugin install kp-agents@kp-agents`, le cache local du plugin est sans doute stale (typiquement après un renommage ou un changement de source du plugin). Purge le cache puis réinstalle :

```bash
rm -rf ~/.claude/plugins/cache/kp-agents
```

Puis dans Claude Code :

```
/plugin marketplace remove kp-agents
/plugin marketplace add KeyProd/kp-agents
/plugin install kp-agents@kp-agents
/reload-plugins
```

### Les anciens `/kp-brainstorm` (sans namespace) ne répondent plus

Normal : la distribution Claude Code se fait désormais via le plugin marketplace. Les skills sont préfixés `kp-` dans leur frontmatter (convention v2.0.0, garantit l'unicité côté Cursor / Codex et lève toute collision avec d'autres plugins) et le namespace de plugin (`kp-agents:`) reste préfixé devant. Forme d'invocation finale : `/kp-agents:kp-<nom>`. L'ancien install local via `sync.sh` a été automatiquement purgé au premier run de la nouvelle version.

Utilise `/kp-agents:kp-brainstorm` à la place de `/kp-brainstorm`, etc.

### Installer une branche feature (pour tester)

```
/plugin marketplace add KeyProd/kp-agents@feat/ma-branche
/plugin install kp-agents@kp-agents
```

### Auto-bump de version : la version ne bouge pas après modification

Si tu modifies un agent, lances `./sync.sh`, mais que la version dans `plugin.json` reste identique :

1. **Vérifie les outils de hash** : `shasum` (standard macOS/Linux) ou `openssl` doit être dans le `PATH`. Si aucun des deux n'est disponible, `sync.sh` affiche un warning `"Hash calculation skipped (no SHA256 tool available)"` et saute le bump.
2. **Vérifie `python3`** : la manipulation JSON du `plugin.json` dépend de `python3` (standard macOS/Linux récent). Test rapide : `python3 --version`.
3. **Vérifie le champ `_lastAutoVersion`** : si `version` dans `plugin.json` diffère de `_lastAutoVersion`, `sync.sh` considère un bump manuel et ne re-bumpe pas. Aligne les deux champs pour réactiver l'auto-patch, ou utilise `./sync.sh --minor` / `--major` pour forcer.
4. **Relance manuellement** après modification d'un agent : `./sync.sh`. Le log doit afficher `"Plugin version bumped: X.Y.Z → X.Y.(Z+1) (content changed)"`.

### Conflit Git sur `plugin.json` après merge concurrent

Si deux branches ont bumpé `plugin.json` en parallèle, un merge peut produire une incohérence entre `version` et `_contentHash`. Résolution :

1. Résous le conflit manuellement en gardant la plus haute des deux versions
2. Relance `./sync.sh` — il mettra à jour `_contentHash` pour refléter l'état réel des skills et alignera `_lastAutoVersion`
3. Vérifie avec `claude plugin validate .` que le résultat est conforme

### Rollback d'une release

Semver ne permet pas de "descendre" la version côté client (un client qui a reçu `0.3.0` ignorera un futur `0.2.1` sorti après). Pour revenir en arrière :

1. `git revert` le commit fautif (le code revient à l'état précédent)
2. Lance `./sync.sh` — le hash détecte le changement et bumpe le patch en avant (`0.3.0` → `0.3.1`)
3. La version `0.3.1` porte alors le contenu "corrigé" (qui est l'état pré-release problématique)
