---
title: Roadmap
date: 2026-04-18
status: active
author: product-agent
---


# Roadmap - kp-agents

## Phase 1 - Migration en marketplace Claude Code (Priorité: MUST) ✅ DONE

**Objectif** : faire de kp-agents une **marketplace Claude Code native** installable via URL git, tout en conservant la compatibilité Cursor/Codex via `sync.sh`. Supprimer la cible d'installation Claude locale désormais redondante.

**Jalon** : release `kp-agents-v0.1.0` publiée sur GitHub, installable et fonctionnelle pour tout dev KeyProd. **Atteint le 2026-04-18.**

**Pré-requis** : ✅ Spike de faisabilité validé GO (2026-04-17) — marketplace + plugin + GitHub privé + token d'org fonctionnent.

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

## Phase 2 - Hygiène et extensibilité (Priorité: COULD)

**Objectif** : consolider l'outillage autour du plugin (automatisation, test) et préparer l'accueil de futurs plugins métier spécifiques.

**Décision 2026-04-18** : le passage du repo en visibilité publique est **retiré du périmètre**. Le fonctionnement au sein de l'organisation KeyProd avec token d'org est l'usage cible. Une ouverture publique pourra être reconsidérée ultérieurement si un besoin externe concret émerge.

### Epics actives

- [E-0002 - Auto-bump de version du plugin kp-agents](epics/E-0002-Auto-Bump-Version/readme.md) — 🔄 ready, 3 stories TODO
- [E-0003 - Optimisation des agents selon best practices](epics/E-0003-Optimisation-Agents-Best-Practices/readme.md) — 🔄 ready, 8 stories TODO (voir [`docs/agents-review.md`](../agents-review.md))

### Backlog

Aucune epic en backlog à ce jour. Les deux pistes initialement envisagées (CI de cohérence `agents/` ↔ `plugins/`, premier plugin métier) ont été **retirées du périmètre le 2026-04-18** — elles ne seront pas réalisées en Phase 2. Si un besoin concret émerge ultérieurement, un nouveau cadrage pourra être ouvert via `/kp-agents:product`. Note : le numéro E-0003 a été réattribué à l'epic « Optimisation des agents selon best practices » ci-dessus.

---

## Risques majeurs

| Risque | Phase | Mitigation |
|---|---|---|
| Drift entre `agents/` et `plugins/` committé | Phase 1 (résolu) | Discipline `./sync.sh` avant commit ; à surveiller en revue de PR faute d'automatisation CI prévue |
| Oubli de bump `plugin.json` lors d'une release | Phase 1 (résolu) → Phase 2 (automatisation) | CHANGELOG obligatoire ; automatisation via E-0002 |

## Hypothèses de passage d'une phase à l'autre

- **Phase 1 → Phase 2** : ✅ atteint. La Phase 2 est un backlog d'améliorations, pas un objectif bloquant.
