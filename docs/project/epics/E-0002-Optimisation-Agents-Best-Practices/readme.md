---
title: Optimisation des agents selon best practices
date: 2026-04-18
status: ready
author: product-agent
epic-id: E-0002
phase: 2
---

# E-0002 - Optimisation des agents selon best practices

## Résumé

Optimiser les 7 agents sources (`agents/*.md`) pour améliorer leur cohérence, leur taux de déclenchement en *progressive disclosure* et leur valeur ajoutée, sans modifier leur objectif fonctionnel. Les modifications s'appuient sur l'audit réalisé dans [`docs/agents-review.md`](../../../agents-review.md) — recommandations P1/P2/P3 internes + B1-B7 issues des guides [agentskills.io](https://agentskills.io/skill-creation/).

## Objectif

- Homogénéiser les blocs répétés (activation, dépendances) via des includes partagés — source de vérité unique.
- Rendre les descriptions (frontmatter `description`) impératives + pushy pour améliorer le déclenchement Claude Code.
- Capturer la connaissance projet via des sections `## Gotchas` par agent.
- Réduire les redondances et le contenu générique qui encombrent les SKILL.md compilés.
- Poser les fondations d'une évaluation objective (structure `agents/_evals/`).
- Publier la release `kp-agents-v0.2.0`.

## Problème adressé

- **Incohérence** : bloc "Activation et persistance" dupliqué sur 4 agents, tronqué sur 3 (review, ux-ui partiellement).
- **Sous-déclenchement potentiel** : descriptions descriptives ("X: do Y") au lieu d'impératives ("Use when..."), sans triggers explicites ni near-miss exclusions.
- **Duplication silencieuse** : templates d'epic/story inline dans `product.md` alors que les includes existent déjà → risque de divergence.
- **Contenu générique** : conseils que le modèle possède déjà (ex: "écris du code propre"), occupant de la place sans valeur ajoutée.
- **Pas de gotchas** : les erreurs projet-spécifiques observées (pas de worktree, pas de `/` pour review qui modifie du code, etc.) ne sont pas capturées dans un emplacement dédié.
- **Pas de mesure** : aucun dispositif pour évaluer objectivement l'effet des modifications.

## Résultat attendu

- Les 7 agents partagent un bloc "Activation" **identique** issu de `includes/activation.md`.
- Les 7 descriptions suivent le patron impératif + triggers explicites (< 1024 caractères).
- Chaque agent possède une section `## Gotchas` de 5 à 10 items ancrés dans la pratique projet.
- `agents/product.md` n'a plus de templates inline : il référence les includes existants.
- `agents/developer.md` : étapes 6 et 7 fusionnées, portabilité multi-cibles de la simplification.
- Structure `agents/_evals/` créée avec ~20 queries pilotes pour 2 agents (preuve de concept, pas de run).
- Release `kp-agents-v0.2.0` publiée, `CHANGELOG.md` et `docs/agents.md` mis à jour si impactés.

## Périmètre

### Inclus

- Modifications des 7 fichiers dans `agents/` (source de vérité).
- Création de nouveaux fichiers dans `includes/` : `activation.md`, `dependency-versions.md`, éventuellement `index-template.md`.
- Régénération via `sync.sh` (plugin + dist Cursor/Codex).
- Mise à jour du `CHANGELOG.md` et bump de `plugins/kp-agents/.claude-plugin/plugin.json` (0.1.0 → 0.2.0).
- Structure `agents/_evals/` (ignorée par `sync.sh`) + trigger queries pour 2 agents pilotes (à choisir : `developer` et `review` recommandés — cas les plus discriminants).

### Exclu

- **Exécution** des evals (nécessite configuration API / baseline sans skill) — B6 se limite à la structure et aux données.
- **Refonte** des workflows inter-agents décrits dans `docs/agents.md` (schémas Mermaid inchangés).
- **Pivot d'objectif** d'un agent : aucun changement de périmètre fonctionnel.
- **Nouveaux agents** ou suppression d'agents existants.
- **Refonte** de `sync.sh` (au-delà de l'éventuel support de fichiers référence externes, reporté).
- **Modification** du mécanisme de distribution (marketplace Claude Code, Cursor rules, Codex skills).

## Règles métier concernées

- La source de vérité reste exclusivement `agents/` — aucune modification manuelle dans `plugins/kp-agents/skills/` ou `dist/`.
- Le bump `plugin.json` suit le semver : modifications de comportement des agents = bump **mineur** (0.1.0 → 0.2.0).
- `sync.sh` doit être rejoué et validé après chaque story qui modifie `agents/` ou `includes/`.
- Toute nouvelle convention doit être répercutée dans `CLAUDE.md` (via l'agent Documentation) si elle change les règles projet.

## Dépendances

- Epic E-0001 (plugin marketplace) : **archivée**, aucune dépendance bloquante.
- `docs/agents-review.md` : source de l'analyse, doit rester stable pendant l'epic.
- Accès en écriture au repo GitHub pour publier la release (cf. S-0008).

## Risques / inconnues

- **R1** — Les descriptions impératives proposées (anglais) peuvent être sur-dimensionnées pour les cibles Cursor/Codex. Atténuation : vérifier les artefacts générés après chaque modification, ajuster si nécessaire.
- **R2** — L'ajout massif de `## Gotchas` peut faire grossir les SKILL.md compilés au-delà du confort (guide agentskills.io : < 500 lignes). Atténuation : cap à 10 items par agent, refuser les gotchas génériques.
- **R3** — La factorisation via includes suppose que `sync.sh` résout déjà `{{include:activation}}`. **Hypothèse à vérifier** : la logique de `sync.sh` est générique sur le nom d'include ou whitelistée ?
- **R4** — Les utilisateurs installés du plugin en v0.1.0 ne verront les changements qu'après `/plugin marketplace update`. Pas bloquant mais à mentionner dans le CHANGELOG.

## Stories

- [S-0001 - Factorisation des blocs partagés via includes](S-0001-Factorisation-Includes-Partages.md) — T1 + T3 → `includes/activation.md` + `includes/dependency-versions.md`, appliqués aux 7 agents.
- [S-0002 - Réécriture des descriptions en phrasing impératif](S-0002-Descriptions-Imperatives.md) — B1 → les 7 champs `description` du frontmatter.
- [S-0003 - Ajout des sections Gotchas par agent](S-0003-Sections-Gotchas.md) — B2 → une section `## Gotchas` (5–10 items) dans chaque agent.
- [S-0004 - Refonte de l'agent product](S-0004-Refonte-Product.md) — O2.1 + O2.2 + O2.3 : templates inline → includes, déplacement mode init, nettoyage règles.
- [S-0005 - Refonte de l'agent developer](S-0005-Refonte-Developer.md) — O4.1 + O4.2 + B5 : fusion étapes 6/7, portabilité simplification, exemple "Validation par critère".
- [S-0006 - Nettoyage ciblé des agents restants](S-0006-Nettoyage-Agents-Restants.md) — B3/B4 + O1.1 + O3.2 + O5.2 + O6.1 + O6.2 + O7.2 : brainstorm (menu→défaut), architect (fusion), review (étape 2), documentation (template index, dédoublonnage), ux-ui (mini-template).
- [S-0007 - Mise en place de la structure d'évaluation](S-0007-Structure-Evals.md) — B6 → `agents/_evals/` + trigger queries pour 2 agents pilotes + exclusion `sync.sh`.
- [S-0008 - Release kp-agents-v0.2.0](S-0008-Release-V02.md) — bump semver, CHANGELOG, tag, push, validation end-to-end.

## Critères de succès

- Les 7 agents sont cohérents : même bloc Activation, même format de description (impératif + triggers), même structure Gotchas.
- `sync.sh` s'exécute sans erreur après chaque story impactante ; les artefacts `plugins/kp-agents/skills/` et `dist/` sont à jour et versionnés.
- Aucune régression fonctionnelle : les invocations `/kp-agents:<nom>` continuent de produire les livrables attendus (vérifié manuellement sur au moins 2 agents).
- `plugin.json` est bumpé en `0.2.0`, taggé, pushé.
- `CHANGELOG.md` décrit la release avec les 3 grandes catégories de changements (cohérence, descriptions, gotchas).
- `agents/_evals/` contient la structure et les queries pilotes pour au moins 2 agents (documentation `agents/_evals/README.md` expliquant comment les exécuter quand l'équipe aura les moyens).
- Aucune modification dans `plugins/kp-agents/skills/` ou `dist/` n'a été commitée sans passer par `agents/` + `sync.sh`.
