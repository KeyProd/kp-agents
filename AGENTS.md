# kp-agents — Instructions pour les agents (Codex / autres)

## Principe fondamental

Ce projet est un **catalogue d'agents IA distribué sur 3 outils**.
Il n'y a **plus de génération ni de templating** : chaque outil a son dossier dédié, au format qu'il attend directement. Le contenu de chaque agent est **écrit à plat et dupliqué** dans les 3 dossiers.

```
claude/   ← plugin Claude Code : subagents (agents/) + skills (skills/)
codex/    ← skills Codex (monolithiques par rôle)
cursor/   ← règles Cursor (.mdc, monolithiques par rôle)
```

⚠️ **Asymétrie transitoire** : côté **Claude**, chaque rôle est un **subagent** (`claude/agents/`, contexte + méthode) qui délègue les **actions** à des **skills** (`claude/skills/`, partagées + spécifiques). `codex/` et `cursor/` restent des skills/règles **monolithiques par rôle** jusqu'à une passe de réplication.

Modifier un rôle = éditer son agent + ses skills (`claude/`) **et** ses équivalents `codex/` / `cursor/`. Pas de `sync.sh` qui régénère : il se contente d'**installer** Cursor et Codex sur la machine locale.

## Distribution

- **Claude Code** → plugin marketplace (`claude/`, commité dans git). Le catalogue racine `.claude-plugin/marketplace.json` pointe sur `./` (le repo entier est le plugin). Installation : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`. Invocation : `/kp-agents:<nom>`
- **Cursor** → règles copiées par `sync.sh` dans `~/.cursor/rules/kp-*.mdc`
- **Codex** → skills copiées par `sync.sh` dans `~/.codex/skills/kp-*/`

## Structure du projet

```
.claude-plugin/
  marketplace.json   ← Catalogue marketplace (source: ./ → le repo entier est le plugin)
  plugin.json        ← Manifeste plugin : name, version (manuelle), agents[] (liste de fichiers) + skills[] → ./claude
claude/              ← Contenu du plugin Claude Code (référencé par plugin.json)
  agents/kp-<role>.md          ← Subagent : contexte + méthode + bonnes pratiques (10)
  skills/kp-<skill>/           ← Skill d'action ou partagée (22)
    SKILL.md         ← frontmatter name + description, puis la procédure
    references/*.md   ← Templates / gabarits lourds chargés à la demande
codex/               ← Skills Codex (monolithiques par rôle — réplication à venir)
  kp-<nom>/
    SKILL.md         ← Skill (frontmatter name + description + metadata)
    agents/openai.yaml   ← Interface Codex (display_name, default_prompt, policy)
cursor/              ← Règles Cursor
  kp-<nom>.mdc       ← Règle (frontmatter description + alwaysApply)
sync.sh              ← Installe cursor/ → ~/.cursor/rules et codex/ → ~/.codex/skills (macOS)
.githooks/pre-commit ← Vérifie le bump de version quand un skill change
docs/                ← Documentation projet (vision, architecture, epics, stories)
.kp-agents.yml          ← OPTIONNEL — politique de sources du projet (commité)
.kp-agents.local.yml    ← OPTIONNEL — chemins machine-spécifiques (gitignoré)
```

## Format par cible

### Codex (`codex/kp-<nom>/`)
- `SKILL.md` — frontmatter `name`, `description`, `metadata.short-description`, puis le corps inliné (pas de sous-dossier `references/` : tout est dans le SKILL.md).
- `agents/openai.yaml` — `interface` (`display_name`, `short_description`, `default_prompt`) + `policy.allow_implicit_invocation`.

### Claude (`claude/skills/kp-<nom>/`)
- `SKILL.md` (persona + scope + router) + `persona.md` + `references/*.md` (templates lourds, chargés à la demande).

### Cursor (`cursor/kp-<nom>.mdc`)
- Frontmatter `description` + `alwaysApply: false`, puis le corps inliné.

## Ajouter ou modifier un agent

1. Éditer le contenu dans les **3 dossiers** (`claude/skills/kp-<nom>/`, `codex/kp-<nom>/`, `cursor/kp-<nom>.mdc`) en respectant le format de chacun.
2. Pour un **nouvel** agent : ajouter son fichier à la liste `agents[]` de `.claude-plugin/plugin.json`, créer aussi `codex/kp-<nom>/agents/openai.yaml` et, si besoin, les `references/` côté Claude.
3. **Monter la version** dans `.claude-plugin/plugin.json` (patch / minor / major) + mettre à jour `CHANGELOG.md`.
4. Lancer `./sync.sh` pour installer Cursor + Codex en local.
5. `git add` + commit (le hook de pré-commit vérifie le bump) + tag `kp-agents-v<X.Y.Z>` + push.

Le préfixe `kp-` est obligatoire dans le nom de fichier ET dans le frontmatter `name:`.

## Règles critiques

- **Toute modification d'agent doit être répliquée dans les 3 dossiers.** Le contenu est dupliqué par design.
- **La version est unique et manuelle** (`.claude-plugin/plugin.json` → `version`), référence pour les 3 cibles.
- **`sync.sh` ne génère plus rien** : il copie `cursor/` et `codex/` vers `~/.cursor` / `~/.codex` et câble le hook. Ne pas y remettre de templating ou de bump.

## sync.sh

```
./sync.sh            # installe cursor/ + codex/ en local + câble le hook
./sync.sh --clean    # supprime les kp-* installés puis sort
./sync.sh -h         # aide
```

## Hook de pré-commit

`.githooks/pre-commit` bloque tout commit modifiant un skill (`claude/skills/`, `codex/`, `cursor/`) sans bump de `version` vs `HEAD`. Activation via `./sync.sh` (ou `git config core.hooksPath .githooks`). Contournement : `git commit --no-verify`.

## Agents disponibles

| Agent | Invocation Claude | Rôle |
|-------|-------------------|------|
| kp-brainstorm | `/kp-agents:kp-brainstorm` | Explorer des idées, challenger des hypothèses |
| kp-product | `/kp-agents:kp-product` | Structurer en roadmap, epics et stories |
| kp-architect | `/kp-agents:kp-architect` | Concevoir l'architecture technique |
| kp-developer | `/kp-agents:kp-developer` | Implémenter les stories et epics |
| kp-review | `/kp-agents:kp-review` | Relire, tester, valider le code |
| kp-documentation | `/kp-agents:kp-documentation` | Analyser et maintenir la documentation |
| kp-ux-ui | `/kp-agents:kp-ux-ui` | Designer UX/UI et identité visuelle |
| kp-setup | `/kp-agents:kp-setup` | Configurer les sources du projet |
| kp-daily | `/kp-agents:kp-daily` | Daily synthétique en français |
| kp-test | `/kp-agents:kp-test` | Orchestrer les tests E2E (cas Xray + test + remontée) |

Pour Cursor : `@kp-<nom>` via le sélecteur de règles. Pour Codex : skill auto-détectée `kp-<nom>`.
