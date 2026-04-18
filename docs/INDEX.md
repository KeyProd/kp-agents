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
| Roadmap | `docs/project/roadmap.md` | Phase 1 MUST ✅ DONE (migration plugin marketplace) + Phase 2 COULD (backlog hygiène/extensibilité) | 2026-04-18 |

## Epics actives

Aucune epic active à ce jour. L'epic E-0001 a été clôturée le 2026-04-18 et archivée (voir section "Epics archivées").

Prochaines epics potentielles (backlog qualifié, non priorisé, voir roadmap) :

- **E-0002** — Auto-bump de version via hash des skills
- **E-0003** — CI : check de cohérence `agents/` ↔ `plugins/`
- **E-0004** — Premier plugin métier spécifique

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
- ✅ Documents principaux (`product.md`, `architect.md`, `agents.md`) : alignés sur le périmètre "1 plugin `kp-agents` (7 agents génériques)"
- ✅ Roadmap : Phase 1 clôturée avec tous les critères de sortie validés, Phase 2 recadrée en backlog de hygiène/extensibilité
- ✅ Epic E-0001 : clôturée, archivée, traçabilité préservée dans `_archives/`
- ✅ Idée `plugin-claude-code.md` : statut `qualified`, archive du raisonnement ayant mené à la release v0.1.0

## Conventions maintenues ici

- Toute création / modification / suppression de document dans `docs/` doit déclencher une mise à jour de cet index (propriété de l'agent Documentation)
- Les autres agents consultent l'index mais ne le modifient pas
- Un renommage ou déplacement de fichier = mise à jour simultanée de l'index
- `README.md`, `CLAUDE.md` et `CHANGELOG.md` (racine) figurent systématiquement dans la section "Documents racine du projet"
- Les epics dont toutes les stories sont `DONE` sont archivées dans `docs/project/epics/_archives/` — leur ligne reste visible ici dans "Epics archivées"
