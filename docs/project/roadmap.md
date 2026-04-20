---
title: Roadmap
date: 2026-04-21
status: active
author: product-agent
---


# Roadmap - kp-agents

> État au 2026-04-21 : Phases 1 et 2 closes. **Phase 3 ouverte** (Configurabilité & sources externes).

## Phase 1 - Migration en marketplace Claude Code (Priorité: MUST) ✅ DONE

**Objectif** : faire de kp-agents une **marketplace Claude Code native** installable via URL git, tout en conservant la compatibilité Cursor/Codex via `sync.sh`. Supprimer la cible d'installation Claude locale désormais redondante.

**Jalon** : release `kp-agents-v0.1.0` publiée sur GitHub, installable et fonctionnelle pour tout dev KeyProd. **Atteint le 2026-04-18.**

### Epics

- [E-0001 - Migration en marketplace Claude Code](epics/_archives/E-0001-Plugin-Marketplace/readme.md) — ✅ DONE (archivée)

### Critères de sortie de phase

- [x] `./sync.sh` produit les 3 cibles (`plugins/kp-agents/`, `dist/cursor/`, `dist/codex/`) sans toucher `~/.claude/commands/`
- [x] `plugins/kp-agents/` contient les 7 agents sous forme de skills au format Claude Code natif
- [x] `./sync.sh --clean` et `--clean-all` sont adaptés au nouveau périmètre
- [x] `/plugin install kp-agents@kp-agents` fonctionne depuis un poste vierge
- [x] `/kp-agents:brainstorm` (et les 6 autres) sont invocables et répondent correctement
- [x] Documentation à jour : README, CLAUDE.md, docs/agents.md, docs/INDEX.md
- [x] Tag `kp-agents-v0.1.0` poussé sur GitHub + GitLab

---

## Phase 2 - Hygiène et extensibilité (Priorité: COULD) ✅ DONE

**Objectif** : consolider l'outillage autour du plugin (automatisation, qualité des agents) après la release v0.1.0.

**Décision 2026-04-18** : le passage du repo en visibilité publique est **retiré du périmètre**. Fonctionnement cible au sein de l'organisation KeyProd avec token d'org.

### Epics

- [E-0002 - Auto-bump de version du plugin kp-agents](epics/_archives/E-0002-Auto-Bump-Version/readme.md) — ✅ DONE (archivée 2026-04-20), 3/3 stories DONE
- [E-0003 - Optimisation des agents selon best practices](epics/_archives/E-0003-Optimisation-Agents-Best-Practices/readme.md) — ✅ DONE (archivée 2026-04-18), 8/8 stories DONE, release `kp-agents-v0.2.0`

### Backlog

Vide. Les deux pistes initialement envisagées (CI de cohérence `agents/` ↔ `plugins/`, premier plugin métier) ont été retirées le 2026-04-18. Un nouveau cadrage via `/kp-agents:product` sera nécessaire si un besoin concret émerge.

---

## Phase 3 - Configurabilité & sources externes (Priorité: SHOULD) 🚧 IN PROGRESS

**Objectif** : rendre les agents `kp-agents` capables de travailler sur des projets dont la documentation produit est centralisée hors du repo (OneDrive / SharePoint) et dont le suivi des tickets est externalisé (JIRA via MCP), tout en préservant 100% le comportement actuel pour les projets sans configuration. Introduction d'un 8ᵉ agent `setup` dédié à la configuration projet et aux préférences utilisateur.

**Jalon** : release `kp-agents-v1.1.0` publiée sur GitHub, validée sur au moins un projet KeyProd réel avec doc produit OneDrive et tickets JIRA.

### Epics

- [E-0004 - Sources Externalisation](epics/E-0004-Sources-Externalisation/readme.md) — 🚧 IN PROGRESS, 0/8 stories

### Critères de sortie de phase

- [ ] Un projet sans `.kp-agents.yml` fonctionne exactement comme aujourd'hui (non-régression)
- [ ] Un projet avec `product.mode: external` peut pointer vers un dossier OneDrive, l'agent Product lit/écrit dedans avec fallback local si écriture refusée
- [ ] Un projet avec `tickets.mode: mcp` crée/lit les epics et stories via MCP JIRA avec mapping documenté
- [ ] Aucun chemin machine-spécifique n'est commité dans le repo (gitignore effectif sur `.kp-agents.local.yml`)
- [ ] Le nouvel agent `setup` est invocable via `/kp-agents:setup` et configure correctement les deux dimensions
- [ ] Les 7 agents existants détectent une config manquante et redirigent vers `setup` sans bloquer l'utilisateur
- [ ] Release `kp-agents-v1.1.0` taguée (minor bump car ajout d'agent)
- [ ] README + CLAUDE.md + docs/agents.md mis à jour

### Risques majeurs

| Risque | Mitigation |
|---|---|
| Mapping story-markdown ↔ ticket JIRA plus lourd que prévu | Spike dédié (S-0005) avant implémentation S-0006 — possibilité de scinder en 2 epics si nécessaire |
| Permissions OneDrive variables (lecture seule vs lecture-écriture) | Fallback write local systématique avec warn explicite |
| Gonflement des skills par l'include partagé | Mesure de taille avant/après sur `developer.md` (skill le plus long) en S-0001 |

---

## Suite

Phase 3 en cours. Les chantiers suivants seront cadrés après clôture, à partir de besoins concrets.

## Risques majeurs (historique)

| Risque | Phase | Mitigation |
|---|---|---|
| Drift entre `agents/` et `plugins/` committé | Phase 1 (résolu) | Discipline `./sync.sh` avant commit |
| Oubli de bump `plugin.json` lors d'une release | Phase 1 → Phase 2 (résolu) | Auto-bump via E-0002 |
