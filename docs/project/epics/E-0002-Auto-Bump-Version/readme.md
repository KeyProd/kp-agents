---
title: Auto-bump de version du plugin kp-agents
date: 2026-04-18
status: ready
author: product-agent
epic-id: E-0002
phase: 2
---

# E-0002 - Auto-bump de version du plugin kp-agents

## Résumé

Automatiser le bump de la version du plugin `kp-agents` dans `plugins/kp-agents/.claude-plugin/plugin.json` à chaque modification de contenu détectée par `sync.sh`. Supprime le risque d'oubli humain qui empêche Claude Code de détecter les mises à jour côté client. Les bumps **mineur** et **majeur** restent manuels via des flags explicites.

## Objectif

Garantir que la version publiée reflète toujours l'état réel du plugin, sans friction pour le contributeur. Rendre la distribution de mises à jour fiable à 100%.

## Problème adressé

Aujourd'hui, le contributeur doit **penser** à bumper `plugin.json` avant chaque release. S'il oublie :

- Claude Code côté client compare la version locale en cache (ex: `0.1.0`) à celle du remote (`0.1.0` toujours) → **identique** → mise à jour skippée silencieusement
- Le dev peut mettre plusieurs dizaines de minutes à diagnostiquer
- La confiance dans le flux de distribution s'effrite

Ce problème s'est concrètement manifesté durant l'epic E-0001 (symptôme `0 skills` résolu par renommage + bump forcé).

## Résultat attendu

- ✅ Un contributeur qui modifie un agent dans `agents/<nom>.md` puis fait `./sync.sh` voit la version patch incrémentée sans aucune action manuelle
- ✅ Un contributeur qui re-sync sans rien changer ne génère pas de bump inutile (idempotence)
- ✅ Les bumps mineur (`--minor`) et majeur (`--major`) sont invocables explicitement par le contributeur
- ✅ Un bump manuel saisi dans `plugin.json` est respecté, jamais écrasé par l'auto-bump
- ✅ La documentation (README, CLAUDE.md, architect.md ADR-005) décrit précisément le comportement et le workflow

## Périmètre

### Inclus

- Calcul d'un hash SHA256 du contenu des skills générés (`plugins/kp-agents/skills/**/SKILL.md`)
- Stockage du hash précédent dans un champ `_contentHash` de `plugins/kp-agents/.claude-plugin/plugin.json` (validé compatible avec `claude plugin validate`)
- Incrémentation automatique du `patch` (ex: `0.1.0` → `0.1.1`) si le hash a changé
- Flags `./sync.sh --minor` et `./sync.sh --major` pour les bumps explicites (avec reset correct des composantes inférieures : mineur remet patch à 0, majeur remet mineur et patch à 0)
- Respect du bump manuel : si la version dans `plugin.json` a été modifiée à la main depuis le dernier sync, on met à jour le hash mais on ne re-bumpe pas par-dessus
- ADR-005 dans `docs/architect.md` consignant la décision
- Mise à jour de `README.md`, `CLAUDE.md` avec le nouveau workflow
- Logs clairs dans la sortie de `sync.sh` décrivant le bump effectué (ou l'absence de bump)

### Exclu

- Tag git automatique (reste manuel : `git tag kp-agents-v<X.Y.Z>`)
- Publication GitHub Release automatique
- Génération automatique du CHANGELOG (entrée manuelle à ajouter à la main lors du commit)
- Bump du champ `version` de la marketplace (`.claude-plugin/marketplace.json`) — géré séparément si jamais nécessaire
- Analyse sémantique "intelligente" (ex: "ajouter un agent = mineur") — reste décision humaine

## Règles métier concernées

- **RM-1** : le hash de contenu est calculé uniquement sur les fichiers `plugins/kp-agents/skills/**/SKILL.md`. Ni `plugin.json`, ni `marketplace.json`, ni les artefacts Cursor/Codex n'influencent le hash
- **RM-2** : un bump auto se limite au `patch` ; mineur et majeur sont explicites via flags
- **RM-3** : la priorité va toujours au choix humain — si `version` a changé entre deux syncs sans qu'on passe par `sync.sh --minor/--major`, on respecte la valeur saisie (bump manuel) et on met à jour le hash sans bumper
- **RM-4** : la **documentation doit être tenue à jour au fil de l'eau** dans chaque story de cette epic. Toute story qui introduit un changement de comportement `sync.sh` doit modifier `README.md`, `CLAUDE.md` et, si pertinent, `docs/architect.md`. Cette règle est **bloquante** — une story sans maj doc associée n'est pas DONE.
- **RM-5** : `claude plugin validate` doit continuer à passer après chaque modification (validation post-sync non bloquante, mais absence d'erreur attendue)

## Dépendances

- ✅ Plugin `kp-agents` en place (issu de E-0001 — clôturée le 2026-04-18)
- ✅ `sync.sh` refactoré avec cibles plugin + Cursor + Codex
- Outil `shasum` ou `sha256sum` disponible (standard sur macOS et Linux, à vérifier par Architect)
- Pas de dépendance externe nouvelle

## Risques / inconnues

- **R1** : le champ custom `_contentHash` dans `plugin.json` pourrait être rejeté par une future version de `claude plugin validate` (à confirmer — la doc officielle tolère les champs inconnus à date, mais ce n'est pas garanti contractuellement). Mitigation : fallback vers un fichier dédié si validation échoue
- **R2** : `shasum` n'existe pas dans tous les environnements (CI minimaliste ?) → à vérifier par Architect, alternative : `openssl dgst -sha256`
- **R3** : un merge Git qui combine deux bumps manuels concurrents peut produire une version `plugin.json` incohérente avec le hash. Pas de résolution automatique prévue — le contributeur doit arbitrer manuellement (documenté dans README troubleshooting)
- **R4** : la détection "bump manuel vs auto" suppose qu'on peut distinguer la version actuelle du dernier bump auto. On stocke donc la version de référence aussi ? (à préciser côté Architect — piste : si `_contentHash` dans `plugin.json` = hash actuel ET version != celle attendue, alors bump manuel détecté)

## Stories

- [S-0001 - Auto-bump patch à chaque sync](S-0001-Auto-Bump-Patch.md) — calcul du hash, incrémentation auto du patch, stockage du `_contentHash`, log lisible, maj doc minimale (CLAUDE.md + README.md)
- [S-0002 - Flags `--minor` et `--major` + respect du bump manuel](S-0002-Flags-Minor-Major.md) — ajout des flags CLI, logique de détection du bump manuel, cas d'erreur (flags conflictuels), maj doc
- [S-0003 - ADR-005 et consolidation documentaire](S-0003-ADR-Documentation.md) — ADR-005 dans `docs/architect.md`, section dédiée dans README, note dans CHANGELOG, signal Documentation pour `docs/INDEX.md`

## Critères de succès

- Après release de E-0002, zéro "oubli de bump" rapporté
- Un `./sync.sh` sur `agents/brainstorm.md` modifié produit immédiatement un plugin avec version bumpée et hash à jour
- La section "Publier une mise à jour" de CLAUDE.md devient 4 étapes au lieu de 5 (suppression du "bumper manuellement")
- ADR-005 approuvée et traçable dans `docs/architect.md`
- `docs/INDEX.md` reflète l'ajout de l'ADR et l'archivage de l'epic après clôture
