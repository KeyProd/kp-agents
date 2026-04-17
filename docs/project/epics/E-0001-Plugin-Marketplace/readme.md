---
title: Migration en marketplace Claude Code
date: 2026-04-17
status: ready
author: product-agent
epic-id: E-0001
phase: 1
---

# E-0001 - Migration en marketplace Claude Code

## Résumé

Transformer kp-agents en marketplace Claude Code installable via URL git. Un seul plugin `kp-agents` expose les 7 agents génériques. `sync.sh` est refactoré pour retirer la cible d'installation Claude locale (remplacée par le mécanisme plugin) tout en conservant Cursor et Codex.

## Objectif

Réduire la friction d'installation et de mise à jour des agents pour les développeurs KeyProd, en s'appuyant sur le mécanisme de plugin Claude Code natif, tout en préservant la cohérence du format source unique (`agents/<nom>.md`).

## Problème adressé

- Aujourd'hui, installer kp-agents = cloner le repo + lancer `./sync.sh`. Cette friction décourage l'adoption et rend les mises à jour non-automatiques
- La cible Claude locale (`~/.claude/commands/`) deviendra obsolète à l'arrivée du plugin, générant de la dette si conservée

## Résultat attendu

- Un dev KeyProd installe les agents dans Claude Code via `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
- Le dev invoque les agents via `/kp-agents:<nom>` (ex: `/kp-agents:brainstorm`)
- Les mises à jour sont appliquées automatiquement via `/plugin marketplace update`
- Les utilisateurs Cursor et Codex continuent d'utiliser `sync.sh` pour installer leurs versions

## Périmètre

### Inclus

- Refonte complète de `sync.sh` : retrait des fonctions `generate_claude*`, ajout d'une cible `plugins/kp-agents/`
- Remplacement du plugin temporaire `kp-agents-spike` par `kp-agents` définitif
- Adaptation des flags `--clean` et `--clean-all` au nouveau périmètre
- Adaptation du manifeste `.installed-agents` (Cursor/Codex uniquement)
- Mise à jour de toute la documentation projet (README, CLAUDE.md, docs/agents.md, docs/INDEX.md)
- Release initiale `kp-agents-v0.1.0` taguée

### Exclu

- Stratégie automatique de cohérence `agents/` ↔ `plugins/` (pre-commit, CI) → reporté en Phase 2
- Ouverture publique du repo → reporté en Phase 2
- Création d'autres plugins (ex: `kp-metier-X`) → reporté en Phase 2
- Migration des utilisateurs actuels ayant déjà installé via l'ancien `sync.sh` → un message informatif suffit

## Règles métier concernées

- Un agent a une définition unique dans `agents/<nom>.md`
- Le préfixe `kp-` identifie les agents issus de ce projet
- Les agents Claude sont namespacés `/kp-agents:<nom>` (imposé par le format plugin)
- Le plugin `kp-agents` suit du semver : bump manuel dans `plugins/kp-agents/.claude-plugin/plugin.json`

## Dépendances

- ✅ Architecture validée ([docs/architect.md](../../architect.md))
- ✅ Spike GO validé ([docs/ideas/plugin-claude-code.md](../../ideas/plugin-claude-code.md))
- ✅ Repo GitHub `KeyProd/kp-agents` accessible avec token d'organisation
- ✅ Repo GitLab `keyprod/tools/kp-agents` synchronisé en miroir
- ⚠️ L'utilisateur doit accepter que `/kp-brainstorm` devienne `/kp-agents:brainstorm` (namespacing imposé)

## Risques / inconnues

- **R1** : drift possible entre `agents/` et `plugins/` si le dev oublie `./sync.sh` avant commit → documenté comme discipline pour la Phase 1, automatisé en Phase 2
- **R2** : rupture pour les utilisateurs actuels ayant fait `sync.sh` avec l'ancienne version (leur `~/.claude/commands/kp-*.md` reste, sans plus être mis à jour) → mitigation : message one-shot dans `sync.sh` pour guider la migration
- **R3** : le comportement exact du namespace Claude Code a été validé pour le spike (`kp-agents-spike:brainstorm`) mais pas pour tous les skills simultanément → validation finale dans S-0003

## Stories

- [S-0001 - Refonte sync.sh pour générer le plugin kp-agents](S-0001-Refonte-Sync.md) — transforme le pipeline de build et retire la cible Claude locale
- [S-0002 - Mise à jour de la documentation projet](S-0002-Mise-A-Jour-Documentation.md) — aligne README, CLAUDE.md, docs/agents.md, docs/INDEX.md sur la nouvelle architecture
- [S-0003 - Release kp-agents-v0.1.0 et validation end-to-end](S-0003-Release-V01.md) — bump, tag, push, test d'installation depuis un poste vierge

## Critères de succès

- [ ] Le dossier `plugins/kp-agents/` contient un plugin valide au sens de `claude plugin validate`
- [ ] `./sync.sh` ne dépose plus aucun fichier dans `~/.claude/commands/`
- [ ] `./sync.sh` continue de produire `dist/cursor/*.mdc` et `dist/codex/*/SKILL.md` sans régression
- [ ] Les 7 skills sont accessibles via `/kp-agents:<nom>` une fois le plugin installé
- [ ] Documentation cohérente avec la nouvelle architecture (aucune mention résiduelle d'install Claude locale ou d'agents recettemoi)
- [ ] Tag `kp-agents-v0.1.0` poussé sur GitHub + GitLab
- [ ] Aucune régression sur les installations Cursor/Codex existantes
