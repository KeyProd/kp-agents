### Format de l'index

```markdown
---
title: Index de la documentation
date: YYYY-MM-DD
status: active
author: documentation-agent
---

# Index de la documentation

> Cartographie complète de `docs/` + documents racine du projet. Fichier maintenu par l'agent Documentation.
> Dernière mise à jour : YYYY-MM-DD

## Documents racine du projet

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| README projet | `README.md` | Présentation publique, usage, installation, structure | YYYY-MM-DD |
| Instructions Claude | `CLAUDE.md` | Règles de travail projet pour les agents IA | YYYY-MM-DD |

## Documents structurants `docs/`

| Document | Chemin | Commit | Description |
|----------|--------|--------|-------------|
| Guidelines | `docs/guidelines.md` | ✅ | Convention de la documentation (lisible par tout agent IA) |
| Git — équipe | `docs/git.md` | ✅ | Conventions git du projet (branches, commits, PR) |
| Git — dev local | `docs/git.local.md` | ❌ gitignored | Préférences git du dev (auto-commit, auto-push) |
| Projet — équipe | `docs/project.md` | ✅ | Politique de suivi projet (tickets, workflow, mapping JIRA) |
| Projet — overrides locaux | `docs/project.local.md` | ❌ gitignored | Overrides personnels (ex: project_key de test) |
| Sources doc | `docs/documentation.md` | ✅ | Politique des sources de documentation |
| Sources doc — chemins locaux | `docs/documentation.local.md` | ❌ gitignored | Chemins absolus machine-spécifiques |

> Lister uniquement les fichiers qui existent. Les `.local.md` peuvent être absents selon le poste — c'est normal.

## Documents principaux

| Document | Chemin | Description | Mis à jour |
|----------|--------|-------------|------------|
| Vision produit | `docs/product.md` | Vision, personas, règles métier | YYYY-MM-DD |
| Architecture | `docs/architect.md` | Stack, ADR, diagrammes | YYYY-MM-DD |
| Design system | `docs/design-system.md` | Identité visuelle, tokens | YYYY-MM-DD |
| Roadmap | `docs/project/roadmap.md` | Phases, jalons, priorités | YYYY-MM-DD |

## Apps (monorepo uniquement)

> Section présente uniquement si workspaces détectés.

| App | Chemin | Index local | Description |
|-----|--------|-------------|-------------|
| <app-name> | `apps/<app-name>/` | `apps/<app-name>/docs/index.md` | <description courte> |

## Epics actives

| ID | Titre | Statut | Stories (done/total) | Chemin |
|----|-------|--------|----------------------|--------|
| E-0001 | Titre | in-progress | 2/5 | `docs/project/epics/E-0001-Nom/` |

## Features

| Groupe | product.md | architect.md | ux.md | ui.md |
|--------|------------|--------------|-------|-------|
| auth | ✓ | ✓ | ✗ | ✗ |

## Idées

| Thème | Statut | Chemin |
|-------|--------|--------|
| auth-passwordless | qualified | `docs/ideas/auth-passwordless.md` |

## Epics archivées

| ID | Titre | Statut | Chemin |
|----|-------|--------|--------|
| E-0001 | Titre | done | `docs/project/epics/_archives/E-0001-Nom/` |
```
