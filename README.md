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

Puis invoque les agents avec le namespace `kp-agents:` :

```
/kp-agents:brainstorm
/kp-agents:product
/kp-agents:architect
/kp-agents:developer
/kp-agents:review
/kp-agents:documentation
/kp-agents:ux-ui
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

Créer `agents/mon-agent.md` avec ce frontmatter :

```yaml
---
name: mon-agent
description: "Description longue pour les outils IA"
short_description: "Description courte pour les listes"
default_prompt: "Prompt suggéré à l'utilisateur."
---

# Contenu de l'agent

Instructions, processus, règles...
```

Lancer `./sync.sh` — le plugin Claude exposera l'agent comme `/kp-agents:mon-agent`, Cursor comme `@kp-mon-agent`, Codex avec la skill `kp-mon-agent`.

### Publier une mise à jour Claude Code

1. Modifier l'agent source dans `agents/<nom>.md`
2. Lancer `./sync.sh` pour régénérer `plugins/kp-agents/skills/<nom>/SKILL.md`. **La version patch est bumpée automatiquement** si le contenu des skills a changé (via un hash SHA256 stocké dans `_contentHash`). Pour un bump mineur (ajout d'agent) ou majeur (rupture), utiliser `./sync.sh --minor` ou `./sync.sh --major` (à venir).
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
| `brainstorm` | Explorer des idées, challenger des hypothèses |
| `product` | Structurer en roadmap, epics et stories |
| `architect` | Concevoir l'architecture technique |
| `developer` | Implémenter les stories et epics |
| `review` | Relire, tester, valider le code |
| `documentation` | Analyser et maintenir la documentation |
| `ux-ui` | Designer UX/UI et identité visuelle |

### Flux entre agents

```
brainstorm → product → architect → developer → review → documentation
                                       ↑                    ↓
                                       └────────────────────┘
```

Détails dans [docs/agents.md](docs/agents.md).

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

Normal : la distribution Claude Code se fait désormais via le plugin marketplace. Les namespaces sont imposés sous la forme `/kp-agents:<nom>`. L'ancien install local via `sync.sh` a été automatiquement purgé au premier run de la nouvelle version.

Utilise `/kp-agents:brainstorm` à la place de `/kp-brainstorm`, etc.

### Installer une branche feature (pour tester)

```
/plugin marketplace add KeyProd/kp-agents@feat/ma-branche
/plugin install kp-agents@kp-agents
```
