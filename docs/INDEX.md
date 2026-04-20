---
title: Index de la documentation
date: 2026-04-20
status: active
author: documentation-agent
---

# Index de la documentation

> Cartographie complète de `docs/` + documents racine du projet. Fichier maintenu par l'agent Documentation.
> Dernière mise à jour : 2026-04-20

## Documents racine du projet

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| README projet | `README.md` | Présentation publique, installation plugin + sync.sh, structure, troubleshooting | 2026-04-18 |
| Instructions Claude | `CLAUDE.md` | Règles de travail projet pour les agents IA (structure, flags, workflow) | 2026-04-20 |
| CHANGELOG | `CHANGELOG.md` | Historique des releases du plugin `kp-agents` (semver, dernière entrée v0.2.0) | 2026-04-18 |

## Documents principaux

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Vision produit | `docs/product.md` | Vision, personas, valeur, règles métier, parcours, KPIs (7 agents `kp-agents`) | 2026-04-18 |
| Architecture | `docs/architect.md` | Stack, ADR (4), diagrammes, contrats de fichiers plugin Claude Code | 2026-04-18 |
| Guide des agents | `docs/agents.md` | Description et workflows des 7 agents génériques (schémas Mermaid, namespaces `/kp-agents:<nom>`) | 2026-04-18 |
| Review des agents | `docs/agents-review.md` | Audit des sources `agents/*.md` : forces, divergences, optimisations P1/P2/P3, bilan post-refactor | 2026-04-20 |

## Roadmap

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Roadmap | `docs/project/roadmap.md` | Phase 1 ✅ DONE + Phase 2 ✅ DONE. Toutes les epics archivées. Pas de backlog actif. | 2026-04-20 |

## Epics actives

Aucune. Toutes les epics sont archivées (voir ci-dessous).

## Features

Aucun groupe de features documenté à ce stade. Le projet kp-agents étant lui-même un outil de distribution, les fonctionnalités sont consolidées dans `docs/product.md` et `docs/architect.md` plutôt qu'en groupes distincts.

## Idées

| Thème | Statut | Chemin | Notes |
|-------|--------|--------|-------|
| Plugin Claude Code | qualified | `docs/ideas/plugin-claude-code.md` | Spike GO validé le 2026-04-17. A donné naissance à l'epic E-0001, désormais archivée |

## Epics archivées

| ID | Titre | Statut | Stories | Clôturée le | Chemin |
|----|-------|--------|---------|-------------|--------|
| E-0001 | Migration en marketplace Claude Code | done | 3/3 | 2026-04-18 | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/` |
| E-0002 | Auto-bump de version du plugin kp-agents | done | 3/3 | 2026-04-20 | `docs/project/epics/_archives/E-0002-Auto-Bump-Version/` |
| E-0003 | Optimisation des agents selon best practices | done | 8/8 | 2026-04-18 | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/` |

### Stories de E-0001 (archivées avec l'epic)

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Refonte sync.sh pour générer le plugin kp-agents | DONE | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/S-0001-Refonte-Sync.md` |
| S-0002 | Mise à jour de la documentation projet | DONE | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/S-0002-Mise-A-Jour-Documentation.md` |
| S-0003 | Release kp-agents-v0.1.0 et validation end-to-end | DONE | `docs/project/epics/_archives/E-0001-Plugin-Marketplace/S-0003-Release-V01.md` |

### Stories de E-0002 (archivées avec l'epic)

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Auto-bump patch à chaque sync | DONE | `docs/project/epics/_archives/E-0002-Auto-Bump-Version/S-0001-Auto-Bump-Patch.md` |
| S-0002 | Flags `--minor` et `--major` + respect du bump manuel | DONE | `docs/project/epics/_archives/E-0002-Auto-Bump-Version/S-0002-Flags-Minor-Major.md` |
| S-0003 | ADR-005 et consolidation documentaire | DONE | `docs/project/epics/_archives/E-0002-Auto-Bump-Version/S-0003-ADR-Documentation.md` |

### Stories de E-0003 (archivées avec l'epic)

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Factorisation des blocs partagés via includes | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0001-Factorisation-Includes-Partages.md` |
| S-0002 | Réécriture des descriptions en phrasing impératif | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0002-Descriptions-Imperatives.md` |
| S-0003 | Ajout des sections Gotchas par agent | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0003-Sections-Gotchas.md` |
| S-0004 | Refonte de l'agent product | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0004-Refonte-Product.md` |
| S-0005 | Refonte de l'agent developer | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0005-Refonte-Developer.md` |
| S-0006 | Nettoyage ciblé des agents restants | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0006-Nettoyage-Agents-Restants.md` |
| S-0007 | Mise en place de la structure d'évaluation | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0007-Structure-Evals.md` (scaffolding retiré le 2026-04-20) |
| S-0008 | Release kp-agents-v0.2.0 | DONE | `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/S-0008-Release-V02.md` |

## État documentaire

- ✅ Documents racine (`README.md`, `CLAUDE.md`, `CHANGELOG.md`) : à jour
- ✅ Documents principaux : alignés sur la marketplace `kp-agents` (7 agents)
- ✅ Roadmap : Phase 1 et Phase 2 closes, backlog vide
- ✅ Toutes les epics (E-0001, E-0002, E-0003) sont archivées
- ❌ Scaffolding `agents/_evals/` : retiré le 2026-04-20 (aucun runner, non directement utilisable). Cf. `docs/agents-review.md` § « Mise à jour post-refactor » et « Reliquats non traités »
- ℹ️ Une future phase sera ouverte à partir d'un besoin concret via `/kp-agents:brainstorm` puis `/kp-agents:product`

## Conventions maintenues ici

- Toute création / modification / suppression de document dans `docs/` doit déclencher une mise à jour de cet index (propriété de l'agent Documentation)
- Les autres agents consultent l'index mais ne le modifient pas
- `README.md`, `CLAUDE.md` et `CHANGELOG.md` (racine) figurent systématiquement dans la section "Documents racine du projet"
- Les epics dont toutes les stories sont `DONE` sont archivées dans `docs/project/epics/_archives/` — leur ligne reste visible ici dans "Epics archivées"
