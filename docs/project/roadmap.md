---
title: Roadmap
date: 2026-04-17
status: active
author: product-agent
---

# Roadmap - kp-agents

## Phase 1 - Migration en marketplace Claude Code (Priorité: MUST)

**Objectif** : faire de kp-agents une **marketplace Claude Code native** installable via URL git, tout en conservant la compatibilité Cursor/Codex via `sync.sh`. Supprimer la cible d'installation Claude locale désormais redondante.

**Jalon** : release `kp-core-v0.1.0` publiée sur GitHub, installable et fonctionnelle pour tout dev KeyProd.

**Pré-requis** : ✅ Spike de faisabilité validé GO (2026-04-17) — marketplace + plugin + GitHub privé + token d'org fonctionnent.

### Epics

- [E-0001 - Migration en marketplace Claude Code](epics/E-0001-Plugin-Marketplace/readme.md)

### Critères de sortie de phase

- [ ] `./sync.sh` produit les 3 cibles (`plugins/kp-core/`, `dist/cursor/`, `dist/codex/`) sans toucher `~/.claude/commands/`
- [ ] `plugins/kp-core/` contient les 7 agents sous forme de skills au format Claude Code natif
- [ ] `./sync.sh --clean` et `--clean-all` sont adaptés au nouveau périmètre
- [ ] `/plugin install kp-core@kp-agents` fonctionne depuis un poste vierge
- [ ] `/kp-core:brainstorm` (et les 6 autres) sont invocables et répondent correctement
- [ ] Documentation à jour : README, CLAUDE.md, docs/agents.md, docs/INDEX.md
- [ ] Tag `kp-core-v0.1.0` poussé sur GitHub + GitLab

---

## Phase 2 - Ouverture publique et extension (Priorité: COULD)

**Objectif** : permettre à des collaborateurs externes à KeyProd d'utiliser `kp-core` sans friction d'authentification, et préparer l'accueil de futurs plugins (ex: plugins métier spécifiques par projet).

**Hypothèses à valider avant d'engager** :
- Le repo peut être passé en visibilité publique sans exposer de données sensibles
- Y a-t-il une demande externe réelle pour justifier l'effort de hardening ?

### Epics potentielles (à décider après Phase 1)

- E-0002 — Passage du repo en visibilité publique
- E-0003 — Auto-bump de version via hash des skills (retrait du versioning manuel)
- E-0004 — CI : check de cohérence `agents/` ↔ `plugins/` (hook pre-commit ou GitHub Action)
- E-0005 — Premier plugin métier spécifique (ex: `kp-projet-X`)

---

## Risques majeurs

| Risque | Phase | Mitigation |
|---|---|---|
| Drift entre `agents/` et `plugins/` committé | Phase 1 | Discipline de `./sync.sh` avant commit, CI en Phase 2 |
| Oubli de bump `plugin.json` lors d'une release | Phase 1 | CHANGELOG obligatoire, checklist dans la story de release |
| Difficulté pour les externes sans token GitHub org | Phase 2 | Passage en repo public (nécessite audit contenu) |

## Hypothèses de passage d'une phase à l'autre

- **Phase 1 → Phase 2** : au moins 3 devs KeyProd utilisent quotidiennement le plugin, retours positifs, zéro incident de dérive.
