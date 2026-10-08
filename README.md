# kp-agents

Catalogue d'agents IA KeyProd distribué sur **Claude Code** et **Codex** (plugins, par la même marketplace git) et **Cursor** (règles locales).

## Principe

Pas de génération ni de templating : chaque outil a son **dossier dédié, au format qu'il attend directement**. Le contenu de chaque agent est écrit à plat et **dupliqué** dans les 3 dossiers.

```
claude/   → plugin Claude Code  → .claude-plugin/plugin.json ┐ commit/push → même
codex/    → plugin Codex        → .codex-plugin/plugin.json  ┘ marketplace git
cursor/   → règles Cursor (.mdc) → ~/.cursor/rules/   (via sync.sh)
```

Claude Code et Codex lisent le même catalogue, `.claude-plugin/marketplace.json` : aucun clone
ni script côté consommateur. Chaque plugin porte deux manifestes, un par outil, à la **même
version** ; celui de Codex pointe les variantes `codex/`. `sync.sh` n'installe plus que
**Cursor**.

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

### Codex (plugin marketplace)

```bash
codex plugin marketplace add KeyProd/kp-agents
codex plugin add kp-agents@kp-agents
```

Redémarrer Codex. Les skills apparaissent sous `kp-agents:kp-brainstorm`, `kp-agents:kp-product`…
(`$kp-agents:kp-brainstorm` dans la conversation). Mise à jour :

```bash
codex plugin marketplace upgrade kp-agents
```

Les copies laissées dans `~/.codex/skills/` par l'ancien `sync.sh` (avant la 4.2.0) doublent
les skills du plugin : `./sync.sh --clean` les retire.

### Cursor (via sync.sh)

```bash
# Cloner le repo, puis installer en local
./sync.sh

# Supprimer les règles kp-* (et les anciennes copies Codex)
./sync.sh --clean
```

Après sync : `@kp-brainstorm` via le sélecteur de règles. `sync.sh` câble aussi le hook de
pré-commit du dépôt (`core.hooksPath .githooks`).

## Plugin jpb-platform

La marketplace porte un **second plugin**, `jpb-platform`, indépendant de `kp-agents` : les
skills qui amènent une application sur JPB-Platform, la plateforme d'hébergement des
applications internes de JPB (`app-kickstart`, `app-conformite-audit`,
`app-conformite-transformation`).

```
/plugin install jpb-platform@kp-agents        # Claude Code
codex plugin add jpb-platform@kp-agents       # Codex
```

Il vit dans [`jpb-platform/`](jpb-platform/) (manifestes Claude et Codex, skills Claude,
variantes Codex, script de lecture du référentiel) et a **sa propre version** —
`jpb-platform/.claude-plugin/plugin.json` et `.codex-plugin/plugin.json`, tags
`jpb-platform-v<X.Y.Z>`. Plugin « mince » : ce
dépôt étant public, ses skills ne portent que la démarche et lisent les règles dans le dépôt
privé `KeyProd/jpb-platform` (compte membre de KeyProd et `gh` connecté requis). Détails :
[`jpb-platform/README.md`](jpb-platform/README.md).

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
2. **Monter la version** à la main dans `.claude-plugin/plugin.json` **et** `.codex-plugin/plugin.json` (même valeur ; patch / minor / major) + mettre à jour `CHANGELOG.md`.
3. `./sync.sh` pour installer Cursor en local.
4. `git add` + commit (le hook de pré-commit vérifie le bump et l'égalité des deux versions) + `git tag kp-agents-v<X.Y.Z>` + push.
5. Les utilisateurs reçoivent la maj par `/plugin marketplace update kp-agents` (Claude Code) ou `codex plugin marketplace upgrade kp-agents` (Codex).

> La version est **unique** par plugin — portée par ses deux manifestes, Claude et Codex, gardés égaux par le hook — et sert de référence pour les 3 cibles. Le bump est **manuel** : aucun mécanisme automatique.

## Hook de pré-commit

`.githooks/pre-commit` bloque tout commit qui modifie un skill **sans** bump de la `version` du plugin concerné (comparaison vs `HEAD`) : `claude/skills/`, `codex/`, `cursor/` → `.claude-plugin/plugin.json` ; `jpb-platform/{skills,codex,scripts}/` → `jpb-platform/.claude-plugin/plugin.json`. Il refuse aussi qu'un manifeste Codex (`.codex-plugin/plugin.json`) porte une autre version que le manifeste Claude du même plugin. Les commits docs / `sync.sh` passent librement.

- Activation : automatique via `./sync.sh`, ou manuellement `git config core.hooksPath .githooks`.
- Contournement ponctuel : `git commit --no-verify`.

## Structure

```
.claude-plugin/
  marketplace.json                Catalogue marketplace (source: ./ → le repo est le plugin)
  plugin.json                     Manifeste Claude : name, version (manuelle), skills[] → ./claude/skills/
.codex-plugin/
  plugin.json                     Manifeste Codex : même version, skills → ./codex/
claude/                           Contenu du plugin Claude Code (commité)
  skills/kp-<role>/               Skill de rôle (10) : SKILL.md + references/ (procédures du rôle)
  skills/kp-<partagée>/           Skill partagée (5) : sources-config, docs-structure, handoff,
                                    doc-templates, validation-criteres
codex/kp-<nom>/                   SKILL.md + agents/openai.yaml (monolithique, inliné)
cursor/kp-<nom>.mdc               Règle Cursor
sync.sh                           Installe cursor/ en local (macOS), retire les anciennes copies Codex
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
| `kp-setup` | Configurer les sources du projet (frontmatter `kp-agents:` des `docs/*.md`) |
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

## Configuration projet (optionnel)

Chaque projet peut déclarer une politique de sources : doc produit sur OneDrive, tickets dans JIRA via MCP, préférences Git d'équipe, configuration des tests E2E. **Par défaut (aucune configuration), le comportement est 100 % local.**

La configuration vit dans le **frontmatter YAML** des fichiers markdown de `docs/`, sous la clé `kp-agents:`. Chaque dimension a un fichier commité (politique d'équipe) et un fichier `.local.md` gitignoré (chemins et préférences machine) :

| Fichier | Commité | Clés portées |
|---------|---------|--------------|
| `docs/git.md` | ✅ | `branch_pattern` |
| `docs/git.local.md` | ❌ | `auto_commit`, `auto_push` |
| `docs/project.md` | ✅ | `tickets.mode`, `tickets.mcp_server`, `tickets.project_key`, `tickets.mapping.*` |
| `docs/project.local.md` | ❌ | overrides `tickets.*` |
| `docs/documentation.md` | ✅ | `product.mode`, `product.access` |
| `docs/documentation.local.md` | ❌ | `product.path`, `global_doc.specs`, `global_doc.tech`, `global_doc.product_inputs` |
| `docs/testing.md` | ✅ | `testing.framework`, `testing.tests_dir`, `testing.run_commands`, `testing.case_repository.*`, `testing.isolation.*` |
| `docs/testing.local.md` | ❌ | `testing.discovery.*`, `testing.case_repository.credentials_env` |

```markdown
<!-- docs/project.md — commité, politique partagée par l'équipe -->
---
kp-agents:
  tickets:
    mode: mcp             # local | mcp (JIRA via MCP)
    mcp_server: atlassian
    project_key: KP
---

# Projet & Tickets

Le body reste du markdown libre : conventions d'équipe, liens, contexte.
```

```markdown
<!-- docs/documentation.local.md — gitignoré, chemins machine-spécifiques -->
---
kp-agents:
  product:
    path: /Users/alice/OneDrive/MonProjet
  global_doc:
    tech: /Users/alice/OneDrive/Specs/tech
---
```

Invoque `/kp-agents:kp-setup` pour écrire ces fichiers interactivement — il est audit-first et ne modifie rien sans confirmation. C'est le **seul** agent autorisé à les écrire.

> **Migration** : les anciens `.kp-agents.yml` / `.kp-agents.local.yml` (v1.x) ne sont **plus lus** depuis la v2.0.0. Si `kp-setup` les détecte à la racine, il propose de migrer leur contenu vers les fichiers `docs/*.md` ci-dessus.

> **Important** : les fichiers `docs/*.local.md` doivent être gitignorés (`docs/*.local.md` suffit). Ne jamais committer de chemin machine-spécifique.

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
