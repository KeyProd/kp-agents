# kp-agents — Instructions pour les agents (Codex / autres)

## Principe fondamental

Ce projet est un **catalogue d'agents IA distribué sur 3 outils**.
Il n'y a **plus de génération ni de templating** : chaque outil a son dossier dédié, au format qu'il attend directement. Le contenu de chaque agent est **écrit à plat et dupliqué** dans les 3 dossiers.

```
claude/   ← plugin Claude Code : skills uniquement (skills/)
codex/    ← skills Codex (monolithiques par rôle)
cursor/   ← règles Cursor (.mdc, monolithiques par rôle)
```

**Modèle 100 % skills (côté Claude)** : pas de subagent. Un rôle = une **skill** (`claude/skills/kp-<role>/`), invocable `/kp-agents:kp-<role>`. Ce qui est **transverse à plusieurs rôles** vit dans une skill partagée chargée via l'outil `Skill` (`kp-sources-config`, `kp-docs-structure`, `kp-handoff`, `kp-doc-templates`, `kp-validation-criteres`) ; ce qui est **propre à un rôle** vit dans ses `references/*.md`, lus à la demande.

⚠️ **Asymétrie assumée** : `codex/` et `cursor/` n'ont pas de mécanisme de sous-fichiers → leur contenu est **entièrement inliné, monolithique par rôle**.

Modifier un rôle = éditer sa skill (`claude/`) **et** ses équivalents `codex/` / `cursor/`. Pas de `sync.sh` qui régénère : il se contente d'**installer** Cursor et Codex sur la machine locale.

## Distribution

- **Claude Code** → plugin marketplace (`claude/`, commité dans git). Le catalogue racine `.claude-plugin/marketplace.json` pointe sur `./` (le repo entier est le plugin). Installation : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`. Invocation : `/kp-agents:<nom>`
- **Cursor** → règles copiées par `sync.sh` dans `~/.cursor/rules/kp-*.mdc`
- **Codex** → skills copiées par `sync.sh` dans `~/.codex/skills/kp-*/`

## Structure du projet

```
.claude-plugin/
  marketplace.json   ← Catalogue marketplace (source: ./ → le repo entier est le plugin)
  plugin.json        ← Manifeste plugin : name, version (manuelle), skills[] → ./claude/skills/
claude/              ← Contenu du plugin Claude Code (référencé par plugin.json)
  skills/kp-<role>/            ← Skill de rôle (10) — persona + méthode + routage
    SKILL.md         ← frontmatter name + description (déclencheurs), puis le corps
    references/*.md   ← Procédures et gabarits propres au rôle, lus à la demande
  skills/kp-<partagée>/        ← Skill partagée (5) — chargée par les rôles via l'outil Skill
codex/               ← Skills Codex (monolithiques par rôle, tout inliné)
  kp-<nom>/
    SKILL.md         ← Skill (frontmatter name + description + metadata)
    agents/openai.yaml   ← Interface Codex (display_name, default_prompt, policy)
cursor/              ← Règles Cursor
  kp-<nom>.mdc       ← Règle (frontmatter description + alwaysApply), tout inliné
sync.sh              ← Installe cursor/ → ~/.cursor/rules et codex/ → ~/.codex/skills (macOS)
.githooks/pre-commit ← Vérifie le bump de version quand un skill change
docs/                ← Documentation projet (vision, architecture, epics, stories)
.kp-context.yml      ← OPTIONNEL — carte de contexte du projet
```

## Format par cible

### Codex (`codex/kp-<nom>/`)
- `SKILL.md` — frontmatter `name`, `description`, `metadata.short-description`, puis le corps inliné (pas de sous-dossier `references/` : tout est dans le SKILL.md).
- `agents/openai.yaml` — `interface` (`display_name`, `short_description`, `default_prompt`) + `policy.allow_implicit_invocation`.

### Claude (`claude/skills/kp-<nom>/`)
- `SKILL.md` — frontmatter `name` + `description` (orientée déclenchement), puis persona + méthode + routage.
- `references/*.md` — procédures et gabarits propres au rôle, markdown nu, chargés à la demande via `Read`.

### Cursor (`cursor/kp-<nom>.mdc`)
- Frontmatter `description` + `alwaysApply: false`, puis le corps inliné.

### Convention d'inlining (Codex et Cursor)
Fichier unique : pas de skill partagée ni de `references/`. Le contenu chargé à la demande côté Claude est rassemblé en fin de fichier sous `# Annexes`, un bloc `## Annexe — <nom>` par skill partagée ou procédure, **une seule occurrence chacun**. Le corps renvoie sous la forme `annexe « <nom> »` ; une skill partagée non inlinée est reformulée en clair. Ne jamais insérer un bloc au milieu d'une phrase ou d'une cellule de tableau.

## Ajouter ou modifier un agent

1. Éditer le contenu dans les **3 dossiers** (`claude/skills/kp-<nom>/`, `codex/kp-<nom>/`, `cursor/kp-<nom>.mdc`) en respectant le format de chacun.
2. Pour un **nouvel** agent : créer `claude/skills/kp-<nom>/SKILL.md` (le manifeste pointe le dossier `./claude/skills/`, rien à déclarer), `codex/kp-<nom>/agents/openai.yaml` et, si besoin, les `references/` côté Claude.
3. **Monter la version** dans `.claude-plugin/plugin.json` (patch / minor / major) + mettre à jour `CHANGELOG.md`.
4. Lancer `./sync.sh` pour installer Cursor + Codex en local.
5. `git add` + commit (le hook de pré-commit vérifie le bump) + tag `kp-agents-v<X.Y.Z>` + push.

Le préfixe `kp-` est obligatoire dans le nom de fichier ET dans le frontmatter `name:`.

## Règles critiques

- **Toute modification d'agent doit être répliquée dans les 3 dossiers.** Le contenu est dupliqué par design ; ce qui est en `references/` côté Claude est **inliné** côté Codex / Cursor.
- **Pas de subagent** : ne jamais recréer `claude/agents/` ni de champ `agents[]` dans `plugin.json`.
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
