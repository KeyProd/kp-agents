---
title: Roadmap
date: 2026-04-20
status: active
author: product-agent
---


# Roadmap - kp-agents

> État au 2026-04-20 : Phase 1 et Phase 2 closes. Toutes les epics sont archivées. Aucun backlog actif.

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

## Suite

Aucune nouvelle phase n'est ouverte. Les prochains chantiers seront cadrés à partir d'un besoin concret (nouvelle idée qualifiée via `/kp-agents:brainstorm`, puis `/kp-agents:product`).

## Risques majeurs (historique)

| Risque | Phase | Mitigation |
|---|---|---|
| Drift entre `agents/` et `plugins/` committé | Phase 1 (résolu) | Discipline `./sync.sh` avant commit |
| Oubli de bump `plugin.json` lors d'une release | Phase 1 → Phase 2 (résolu) | Auto-bump via E-0002 |
