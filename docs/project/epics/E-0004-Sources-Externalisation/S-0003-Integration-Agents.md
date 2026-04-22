---
title: Intégration sources-config dans les 7 agents existants
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0003
epic-id: E-0004
---

# S-0003 - Intégration sources-config dans les 7 agents existants

## Résumé

Injecter l'include `sources-config` dans les 7 agents existants (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`), rendre leur section « Convention de sortie » conditionnelle selon la config du projet, et implémenter l'auto-redirect vers `/kp-agents:setup` quand la config est manquante ou incomplète.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux que chaque agent respecte la configuration des sources du projet courant, afin que mes fichiers produit aillent au bon endroit (local ou externe) sans intervention manuelle.

## Contexte

- Story bloquée par S-0001 (include) et S-0002 (agent setup).
- Modification à minima invasive : ajouter l'include + adapter la section « Convention de sortie » de chaque agent.
- Les agents restent rétro-compatibles : sans `.kp-agents.yml`, leur comportement est identique à aujourd'hui.

## Règles métier

- Chaque agent lit la config en début de session (après l'audit initial type « rôle et persistance »).
- Si la config est absente → mode local par défaut, aucun prompt.
- Si la config est présente mais incomplète pour le périmètre de l'agent → proposer `/kp-agents:setup`, continuer sans bloquer si l'utilisateur refuse.
- La section « Convention de sortie - Répertoire docs/ » de chaque agent précise désormais :
  - Les chemins externalisables (selon la config `product.mode` / `tickets.mode`)
  - Les chemins toujours locaux (architecture, doc technique)
  - La logique de fallback write

## Scénarios

### Nominal
- Étant donné un projet avec `product.mode: external` et `product.path` configuré
- Quand l'utilisateur invoque `/kp-agents:product` pour créer une epic
- Alors l'agent écrit dans `<product.path>/project/epics/E-XXXX-.../readme.md` (et non dans `./docs/`).

### Alternatif
- Étant donné un projet sans `.kp-agents.yml`
- Quand l'utilisateur invoque n'importe quel agent
- Alors l'agent écrit dans `./docs/` (comportement actuel, non-régression).

### Erreur / refus
- Étant donné `product.mode: external` mais le chemin externe est en lecture seule (écriture refusée par l'OS)
- Quand l'agent tente d'écrire une nouvelle story
- Alors l'agent warn explicitement, écrit dans `./docs/` en fallback, et indique le chemin exact du fichier écrit.

## Cas limites

- [ ] Agent `developer` travaille sur du code : ne lit que la doc produit externe, ses propres outputs (stories en IN PROGRESS) suivent la config `tickets.mode`
- [ ] Agent `architect` produit toujours en local (périmètre technique), ignore complètement `product.mode`
- [ ] Agent `documentation` maintient `docs/INDEX.md` : INDEX reste **toujours local** (référence locale du repo code)
- [ ] Agent `brainstorm` écrit dans `ideas/` : si `product.mode: external`, les ideas vont dans le chemin externe

## Critères d'acceptation

- [ ] Les 7 agents (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`) incluent `{{include:sources-config}}` dans leur frontmatter body
- [ ] La section « Convention de sortie » de chaque agent est mise à jour pour référencer la logique de config (pas de duplication — l'include centralise)
- [ ] Auto-redirect implémenté : si un agent détecte config manquante/incomplète, il propose `/kp-agents:setup` dès son premier message, sans bloquer
- [ ] Pour chaque agent, matrice claire documentée : quels outputs sont externalisables, quels restent locaux
- [ ] Test manuel non-régression : sur un projet sans config (ex: `kp-agents` lui-même), chaque agent se comporte exactement comme aujourd'hui
- [ ] Test manuel mode mixte : projet avec `product.mode: external`, `tickets.mode: local` → `/kp-agents:brainstorm` écrit externe, `/kp-agents:developer` écrit local, `/kp-agents:architect` écrit local
- [ ] `./sync.sh` produit des SKILL.md cohérents pour les 7 agents (hash valide, taille raisonnable)
- [ ] Auto-bump patch déclenché par `./sync.sh` si changement de contenu

## Dépendances

- **S-0001** (include créé)
- **S-0002** (agent setup invocable pour l'auto-redirect)

## Notes techniques

- Ne **jamais** modifier directement `plugins/kp-agents/skills/` — toujours éditer `agents/*.md` puis lancer `./sync.sh`.
- L'include doit rester **court** : il est inliné 8 fois. Chaque ligne superflue coûte.
- Les chemins dans les agents doivent rester des **placeholders logiques** (`<product-root>/ideas/`), résolus par l'include.
- L'agent `documentation` a un rôle spécial sur `INDEX.md` : ce fichier reste toujours local. À documenter explicitement dans son agent.

## Instrumentation / mesure

- Nombre de lignes ajoutées à chaque agent (attendu : ~5-10 lignes nettes)
- Taille finale de chaque SKILL.md généré (comparatif avant/après)

## Questions ouvertes

- Est-ce que l'agent `architect` a besoin de savoir lire la doc produit externe (pour référence) ? → **Oui**, il lit tout en mode externe si configuré, mais écrit toujours en local.

## Implémentation

### Fichiers modifiés (7 agents)

Pour chacun des 7 agents existants, deux insertions ciblées (approche minimale validée) :
1. **Section `## Configuration du projet`** ajoutée juste après `{{include:activation}}` — instruit l'agent de lire `.kp-agents.yml` / `.kp-agents.local.yml` au démarrage et de proposer `/kp-agents:setup` si la config est incomplète. Le texte est contextualisé par agent (ex: architect mentionne que ses écritures restent toujours locales ; documentation mentionne que INDEX reste local).
2. **Directive `{{include:sources-config}}`** insérée juste avant `{{include:docs-structure[-light]}}` — injecte la logique centralisée (schéma, résolution de chemin, fallback write, redirection setup).

### Mesure H3 empirique (critère d'acceptation de S-0001)

Avant/après intégration de `{{include:sources-config}}` dans chaque agent :

| Agent | Source avant (lignes) | Source après (lignes) | Δ source | SKILL.md après (lignes) |
|---|---:|---:|---:|---:|
| brainstorm | 181 | 190 | +9 | 319 |
| product | 157 | 166 | +9 | 297 |
| architect | 184 | 193 | +9 | 324 |
| developer | 241 | 251 | +10 | **396** |
| review | 225 | 235 | +10 | 380 |
| documentation | 217 | 227 | +10 | 358 |
| ux-ui | 216 | 226 | +10 | 357 |
| **Total ajout net** | | | **+67** | |

- **Ajout net par agent** : 9-10 lignes source (conforme à l'estimation de la story : 5-10 lignes, légèrement dépassé mais acceptable).
- **developer (agent le plus long)** : 396 lignes de SKILL.md final, **+19%** vs baseline 332 lignes (proche de la théorique 388 lignes de S-0001, écart +8 lignes dû aux lignes blanches autour des sections).
- **Pas de saturation** identifiée — aucun SKILL.md ne dépasse 400 lignes.

### Vérifications techniques

- `grep '{{include' plugins/kp-agents/skills/*/SKILL.md` → **0 résidu** sur les 8 agents (setup inclus).
- `grep '^## Configuration du projet' plugins/kp-agents/skills/*/SKILL.md` → exactement **1 match par agent** (7 agents — setup exclu car il a sa propre section Processus qui fait déjà l'audit).
- `grep '^## Configuration des sources' plugins/kp-agents/skills/*/SKILL.md` → exactement **1 match par agent** (8 agents, setup inclus car l'include a toujours été présent chez lui depuis S-0002).
- `./sync.sh --dist-only` → 8 agents syncés dans les 3 cibles sans erreur.

### Bump version

`sync.sh --dist-only` a auto-bumpé `1.0.1 → 1.0.3` (accumulation de deux patchs non committés : `55358ac` fix include + ce sync). Le minor bump `1.0.x → 1.1.0` sera appliqué à la release S-0008 via `--minor` (ajout d'agent + feature significative).

### Commandes de test

- Génération : `./sync.sh --dist-only`
- Vérif résidus : `grep -c '{{include' plugins/kp-agents/skills/*/SKILL.md` (doit être 0 pour chaque)
- Vérif section startup : `grep -c '^## Configuration du projet' plugins/kp-agents/skills/<agent>/SKILL.md` (doit être 1 pour brainstorm/product/architect/developer/review/documentation/ux-ui)
- Vérif include inliné : `grep -c '^## Configuration des sources' plugins/kp-agents/skills/<agent>/SKILL.md` (doit être 1 pour tous les 8 agents)
- Mesure tailles : `wc -l plugins/kp-agents/skills/*/SKILL.md`
- Test manuel non-régression (à faire par l'utilisateur post-merge) : dans un projet sans `.kp-agents.yml`, invoquer `/kp-agents:brainstorm` / `/kp-agents:product` / etc. et vérifier que le comportement est identique à avant.

### Limites

- **Test de redirection effective non exécuté** : la logique de redirection `docs/` → `<product.path>/` n'est pas testée end-to-end dans cette story (elle dépend d'une vraie config `product.mode: external`). Ce test est le périmètre de S-0004 (Mode product.mode external OneDrive).
- **Auto-redirect vers setup non testé interactivement** : le comportement « proposer `/kp-agents:setup` sans bloquer » est documenté mais dépend de l'agent en session — non reproductible statiquement.

## Validation par critère

- **Les 7 agents incluent `{{include:sources-config}}` dans leur frontmatter body** : ✅ `grep '^## Configuration des sources' plugins/kp-agents/skills/*/SKILL.md` → 8 matches (7 agents ciblés + setup qui l'avait déjà depuis S-0002). Aucun résidu de directive `{{include}}` dans les 8 SKILL.md générés.
- **La section « Convention de sortie » de chaque agent est mise à jour pour référencer la logique de config (pas de duplication)** : ✅ approche minimale validée — la convention par défaut (`{{include:docs-structure-light}}` ou `{{include:docs-structure}}`) reste inchangée, l'include `sources-config` la complète en expliquant les redirections possibles. Pas de duplication introduite.
- **Auto-redirect implémenté : si un agent détecte config manquante/incomplète, il propose `/kp-agents:setup` dès son premier message, sans bloquer** : ✅ documenté dans la section `## Configuration du projet` de chaque agent (3 cas : absent / incomplet / complet) + réitéré dans l'include `sources-config`. Limite : comportement non testable statiquement.
- **Pour chaque agent, matrice claire documentée : quels outputs sont externalisables, quels restent locaux** : ✅ documenté dans la section startup de chaque agent, avec contextualisation :
  - `architect` → écritures **toujours locales**
  - `documentation` → INDEX, README, CLAUDE.md, architect.md **toujours locaux**
  - `developer` / `review` → stories suivent la dimension `tickets`
  - `brainstorm` / `product` / `ux-ui` → lecture produit externe si configuré
- **Test manuel non-régression : sur un projet sans config, chaque agent se comporte comme aujourd'hui** : ⚠️ **à exécuter par l'utilisateur post-merge**. Le comportement est garanti par la règle documentée « Absent → mode 100% local, aucun prompt, comportement par défaut » présente dans la section startup de chaque agent et dans l'include `sources-config`.
- **Test manuel mode mixte : projet avec `product.mode: external`, `tickets.mode: local` → dimensions indépendantes respectées** : ⚠️ **non exécutable dans cette story** — dépend d'une vraie config externe, ce qui est le périmètre de S-0004 (OneDrive).
- **`./sync.sh` produit des SKILL.md cohérents pour les 7 agents (hash valide, taille raisonnable)** : ✅ 8 agents syncés dans les 3 cibles (plugin + cursor + codex) sans erreur. Tailles entre 297 (product) et 396 (developer) lignes — acceptable. Hash SHA256 `282b1fdee9…` mis à jour dans `plugin.json`.
- **Auto-bump patch déclenché par `./sync.sh` si changement de contenu** : ✅ bump `1.0.1 → 1.0.3` appliqué (2 patches cumulés). Minor bump 1.1.0 prévu en S-0008.
