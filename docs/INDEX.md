---
title: Index de la documentation
date: 2026-04-18
status: active
author: documentation-agent
---

# Index de la documentation

> Cartographie complète de `docs/` + documents racine du projet. Fichier maintenu par l'agent Documentation.
> Dernière mise à jour : 2026-04-18

## Documents racine du projet

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| README projet | `README.md` | Présentation publique, installation plugin + sync.sh, structure, troubleshooting | 2026-04-18 |
| Instructions Claude | `CLAUDE.md` | Règles de travail projet pour les agents IA (structure, flags, workflow) | 2026-04-18 |
| CHANGELOG | `CHANGELOG.md` | Historique des releases du plugin `kp-agents` (semver) | 2026-04-18 |

## Documents principaux

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Vision produit | `docs/product.md` | Vision, personas, valeur, règles métier, parcours, KPIs (7 agents `kp-agents`) | 2026-04-18 |
| Architecture | `docs/architect.md` | Stack, ADR (4), diagrammes, contrats de fichiers plugin Claude Code | 2026-04-18 |
| Guide des agents | `docs/agents.md` | Description et workflows des 7 agents génériques (schémas Mermaid, namespaces `/kp-agents:<nom>`) | 2026-04-18 |
| Review des agents | `docs/agents-review.md` | Audit des sources `agents/*.md` : forces, divergences, optimisations priorisées P1/P2/P3 | 2026-04-18 |

## Roadmap

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Roadmap | `docs/project/roadmap.md` | Phase 1 MUST ✅ DONE (migration plugin marketplace) + Phase 2 COULD en cours (2 epics actives : auto-bump v0.2.0 + optimisation agents) | 2026-04-18 |

## Epics actives

| ID | Titre | Statut | Stories (done/total) | Phase | Chemin |
|----|-------|--------|----------------------|-------|--------|
| E-0002 | Auto-bump de version du plugin kp-agents | ready | 0/3 | 2 | `docs/project/epics/E-0002-Auto-Bump-Version/` |
| E-0003 | Optimisation des agents selon best practices | ready | 0/8 | 2 | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/` |

### Stories de E-0002 (Auto-bump de version)

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Auto-bump patch à chaque sync | TODO | `docs/project/epics/E-0002-Auto-Bump-Version/S-0001-Auto-Bump-Patch.md` |
| S-0002 | Flags `--minor` et `--major` + respect du bump manuel | TODO | `docs/project/epics/E-0002-Auto-Bump-Version/S-0002-Flags-Minor-Major.md` |
| S-0003 | ADR-005 et consolidation documentaire | TODO | `docs/project/epics/E-0002-Auto-Bump-Version/S-0003-ADR-Documentation.md` |

### Stories de E-0003 (Optimisation des agents)

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Factorisation des blocs partagés via includes | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0001-Factorisation-Includes-Partages.md` |
| S-0002 | Réécriture des descriptions en phrasing impératif | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0002-Descriptions-Imperatives.md` |
| S-0003 | Ajout des sections Gotchas par agent | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0003-Sections-Gotchas.md` |
| S-0004 | Refonte de l'agent product | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0004-Refonte-Product.md` |
| S-0005 | Refonte de l'agent developer | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0005-Refonte-Developer.md` |
| S-0006 | Nettoyage ciblé des agents restants | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0006-Nettoyage-Agents-Restants.md` |
| S-0007 | Mise en place de la structure d'évaluation | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0007-Structure-Evals.md` |
| S-0008 | Release kp-agents-v0.2.0 | TODO | `docs/project/epics/E-0003-Optimisation-Agents-Best-Practices/S-0008-Release-V02.md` |

## Features

Aucun groupe de features documenté à ce stade. Le projet kp-agents étant lui-même un outil de distribution, les fonctionnalités sont consolidées dans `docs/product.md` et `docs/architect.md` plutôt qu'en groupes distincts.

## Idées

| Thème | Statut | Chemin | Notes |
|-------|--------|--------|-------|
| Plugin Claude Code | qualified | `docs/ideas/plugin-claude-code.md` | Spike GO validé le 2026-04-17. A donné naissance à l'epic E-0001, désormais archivée |

## Epics archivées

| ID | Titre | Statut | Stories | Clôturée le | Chemin |
|----|-------|--------|---------|-------------|--------|
| E-0001 | Migration en marketplace Claude Code | done | 3/3 (S-0001, S-0002, S-0003) | 2026-04-18 | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/` |

### Stories de E-0001 (archivées avec l'epic)

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Refonte sync.sh pour générer le plugin kp-agents | DONE | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/S-0001-Refonte-Sync.md` |
| S-0002 | Mise à jour de la documentation projet | DONE | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/S-0002-Mise-A-Jour-Documentation.md` |
| S-0003 | Release kp-agents-v0.1.0 et validation end-to-end | DONE | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/S-0003-Release-V01.md` |

## État documentaire

- ✅ Documents racine (`README.md`, `CLAUDE.md`, `CHANGELOG.md`) : à jour sur l'architecture marketplace + plugin `kp-agents`
- ✅ Documents principaux (`product.md`, `architect.md`, `agents.md`, `agents-review.md`) : alignés sur le périmètre "1 plugin `kp-agents` (7 agents génériques)"
- ✅ Roadmap : Phase 1 clôturée avec tous les critères de sortie validés ; Phase 2 active avec 2 epics en cours (E-0002 Auto-bump, E-0003 Optimisation agents)
- ✅ Epic E-0001 : clôturée, archivée, traçabilité préservée dans `_archives/`
- 🔄 Epic E-0002 : cadrée le 2026-04-18 (0/3 stories DONE). Règle métier RM-4 → chaque story modifie la documentation au fil de l'eau, l'INDEX sera donc re-synchronisé après chaque story DONE.
- 🔄 Epic E-0003 : cadrée le 2026-04-18 (0/8 stories DONE). S'appuie sur `docs/agents-review.md`.
- ℹ️ Backlog Phase 2 vide : deux epics initialement envisagées (CI de cohérence `agents/` ↔ `plugins/`, premier plugin métier — anciennement numérotées E-0003 et E-0004 avant renumérotation de l'epic Optimisation) ont été **retirées du périmètre le 2026-04-18**. Un nouveau cadrage via `/kp-agents:product` est requis si un besoin émerge. Note : le numéro `E-0003` désigne désormais l'epic Optimisation active ci-dessus.
- ✅ Idée `plugin-claude-code.md` : statut `qualified`, archive du raisonnement ayant mené à la release v0.1.0

## Conventions maintenues ici

- Toute création / modification / suppression de document dans `docs/` doit déclencher une mise à jour de cet index (propriété de l'agent Documentation)
- Les autres agents consultent l'index mais ne le modifient pas
- Un renommage ou déplacement de fichier = mise à jour simultanée de l'index
- `README.md`, `CLAUDE.md` et `CHANGELOG.md` (racine) figurent systématiquement dans la section "Documents racine du projet"
- Les epics dont toutes les stories sont `DONE` sont archivées dans `docs/project/epics/_archives/` — leur ligne reste visible ici dans "Epics archivées"
- Quand une epic a la règle métier "doc tenue à jour au fil de l'eau" (ex: E-0002 RM-4), cet index est re-synchronisé après chaque story passant à DONE pour refléter l'état réel
