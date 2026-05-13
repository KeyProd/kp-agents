# kp-agents — Instructions pour Codex

## Principe fondamental

Ce projet est un **système de distribution multi-cibles** pour des agents IA.
La source de vérité unique est le dossier `agents/`. Les dossiers `plugins/kp-agents/skills/` et `dist/` sont **entièrement générés** par `sync.sh` — ne jamais y écrire manuellement.

## Distribution

- **Codex** → plugin marketplace (`plugins/kp-agents/`, commité dans git). Installation utilisateur via `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`. Invocation : `/kp-agents:<nom>`
- **Cursor** → règles importées localement par `sync.sh` (`~/.cursor/rules/kp-*.mdc`)
- **Codex** → skills importées localement par `sync.sh` (`~/.codex/skills/kp-*/`)

`sync.sh` **ne dépose plus rien dans `~/.Codex/commands/`** — cette cible est gérée exclusivement par le plugin marketplace. Les résidus d'anciennes installations y sont automatiquement purgés au premier run.

## Structure du projet

```
agents/            ← Source de vérité. Un fichier .md par agent.
includes/          ← Templates réutilisables, injectés via {{include:nom}}
.Codex-plugin/
  marketplace.json ← Catalogue marketplace Codex (statique)
plugins/           ← GÉNÉRÉ par sync.sh, COMMITÉ dans git
  kp-agents/
    .Codex-plugin/plugin.json    ← Manifeste statique (name, version, description)
    skills/<nom>/SKILL.md         ← Skills générés par sync.sh
dist/              ← GÉNÉRÉ. NON commité (.gitignore)
  cursor/          ← Règles Cursor (kp-*.mdc)
  codex/           ← Skills Codex (kp-*/SKILL.md + agents/openai.yaml)
sync.sh            ← Script de synchronisation agents/ → plugins/ + dist/
.installed-agents  ← Manifeste local (non versionné) : liste des agents installés au dernier sync
.kp-agents.yml         ← OPTIONNEL — politique de sources du projet (commité)
.kp-agents.local.yml   ← OPTIONNEL — chemins machine-spécifiques (gitignoré)
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
5. Publier la mise à jour Codex :
   - `sync.sh` **bumpe automatiquement la version patch** si le contenu des skills a changé (cf. `_contentHash` + `_lastAutoVersion` dans `plugin.json` — géré par le script, ne pas modifier à la main)
   - Pour un bump mineur ou majeur (ajout/retrait d'agent, rupture), utiliser `./sync.sh --minor` ou `./sync.sh --major`
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

- **Ne jamais écrire dans `plugins/kp-agents/skills/`** — c'est généré, tout sera écrasé au prochain sync. `plugins/kp-agents/.Codex-plugin/plugin.json` est **statique** et bumpé à la main lors d'une release
- **Ne jamais écrire dans `dist/`** — c'est un dossier généré, tout sera écrasé au prochain sync
- **Ne jamais modifier les fichiers dans `~/.cursor/rules/` ou `~/.codex/skills/`** — ils sont installés par `sync.sh`
- **Toujours passer par `agents/`** pour toute modification d'agent
- Nettoyage automatique au début de chaque sync : utilise `.installed-agents` pour supprimer chirurgicalement les agents du run précédent (permet de supprimer proprement un agent retiré de `agents/`). Fallback sur glob `kp-*` si le manifeste est absent.
- Cleanup one-shot des résidus d'installations Codex locales antérieures (`dist/Codex/` + `~/.Codex/commands/kp-*.md`) au début de chaque `sync.sh` — idempotent
- **Configuration projet (`.kp-agents.yml` / `.kp-agents.local.yml`)** — depuis v1.1.0. **Seul l'agent `setup`** a le droit d'écrire ces fichiers. Les autres agents les lisent au démarrage et appliquent les règles de l'include `sources-config` (redirection chemin, fallback write, protocole d'erreur MCP). Absence de fichier = mode 100% local, comportement identique à v1.0.x.

## Includes et references

Deux directives de composition sont résolues par `sync.sh` avant écriture dans `plugins/` et `dist/` :

### `{{include:nom}}` — inline sur toutes les cibles
Pour le contenu transverse *léger* qui doit être présent immédiatement à l'activation du skill :
- `activation` — Rôle et persistance (2 lignes)
- `dependency-versions` — Règle « Versions des dépendances » (architect, developer, review)
- `docs-structure` — Convention de structure documentaire (complète, inclut les 4 {{ref}} de templates)
- `docs-structure-light` — Arborescence + règles, sans templates
- `handoff` — Convention de relais inter-agents
- `gotchas-transverses` — Gotchas communs aux 9 agents
- `sources-config` — Schéma `.kp-agents.yml`, règles de résolution de chemin, pipelines MCP pour tickets, préférences git (v1.1.0)

### `{{ref:nom}}` — reference file (progressive disclosure, agentskills.io)
Pour le contenu *lourd* ne servant que ponctuellement (templates de livrables) :
- **Codex plugin** : le fichier est copié dans `plugins/kp-agents/skills/<agent>/references/<nom>.md` et la directive est remplacée par un pointeur court. Codex charge le template **à la demande** via Read.
- **Cursor / Codex** : inline (ces cibles ne supportent pas la sous-arborescence → fallback behavior).

Refs disponibles :
- `product-template`, `architect-template`, `epic-template`, `story-template`, `index-template`

### Stratégie d'inclusion par agent
- **product, developer, review** : `docs-structure` (qui charge les 4 templates en ref)
- **architect** : `docs-structure-light` + `architect-template` (ref)
- **documentation** : `docs-structure-light` + `index-template` (ref)
- **brainstorm, ux-ui** : `docs-structure-light`

## Workflow inter-agents

Invocations via le plugin Codex : `/kp-agents:<nom>`.

```mermaid
flowchart LR
    S["/kp-agents:kp-setup"] -->|config prête| P["/kp-agents:kp-product"]
    B["/kp-agents:kp-brainstorm"] -->|idée qualifiée| P
    P -->|epics et stories| A["/kp-agents:kp-architect"]
    P -->|besoin UX| UX["/kp-agents:kp-ux-ui"]
    A -->|design technique| D["/kp-agents:kp-developer"]
    UX -->|specs visuelles| D
    D -->|implémentation| R["/kp-agents:kp-review"]
    R -->|NO-GO| D
    R -->|GO + écarts| DOC["/kp-agents:kp-documentation"]
    D -->|écarts détectés| DOC
    P -. config manquante .-> S
    A -. config manquante .-> S
    D -. config manquante .-> S
```

**Pipeline standard** : brainstorm → product → architect → developer → review
**Agents transversaux** : ux-ui (entre product et developer), documentation (après review ou developer), setup (auto-redirect depuis tout agent détectant une config manquante)
**Relais** : chaque agent produit un bloc de handoff structuré pour transmettre le contexte au suivant

## Agents disponibles

Convention de nommage (v2.0.0) : tous les agents portent le préfixe `kp-` dès le frontmatter `name:`. Côté Codex, le skill se nomme directement `kp-<nom>`.

| Agent | Fichier | Invocation Codex | Rôle |
|-------|---------|-------------------|------|
| kp-brainstorm | `agents/kp-brainstorm.md` | `kp-brainstorm` | Explorer des idées, challenger des hypothèses |
| kp-product | `agents/kp-product.md` | `kp-product` | Structurer en roadmap, epics et stories |
| kp-architect | `agents/kp-architect.md` | `kp-architect` | Concevoir l'architecture technique |
| kp-developer | `agents/kp-developer.md` | `kp-developer` | Implémenter les stories et epics |
| kp-review | `agents/kp-review.md` | `kp-review` | Relire, tester, valider le code |
| kp-documentation | `agents/kp-documentation.md` | `kp-documentation` | Analyser et maintenir la documentation |
| kp-ux-ui | `agents/kp-ux-ui.md` | `kp-ux-ui` | Designer UX/UI et identité visuelle |
| kp-setup | `agents/kp-setup.md` | `kp-setup` | Configurer les sources du projet (`.kp-agents.yml` / `.kp-agents.local.yml`) |
| kp-daily | `agents/kp-daily.md` | `kp-daily` | Générer un daily synthétique en français (sessions Claude J-1, Outlook, Teams) |

Pour Cursor : `@kp-<nom>` via le sélecteur de règles.
Pour Codex : skill auto-détectée `kp-<nom>`.
