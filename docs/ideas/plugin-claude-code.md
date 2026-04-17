---
title: Rendre kp-agents installable comme plugin Claude Code
date: 2026-04-17
status: qualified
author: brainstorm-agent
---

# Rendre kp-agents installable comme plugin Claude Code

## Problème

Distribuer les agents `kp-*` nécessite aujourd'hui : clone du repo → `./sync.sh` → réinstallation à chaque mise à jour. Friction pour les nouveaux arrivants et pas de canal standardisé de distribution.

**Besoin** : installation en 1 commande + mise à jour native, tout en conservant la compatibilité Cursor/Codex fournie par `sync.sh`.

## Faits établis (doc officielle Claude Code)

Sources : [code.claude.com/docs/en/discover-plugins](https://code.claude.com/docs/en/discover-plugins), [code.claude.com/docs/en/plugins](https://code.claude.com/docs/en/plugins)

### Concept : marketplace ≠ plugin

- **Marketplace** = catalogue de plugins (un repo git avec `.claude-plugin/marketplace.json` à la racine)
- **Plugin** = item du catalogue (dossier avec `.claude-plugin/plugin.json` + skills/agents/hooks/etc.)
- Un repo git peut être une marketplace contenant 1 ou N plugins

### Installation utilisateur (flow type)

```
/plugin marketplace add https://gitlab.com/keyprod/kp-agents.git   # ajoute le catalogue
/plugin install kp-core@kp-agents                                  # installe un plugin du catalogue
/kp-core:brainstorm                                                # invocation namespacée
```

### Structure d'un plugin

```
<plugin-name>/
├── .claude-plugin/
│   └── plugin.json           # name, description, version, author
├── skills/
│   └── <skill-name>/
│       └── SKILL.md          # YAML frontmatter (description) + contenu
├── agents/                   # agents custom (subagents)
├── hooks/hooks.json
├── .mcp.json
└── settings.json
```

### Namespacing imposé

- Un plugin nommé `kp-core` expose ses skills sous `/kp-core:brainstorm`, pas `/kp-brainstorm`
- Les noms actuels `/kp-brainstorm` vont changer → point à acter avec l'utilisateur

### Format SKILL.md ≈ format Codex actuel

Le format `SKILL.md` (YAML frontmatter `description` + corps markdown) est quasi identique à ce que `sync.sh` produit déjà pour Codex dans `dist/codex/kp-*/SKILL.md`. **Gain potentiel : un même format source pour Claude-plugin ET Codex**.

## Hypothèses à confirmer

- **H1** ✅ confirmé : installation via URL git HTTPS publique supportée (`/plugin marketplace add https://...`)
- **H2** ✅ confirmé : slash commands actuels (`commands/*.md`) supportés mais **deprecated** → la norme moderne est `skills/<name>/SKILL.md`
- **H3** ✅ confirmé : le format plugin Claude ne couvre pas Cursor ni Codex → `sync.sh` reste nécessaire pour eux
- **H4** ✅ tranché : `sync.sh` n'installera plus Claude → seulement Cursor et Codex. Pas de cohabitation à gérer.
- **H5** à valider : accepter le changement de namespace `/kp-brainstorm` → `/kp-core:brainstorm` (ou similaire)

## Contraintes et décisions utilisateur

- **Distribution** : usage uniquement interne KeyProd, mais doit rester accessible à des **externes sans compte GitLab** → le repo marketplace doit être hébergé publiquement (GitLab public, miroir GitHub, ou hébergement git public self-hosted)
- **sync.sh après remaniement** : n'installe plus rien dans `~/.claude/commands/`. Seulement Cursor et Codex restent sync.sh-dépendants.
- **Organisation par branche** : *interprété* : une branche = un périmètre d'agents (à confirmer)
  - Branche `main` : les 7 agents génériques → plugin `kp-core`
  - Branche dédiée (nom à définir) : les 3 agents recettemoi (± les 7 génériques ?) → plugin `kp-recettemoi`

## Méthode choisie

Starbursting (inconnues cartographiées) → Exploration divergente (approches) → Analyse critique.

## Approches envisagées

### Approche retenue : B — Refonte native, avec split en 2 plugins

- **Hébergement** : GitLab KeyProd, visibilité publique (repo accessible sans authentification via HTTPS)
- **Marketplace** : 1 catalogue exposé par `.claude-plugin/marketplace.json` à la racine
- **Plugins** : 2 plugins **distincts et indépendants** pour maximiser l'extensibilité future
  - `kp-core` → 7 agents génériques (brainstorm, product, architect, developer, review, documentation, ux-ui)
  - `kp-recettemoi` → 3 agents RecetteMoi (support, dev, review)
  - Un utilisateur externe peut installer uniquement `kp-core`
  - Les deux plugins peuvent cohabiter sans conflit (namespaces distincts `kp-core:` vs `kp-recettemoi:`)
- **Namespacing** : `/kp-brainstorm` → `/kp-core:brainstorm`, `/kp-recettemoi-support` → `/kp-recettemoi:support`
- **sync.sh** : ne gère plus que Cursor et Codex (plus d'install Claude)

### Structure cible du repo

```
kp-agents/
├── .claude-plugin/
│   └── marketplace.json                    # catalogue : liste kp-core + kp-recettemoi
├── plugins/
│   ├── kp-core/
│   │   ├── .claude-plugin/plugin.json      # name: kp-core, version, author
│   │   └── skills/
│   │       ├── brainstorm/SKILL.md
│   │       ├── product/SKILL.md
│   │       └── ... (7 skills)
│   └── kp-recettemoi/
│       ├── .claude-plugin/plugin.json      # name: kp-recettemoi, version, author
│       └── skills/
│           ├── support/SKILL.md
│           ├── dev/SKILL.md
│           └── review/SKILL.md
├── agents/                                 # SOURCE de vérité (frontmatter + {{include:xxx}})
├── includes/                               # templates partagés inchangés
├── sync.sh                                 # génère plugins/ + dist/cursor/ + dist/codex/
└── dist/                                   # cursor/ + codex/ uniquement (plus de claude/)
```

## Recommandation

**Approche B (refonte native), avec 2 plugins distincts (`kp-core` et `kp-recettemoi`), publiée sur GitLab KeyProd en visibilité publique.** `agents/` reste la source de vérité (avec includes), `plugins/` devient une cible générée **et commitée**, `sync.sh` ne gère plus que Cursor et Codex.

**Principe de validation progressive** : un **spike** minimal (1 plugin, 1 skill, bout-en-bout) précède la migration des 10 agents. Coût du spike : 1-2h. Gain : élimination des risques `HC-1` (faisabilité end-to-end) et `HC-2` (visibilité publique GitLab) avant toute refonte massive.

### Critères de succès

- Un collègue sans contexte fait `/plugin marketplace add … && /plugin install kp-core@kp-agents` et utilise `/kp-core:brainstorm` en < 2 minutes
- Workflow de mise à jour agent : `edit agents/<nom>.md → ./sync.sh → git commit + tag → git push` en ≤ 5 étapes
- `sync.sh` reste sous 200 lignes après simplification
- Zéro duplication manuelle source → cibles

## Décision / Next steps

### Étape 1 — Spike de faisabilité (1 skill, bout-en-bout)

**Objectif** : valider en conditions réelles que le flow marketplace Claude Code + GitLab public fonctionne, **avant** toute refonte structurante.

Livrables du spike :
1. Créer la structure minimale à la racine : `.claude-plugin/marketplace.json` + `plugins/kp-core/.claude-plugin/plugin.json` + `plugins/kp-core/skills/brainstorm/SKILL.md` (contenu copié-collé du dist actuel)
2. Pousser sur une branche GitLab KeyProd en visibilité publique
3. Tester depuis un poste "vierge" : `/plugin marketplace add <url>` puis `/plugin install kp-core@kp-agents` puis `/kp-core:brainstorm`
4. Vérifier que le skill répond correctement et que le namespace est bien `kp-core:`

**Résultat attendu** : GO (on enchaîne sur l'étape 2) ou NO-GO (retour brainstorm pour explorer une variante).

### Étape 2 — Refonte structurante (si spike GO)

Sous forme d'une epic à structurer côté Architect puis Product :

1. **Structure repo** : ajouter `.claude-plugin/marketplace.json` + arborescence `plugins/kp-core/` et `plugins/kp-recettemoi/`
2. **sync.sh** : nouvelle cible "plugins" remplaçant la cible "claude" ; réécriture des générateurs ; mise à jour des flags `--clean` / `--clean-all` pour couvrir la nouvelle cible ; manifeste `.installed-agents` à reconsidérer (n'installant plus Claude)
3. **Migration des 7 agents génériques** → `plugins/kp-core/skills/<nom>/SKILL.md`
4. **Migration des 3 agents RecetteMoi** → `plugins/kp-recettemoi/skills/<nom>/SKILL.md`
5. **Versioning** : premier tag `v0.1.0` sur chaque `plugin.json`, stratégie semver à définir
6. **Documentation** : mise à jour README.md et CLAUDE.md ; adaptation de docs/agents.md (namespaces)
7. **CI** (optionnel mais recommandé) : check pre-commit ou CI vérifiant que `plugins/` est synchronisé avec `agents/`

### Étape 3 — Décommissionnement progressif de l'install Claude via sync.sh

- Retirer les blocs `generate_claude*` de sync.sh
- Nettoyer les dépendances au dossier `~/.claude/commands/` dans la doc
- Migration assistée pour les devs actuels : un message "lancez `/plugin install ...`" dans le sync.sh pendant une période de transition

### Points nécessitant validation externe

- **Validation technique d'architecture** : découpage sync.sh post-refonte, gestion de `plugins/` en git, stratégie de versioning → **agent Architect**
- **Cadrage produit** : découper les étapes 2 et 3 en epic + stories, prioriser les tâches, définir les critères d'acceptation → **agent Product** (après validation Architect)

### Relais recommandé

Passage direct à l'**agent Architect** pour :
- Formaliser la nouvelle structure `sync.sh` (algorithmes de génération des 3 cibles)
- Trancher les points techniques (manifeste, versioning, CI, pre-commit)
- Produire un `docs/architect.md` ou `docs/features/plugin/architect.md`

Passage à **Product** ensuite pour découper en epic + stories et prioriser les étapes de la refonte.

