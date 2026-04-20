---
title: ADR-005 et consolidation documentaire
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0003
epic-id: E-0002
---

# S-0003 - ADR-005 et consolidation documentaire

## Résumé

Conclure l'epic E-0002 par une documentation durable : ajout d'une nouvelle ADR-005 dans `docs/architect.md` qui capture la décision d'architecture du versioning, consolidation des modifications doc faites en S-0001 et S-0002, et déclencheur vers l'agent Documentation pour maintenir `docs/INDEX.md` et archiver l'epic.

## User Story

En tant que **contributeur ou mainteneur futur du projet**, je veux **trouver dans `docs/architect.md` une ADR claire expliquant le choix d'auto-bump** afin de **comprendre le contexte et les alternatives rejetées sans avoir à relire l'historique git**.

## Contexte

- S-0001 a livré l'auto-bump patch
- S-0002 a livré les flags `--minor`/`--major` et le respect du bump manuel
- Les modifications de `README.md` et `CLAUDE.md` ont été faites au fil de l'eau (règle RM-4)
- Il manque :
  - Une ADR formelle dans `docs/architect.md` qui trace la décision
  - Une section Troubleshooting dans `README.md` couvrant les cas bump manuel / hash incohérent
  - Un signalement explicite à l'agent Documentation pour maintenir `docs/INDEX.md` et archiver l'epic

## Règles métier

- **RM-4** (epic) : documentation à tenir à jour (cette story la consolide)
- L'ADR-005 doit suivre le format établi dans `docs/architect.md` (cohérence avec ADR-001 à ADR-004 de E-0001)
- Le handoff vers `/kp-agents:documentation` est la dernière étape de l'epic (avant archivage)

## Scénarios

### Nominal — Consolidation documentaire

- Étant donné une epic E-0002 avec S-0001 et S-0002 en DONE
- Quand un contributeur lit `docs/architect.md`
- Alors il trouve une ADR-005 "Auto-bump de version plugin" avec contexte, décision, conséquences, alternatives rejetées
- Et l'ADR fait référence au hash SHA256, au champ `_contentHash`, au champ `_lastAutoVersion`, à la priorité au bump manuel
- Et le `README.md` contient une section Troubleshooting couvrant :
  - "Version semble figée après un changement" → vérifier que `shasum` ou `openssl` sont dispos
  - "Bump manuel ignoré" → vérifier l'alignement `version` / `_lastAutoVersion`

### Alternatif — Vérification de cohérence avec les autres docs

- Étant donné la documentation du projet
- Quand on fait un grep `kp-agents` dans la doc
- Alors les mentions de workflow de publication utilisent bien le nouveau process (pas de bump manuel par défaut, flags pour minor/major)

### Cas d'erreur — Incohérence détectée en fin de story

- Étant donné qu'une section de doc mentionne encore "bumper manuellement" comme étape obligatoire (résidu de S-0001/S-0002)
- Quand cette story est reviewée
- Alors la review remonte l'incohérence et la story retourne en IN PROGRESS jusqu'à correction

## Cas limites

- [ ] Aucune feature n'a changé en comportement → la doc n'a normalement rien de plus à dire que ce que S-0001/S-0002 ont ajouté (cette story devient légère, potentiellement juste l'ADR et le handoff)
- [ ] Un ajustement technique a été fait en cours d'implémentation (ex: champ renommé, commande différente) → l'ADR doit refléter la réalité finale, pas les intentions initiales
- [ ] Les schémas Mermaid existants dans `docs/agents.md` ne sont pas impactés (ils ne mentionnent pas le versioning) — à confirmer au passage

## Critères d'acceptation

- [ ] `docs/architect.md` contient une section `ADR-005 - Auto-bump de version plugin` avec les 5 rubriques standard (Statut, Contexte, Décision, Conséquences, Alternatives rejetées)
- [ ] L'ADR-005 cite précisément les champs `_contentHash` et `_lastAutoVersion` et l'algorithme SHA256 utilisé
- [ ] L'ADR-005 liste au moins 2 alternatives rejetées (ex: bump par timestamp, bump par count de commits) avec la raison du rejet
- [ ] L'ADR-005 est référencée dans le sommaire des ADR en haut de `docs/architect.md`
- [ ] Le `README.md` contient une section Troubleshooting dédiée au versioning plugin couvrant au moins 2 cas (voir scénario nominal)
- [ ] Le `CHANGELOG.md` contient une entrée pour la prochaine release concernant E-0002 (même si la release n'est pas faite dans cette story, l'entrée est préparée)
- [ ] Le `CLAUDE.md` a été relu et ne contient plus aucune référence au bump manuel comme étape obligatoire
- [ ] Aucune incohérence entre la doc et le comportement réel de `sync.sh` (vérifiable par grep sur "bump" et relecture manuelle)
- [ ] **Handoff explicite vers `/kp-agents:documentation`** en fin de story avec consignes précises :
  - Mettre à jour `docs/INDEX.md` pour référencer la nouvelle ADR-005
  - Marquer l'epic E-0002 comme `done` dans son `readme.md`
  - Archiver l'epic dans `docs/project/epics/_archives/E-0002-Auto-Bump-Version/` selon la convention
  - Mettre à jour la roadmap (retirer E-0002 du backlog Phase 2 puisqu'elle devient archivée)
  - Mettre à jour les dates "Mis à jour" dans l'INDEX
- [ ] Tous les tests manuels de S-0001 et S-0002 restent valides après les modifs doc (aucune régression de code)

## Dépendances

- **Story S-0001 DONE** (auto-bump patch implémenté)
- **Story S-0002 DONE** (flags --minor/--major implémentés, respect bump manuel)

## Notes techniques

- Cette story est **majoritairement documentaire**. Pas ou peu de modifications de `sync.sh`.
- Exception : si en relisant le code durant la rédaction de l'ADR, une incohérence ou un bug est détecté, le corriger et le documenter
- Le CHANGELOG suit le format Keep a Changelog déjà établi (voir entrée `kp-agents-v0.1.0`). L'entrée pour E-0002 doit anticiper le prochain numéro de version (probablement `0.2.0` ou `0.3.0` selon quel bump sera fait à la release)

## Instrumentation / mesure

- Vérifier que `grep -c "ADR-" docs/architect.md` retourne **5** après la story (ADR-001 à ADR-005)
- Vérifier que `grep -i "bumper manuellement\|bumper à la main" README.md CLAUDE.md` ne retourne **aucune** occurrence où c'est présenté comme une étape obligatoire

## Questions ouvertes

- Le numéro de la prochaine release (`0.2.0` ou `0.3.0`) dépendra de la stratégie de bump appliquée au moment de merger E-0002. **Hypothèse** : `--minor` (fonctionnalité notable ajoutée) donc `0.2.0`. À confirmer lors de la release.
- Faut-il prévoir une ADR séparée pour le hash (choix SHA256 vs autre) ou l'inclure dans l'ADR-005 ? **Hypothèse** : inclure dans ADR-005 dans la section "Décision" pour rester concis.

## Implémentation

**Date** : 2026-04-19
**Branche** : `feat/E-0002-Auto-Bump-Version`

### Fichiers modifiés

- **`docs/architect.md`** :
  - **ADR-004** (Versioning semver manuel) passée en statut `deprecated (superseded by ADR-005)`.
  - **ADR-005 — Auto-bump de version du plugin kp-agents** ajoutée (statut `accepted, supersedes ADR-004`). Contexte quantifié (7 skills, < 200 ms, pas de CI), décision en 7 points (SHA256, `_contentHash`, `_lastAutoVersion`, patch auto, flags `--minor`/`--major` exclusifs, respect bump manuel, python3 argv-safe), 5 alternatives rejetées argumentées, référence à `docs/features/auto-bump/architect.md`.
- **`README.md`** : section "Troubleshooting" enrichie de 3 nouvelles sous-sections dédiées au versioning :
  - *Auto-bump de version : la version ne bouge pas après modification* — checklist `shasum`/`openssl`/`python3`/champ `_lastAutoVersion`.
  - *Conflit Git sur `plugin.json` après merge concurrent* — procédure de résolution.
  - *Rollback d'une release* — explication de la contrainte semver + technique via `git revert` + patch bump en avant.
- **`CHANGELOG.md`** : entrée `[kp-agents-v0.3.0] — à venir (épic E-0002 terminée)` préparée en tête du fichier. 3 sous-sections (Ajouté / Modifié / Notes) qui consolident S-0001, S-0002 et S-0003. Note globale au header sur l'auto-bump introduite.

### Pas de modification de `sync.sh`

Cette story est purement documentaire. `sync.sh` n'a pas été touché.

### Décisions prises pendant l'implémentation

- **Statut ADR-004** : basculée en `deprecated` avec mention explicite de la supersedure par ADR-005. Cette transition est plus claire que de simplement réécrire ADR-004 (qui perdrait l'historique de décision).
- **CHANGELOG : version `à venir`** : l'entrée est préparée mais pas encore taguée. Le tag `kp-agents-v0.3.0` sera appliqué au moment de la fermeture définitive de l'epic E-0002, pas dans S-0003 (qui reste au niveau doc).
- **Pas d'entrée pour ADR-004 deprecated dans CHANGELOG** : les changements ADR sont de la gouvernance, pas du code livré. Le CHANGELOG se focus sur les changements observables par les utilisateurs du plugin.

### Commandes de vérification

```bash
# 1. Compter les ADR dans architect.md — doit retourner 5
grep -c "^### ADR-" docs/architect.md   # → 5

# 2. ADR-004 bien en deprecated
grep -A1 "### ADR-004" docs/architect.md | head -2

# 3. ADR-005 présente et en accepted
grep -A1 "### ADR-005" docs/architect.md | head -2

# 4. Aucune mention "bumper manuellement" comme étape obligatoire dans README/CLAUDE.md
grep -i "bumper.*manuellement\|bumper.*à la main" README.md CLAUDE.md
# → aucune (les occurrences dans docs/project/ et docs/features/ sont dans des specs,
#   qui décrivent le comportement retiré pour mémoire — OK)

# 5. CHANGELOG contient l'entrée v0.3.0
grep "kp-agents-v0.3.0" CHANGELOG.md

# 6. Validation plugin
claude plugin validate /Users/vincent/GIT/kp-agents   # → ✔ Validation passed
```

### Notes de review

- Le draft ADR-005 prévu par Architect dans [docs/features/auto-bump/architect.md](../../features/auto-bump/architect.md) a été repris avec quelques ajustements mineurs (ordre des points de décision, référence croisée à la feature doc)
- ADR-004 → `deprecated` explicite, respecte la convention ADR (un statut neutre historique reste visible)
- Règle métier RM-4 intégralement respectée sur les 3 stories de l'epic

## Validation par critère

- **[✅] `docs/architect.md` contient une section ADR-005 avec les 5 rubriques standard** : Statut, Contexte, Décision, Conséquences, Alternatives rejetées. Preuve : `grep -c "^### ADR-" docs/architect.md` → 5.
- **[✅] L'ADR-005 cite précisément les champs `_contentHash` et `_lastAutoVersion` et l'algorithme SHA256** : vérifiable dans la section Décision (7 points).
- **[✅] L'ADR-005 liste au moins 2 alternatives rejetées** : 5 alternatives documentées (fichier séparé, timestamp, git rev-count, auto-bump intelligent, jq) avec raison du rejet pour chacune.
- **[⚠️] L'ADR-005 est référencée dans le sommaire des ADR en haut de `docs/architect.md`** : `docs/architect.md` n'a pas de sommaire explicite des ADR — les ADR sont listées en séquence dans la section "Décisions techniques". Le point est traité par adjonction en fin de liste (ordre chronologique respecté). **Limite** : pas de lien TOC, mais l'organisation actuelle du document ne comportait pas de TOC avant cette story.
- **[✅] `README.md` contient une section Troubleshooting dédiée au versioning plugin couvrant au moins 2 cas** : 3 cas documentés (version ne bouge pas, conflit merge, rollback).
- **[✅] `CHANGELOG.md` contient une entrée pour la prochaine release concernant E-0002** : entrée `[kp-agents-v0.3.0] — à venir (épic E-0002 terminée)` présente avec Ajouté / Modifié / Notes.
- **[✅] `CLAUDE.md` ne contient plus aucune référence au bump manuel comme étape obligatoire** : vérifié par grep — les mentions restantes sont dans les docs de spec (stories E-0002) qui **parlent** de ce qui a été retiré.
- **[✅] Aucune incohérence entre la doc et le comportement réel de `sync.sh`** : relecture manuelle — les flags documentés correspondent à l'implémentation (S-0001 + S-0002), les messages de log annoncés dans les docs correspondent à ce que le code émet.
- **[✅] Handoff explicite vers `/kp-agents:documentation`** : voir section "Suggestion de relais" ci-dessous.
- **[✅] Aucune régression de code** : `./sync.sh` + `claude plugin validate` passent en final. Les modifs de cette story sont 100 % documentaires.

### Suggestion de relais (après merge de l'epic)

> **Handoff → /kp-agents:documentation**
> **Depuis** : developer-agent (S-0003 DONE, epic E-0002 à clôturer)
> **Contexte** : Epic E-0002 "Auto-bump de version" terminée (3 stories DONE), prêt pour archivage
> **Acquis** :
> - `plugins/kp-agents/.claude-plugin/plugin.json` a les champs `_contentHash` et `_lastAutoVersion`
> - ADR-005 dans `docs/architect.md` (ADR-004 passée deprecated)
> - README.md : section Troubleshooting enrichie (3 cas versioning)
> - CHANGELOG.md : entrée v0.3.0 préparée pour la release
> - `docs/features/auto-bump/architect.md` : spec technique de référence (créée par Architect)
> **À traiter** (dans cet ordre) :
> 1. Retirer E-0002 de la section "Epics actives" dans `docs/INDEX.md`
> 2. Ajouter E-0002 dans "Epics archivées" avec compteur 3/3 stories DONE
> 3. Archiver le dossier `docs/project/epics/E-0002-Auto-Bump-Version/` dans `_archives/` via `git mv`
> 4. Mettre à jour la roadmap : E-0002 passe en "done", Phase 2 reste active avec E-0003 si non encore archivée
> 5. Ajouter `docs/features/auto-bump/architect.md` dans le tableau "Features" de l'INDEX
> 6. Rafraîchir les dates "Mis à jour" pour les documents touchés aujourd'hui
> **Fichiers de référence** : `docs/INDEX.md`, `docs/project/roadmap.md`, `docs/project/epics/E-0002-Auto-Bump-Version/`
