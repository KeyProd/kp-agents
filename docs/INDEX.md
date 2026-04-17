---
title: Index de la documentation
date: 2026-04-17
status: active
author: documentation-agent
---

# Index de la documentation

> Cartographie complète de `docs/` + documents racine du projet. Fichier maintenu par l'agent Documentation.
> Dernière mise à jour : 2026-04-17

## Documents racine du projet

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| README projet | `README.md` | Présentation publique, usage, installation, structure. **À mettre à jour par la story S-0002** (retrait cible Claude local, namespaces `/kp-core:<nom>`, retrait recettemoi) | 2026-04-16 |
| Instructions Claude | `CLAUDE.md` | Règles de travail projet pour les agents IA. **À mettre à jour par la story S-0002** (structure `plugins/`, workflow semver, retrait recettemoi) | 2026-04-16 |

## Documents principaux

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Vision produit | `docs/product.md` | Vision, personas, valeur, règles métier, parcours, KPIs (7 agents `kp-core`) | 2026-04-17 |
| Architecture | `docs/architect.md` | Stack, ADR (4), diagrammes, contrats de fichiers plugin Claude Code, spike design | 2026-04-17 |
| Guide des agents | `docs/agents.md` | Description et workflows des agents (schémas Mermaid). **À mettre à jour par la story S-0002** (retrait section RecetteMoi, namespaces `/kp-core:<nom>`) | 2026-04-16 |

## Roadmap

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Roadmap | `docs/project/roadmap.md` | 2 phases : Phase 1 MUST (migration plugin marketplace), Phase 2 COULD (ouverture publique, hardening) | 2026-04-17 |

## Epics actives

| ID | Titre | Statut | Stories (done/total) | Phase | Chemin |
|----|-------|--------|----------------------|-------|--------|
| E-0001 | Migration en marketplace Claude Code | ready | 0/3 | 1 | `docs/project/epics/E-0001-Plugin-Marketplace/` |

### Stories de E-0001

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| S-0001 | Refonte sync.sh pour générer le plugin kp-core | TODO | `docs/project/epics/E-0001-Plugin-Marketplace/S-0001-Refonte-Sync.md` |
| S-0002 | Mise à jour de la documentation projet | TODO | `docs/project/epics/E-0001-Plugin-Marketplace/S-0002-Mise-A-Jour-Documentation.md` |
| S-0003 | Release kp-core-v0.1.0 et validation end-to-end | TODO | `docs/project/epics/E-0001-Plugin-Marketplace/S-0003-Release-V01.md` |

## Features

Aucun groupe de features documenté à ce stade. Le projet kp-agents étant lui-même un outil de distribution, les fonctionnalités sont consolidées dans `docs/product.md` et `docs/architect.md` plutôt qu'en groupes distincts.

## Idées

| Thème | Statut | Chemin | Notes |
|-------|--------|--------|-------|
| Plugin Claude Code | qualified | `docs/ideas/plugin-claude-code.md` | Spike GO validé le 2026-04-17. A donné naissance à l'epic E-0001 |

## Epics archivées

Aucune epic archivée à ce jour.

## État documentaire

- ✅ Documents principaux `product.md`, `architect.md` : à jour, périmètre "1 plugin `kp-core` (7 agents)"
- ✅ Roadmap et epic E-0001 : créés et alignés sur la décision architecture du 2026-04-17
- ⚠️ `README.md`, `CLAUDE.md`, `docs/agents.md` : mentionnent encore les agents RecetteMoi (supprimés le 2026-04-17) et la cible d'installation Claude locale (en cours de retrait). Mise à jour planifiée dans la story S-0002.
- ✅ Idée `plugin-claude-code.md` : statut `qualified`, documente le spike GO et le scope reduction (retrait recettemoi)

## Conventions maintenues ici

- Toute création / modification / suppression de document dans `docs/` doit déclencher une mise à jour de cet index (propriété de l'agent Documentation)
- Les autres agents consultent l'index mais ne le modifient pas
- Un renommage ou déplacement de fichier = mise à jour simultanée de l'index
