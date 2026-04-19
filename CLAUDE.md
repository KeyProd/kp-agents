# kp-agents — Instructions pour Claude

## Principe fondamental

Ce projet est un **système de distribution multi-cibles** pour des agents IA.
La source de vérité unique est le dossier `agents/`. Les dossiers `plugins/kp-agents/skills/` et `dist/` sont **entièrement générés** par `sync.sh` — ne jamais y écrire manuellement.

## Distribution

- **Claude Code** → plugin marketplace (`plugins/kp-agents/`, commité dans git). Installation utilisateur via `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`. Invocation : `/kp-agents:<nom>`
- **Cursor** → règles importées localement par `sync.sh` (`~/.cursor/rules/kp-*.mdc`)
- **Codex** → skills importées localement par `sync.sh` (`~/.codex/skills/kp-*/`)

`sync.sh` **ne dépose plus rien dans `~/.claude/commands/`** — cette cible est gérée exclusivement par le plugin marketplace. Les résidus d'anciennes installations y sont automatiquement purgés au premier run.

## Structure du projet

```
agents/            ← Source de vérité. Un fichier .md par agent.
  _evals/          ← Jeux d'évaluation (trigger queries + output evals). Mainteneurs uniquement, ignoré par sync.sh.
includes/          ← Templates réutilisables, injectés via {{include:nom}}
.claude-plugin/
  marketplace.json ← Catalogue marketplace Claude Code (statique)
plugins/           ← GÉNÉRÉ par sync.sh, COMMITÉ dans git
  kp-agents/
    .claude-plugin/plugin.json    ← Manifeste statique (name, version, description)
    skills/<nom>/SKILL.md         ← Skills générés par sync.sh
dist/              ← GÉNÉRÉ. NON commité (.gitignore)
  cursor/          ← Règles Cursor (kp-*.mdc)
  codex/           ← Skills Codex (kp-*/SKILL.md + agents/openai.yaml)
sync.sh            ← Script de synchronisation agents/ → plugins/ + dist/
.installed-agents  ← Manifeste local (non versionné) : liste des agents installés au dernier sync
docs/              ← Documentation projet (vision, architecture, epics, stories)
```

## Ajouter ou modifier un agent

1. Créer ou modifier le fichier dans `agents/<nom>.md`
2. Respecter le frontmatter obligatoire :
   ```yaml
   ---
   name: <nom>
   description: "<description longue>"
   short_description: "<description courte>"
   default_prompt: "<prompt par défaut>"
   ---
   ```
3. Lancer `./sync.sh` (ou `./sync.sh --dist-only` pour générer sans installer Cursor/Codex)
4. Le script génère le SKILL.md dans `plugins/kp-agents/skills/<nom>/` et les artefacts Cursor/Codex préfixés `kp-`
5. Publier la mise à jour Claude :
   - `sync.sh` **bumpe automatiquement la version patch** si le contenu des skills a changé (cf. `_contentHash` + `_lastAutoVersion` dans `plugin.json` — géré par le script, ne pas modifier à la main)
   - Pour un bump mineur ou majeur (ajout/retrait d'agent, rupture), utiliser `./sync.sh --minor` ou `./sync.sh --major` (à venir dans S-0002 de E-0002)
   - `git add agents/ plugins/` puis commit, tag `kp-agents-v<X.Y.Z>` et push
   - Les utilisateurs reçoivent la maj au prochain `/plugin marketplace update`

### Flags disponibles

| Flag | Effet |
|------|-------|
| `--dist-only` | Génère dans `plugins/` et `dist/` sans installer dans `~/.cursor` et `~/.codex` |
| `--clean` | Supprime les agents listés dans `.installed-agents` (plugin skills + Cursor + Codex) puis sort |
| `--clean-all` | Supprime tous les `kp-*` via glob (plugin skills + Cursor + Codex) puis sort |
| `--minor` | Force un bump mineur (`X.Y.Z` → `X.(Y+1).0`). À utiliser pour l'ajout d'un nouvel agent ou une feature significative. Exclusif avec `--major`, incompatible avec `--clean` / `--clean-all`. |
| `--major` | Force un bump majeur (`X.Y.Z` → `(X+1).0.0`). À utiliser pour une rupture (retrait d'agent, renommage de namespace). Exclusif avec `--minor`. |

Sans `--minor` ni `--major`, `sync.sh` **auto-bumpe le patch** si le contenu des skills a changé (SHA256 stocké dans `plugin.json._contentHash`). Un édit manuel de `version` dans `plugin.json` est **respecté** (comparaison avec `_lastAutoVersion`) — `sync.sh` n'écrase jamais un bump manuel.

## Règles critiques

- **Ne jamais écrire dans `plugins/kp-agents/skills/`** — c'est généré, tout sera écrasé au prochain sync. `plugins/kp-agents/.claude-plugin/plugin.json` est **statique** et bumpé à la main lors d'une release
- **Ne jamais écrire dans `dist/`** — c'est un dossier généré, tout sera écrasé au prochain sync
- **Ne jamais modifier les fichiers dans `~/.cursor/rules/` ou `~/.codex/skills/`** — ils sont installés par `sync.sh`
- **Toujours passer par `agents/`** pour toute modification d'agent
- Nettoyage automatique au début de chaque sync : utilise `.installed-agents` pour supprimer chirurgicalement les agents du run précédent (permet de supprimer proprement un agent retiré de `agents/`). Fallback sur glob `kp-*` si le manifeste est absent.
- Cleanup one-shot des résidus d'installations Claude locales antérieures (`dist/claude/` + `~/.claude/commands/kp-*.md`) au début de chaque `sync.sh` — idempotent

## Includes et references

Deux directives de composition sont résolues par `sync.sh` avant écriture dans `plugins/` et `dist/` :

### `{{include:nom}}` — inline sur toutes les cibles
Pour le contenu transverse *léger* qui doit être présent immédiatement à l'activation du skill :
- `activation` — Rôle et persistance (2 lignes)
- `dependency-versions` — Règle « Versions des dépendances » (architect, developer, review)
- `docs-structure` — Convention de structure documentaire (complète, inclut les 4 {{ref}} de templates)
- `docs-structure-light` — Arborescence + règles, sans templates
- `handoff` — Convention de relais inter-agents
- `gotchas-transverses` — Gotchas communs aux 7 agents

### `{{ref:nom}}` — reference file (progressive disclosure, agentskills.io)
Pour le contenu *lourd* ne servant que ponctuellement (templates de livrables) :
- **Claude plugin** : le fichier est copié dans `plugins/kp-agents/skills/<agent>/references/<nom>.md` et la directive est remplacée par un pointeur court. Claude Code charge le template **à la demande** via Read.
- **Cursor / Codex** : inline (ces cibles ne supportent pas la sous-arborescence → fallback behavior).

Refs disponibles :
- `product-template`, `architect-template`, `epic-template`, `story-template`, `index-template`

### Stratégie d'inclusion par agent
- **product, developer, review** : `docs-structure` (qui charge les 4 templates en ref)
- **architect** : `docs-structure-light` + `architect-template` (ref)
- **documentation** : `docs-structure-light` + `index-template` (ref)
- **brainstorm, ux-ui** : `docs-structure-light`

## Workflow inter-agents

Invocations via le plugin Claude Code : `/kp-agents:<nom>`.

```mermaid
flowchart LR
    B["/kp-agents:brainstorm"] -->|idée qualifiée| P["/kp-agents:product"]
    P -->|epics et stories| A["/kp-agents:architect"]
    P -->|besoin UX| UX["/kp-agents:ux-ui"]
    A -->|design technique| D["/kp-agents:developer"]
    UX -->|specs visuelles| D
    D -->|implémentation| R["/kp-agents:review"]
    R -->|NO-GO| D
    R -->|GO + écarts| DOC["/kp-agents:documentation"]
    D -->|écarts détectés| DOC
```

**Pipeline standard** : brainstorm → product → architect → developer → review
**Agents transversaux** : ux-ui (entre product et developer), documentation (après review ou developer)
**Relais** : chaque agent produit un bloc de handoff structuré pour transmettre le contexte au suivant

## Agents disponibles

| Agent | Fichier | Invocation Claude | Rôle |
|-------|---------|-------------------|------|
| brainstorm | `agents/brainstorm.md` | `/kp-agents:brainstorm` | Explorer des idées, challenger des hypothèses |
| product | `agents/product.md` | `/kp-agents:product` | Structurer en roadmap, epics et stories |
| architect | `agents/architect.md` | `/kp-agents:architect` | Concevoir l'architecture technique |
| developer | `agents/developer.md` | `/kp-agents:developer` | Implémenter les stories et epics |
| review | `agents/review.md` | `/kp-agents:review` | Relire, tester, valider le code |
| documentation | `agents/documentation.md` | `/kp-agents:documentation` | Analyser et maintenir la documentation |
| ux-ui | `agents/ux-ui.md` | `/kp-agents:ux-ui` | Designer UX/UI et identité visuelle |

Pour Cursor : `@kp-<nom>` via le sélecteur de règles.
Pour Codex : skill auto-détectée `kp-<nom>`.
