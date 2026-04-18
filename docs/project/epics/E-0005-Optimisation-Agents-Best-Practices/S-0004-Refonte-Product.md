---
title: Refonte de l'agent product
date: 2026-04-18
status: TODO
author: product-agent
story-id: S-0004
epic-id: E-0005
---

# S-0004 - Refonte de l'agent product

## Résumé

Refactoriser `agents/product.md` : remplacer les templates roadmap/epic/story inline par les includes existants, déplacer le "mode init" en amont du processus, sortir les exemples de calibrage de la liste des règles.

## User Story

En tant que mainteneur, je veux que `agents/product.md` délègue le contenu des templates à `includes/` au lieu de les dupliquer, afin d'avoir une source de vérité unique partagée avec l'agent documentation et d'alléger l'agent d'environ 80 lignes.

## Contexte

- Recommandations couvertes : **O2.1** (templates inline → includes, **P1**), **O2.2** (mode init réordonné, **P2**), **O2.3** (exemples calibrage hors `## Règles`, **P3**).
- Les includes cibles existent déjà : `includes/product-template.md`, `includes/epic-template.md`, `includes/story-template.md`.
- L'agent documentation référence déjà ces templates → éviter la divergence.

## Règles métier

- Aucun changement fonctionnel : l'agent product doit continuer à produire les mêmes artefacts (`docs/product.md`, roadmap, epics, stories).
- Les templates inline doivent être remplacés par des `{{include:<nom>}}` à l'emplacement approprié, pas simplement supprimés.
- Le "mode init" devient la première étape du processus (étape 0 ou 1) et renomme la numérotation existante en conséquence.

## Scénarios

### Nominal

- **Étant donné** `agents/product.md` contient les templates roadmap/epic/story inline (~80 lignes)
- **Quand** je les remplace par `{{include:product-template}}`, `{{include:epic-template}}`, `{{include:story-template}}` et je réordonne les étapes
- **Alors** le SKILL.md compilé contient les mêmes templates finaux (via résolution de l'include) et pèse environ 80 lignes de moins en source.

### Alternatif

- **Étant donné** le contenu d'un template inline diffère subtilement du contenu de l'include correspondant
- **Quand** je fais le remplacement
- **Alors** je signale la différence, je demande arbitrage (utilisateur) sur la version à conserver, et je mets à jour l'include si c'est le bon comportement.

### Erreur / refus

- **Étant donné** un include requis n'existe pas encore (cas improbable vu l'existant)
- **Quand** je lance `sync.sh`
- **Alors** l'erreur est détectée (include non résolu) et la story remonte en dépendance.

## Cas limites

- [ ] Un template inline contient du texte explicatif autour du bloc de code : conserver ce texte en prose dans `product.md` et ne déléguer que le bloc de code à l'include.
- [ ] Le "mode init" (étape 5 actuelle) est référencé dans `## Règles` ou ailleurs : vérifier et ajuster les références.
- [ ] Les numéros d'étapes sont renumérotés : vérifier qu'aucun agent en aval (developer, review) ne référence "l'étape N de product" (en principe non, mais à confirmer via `grep`).

## Critères d'acceptation

- [ ] Les 3 templates inline (roadmap, epic, story) dans `agents/product.md` sont remplacés par les includes correspondants.
- [ ] Le contenu final compilé dans `plugins/kp-agents/skills/product/SKILL.md` est **équivalent** (pas forcément identique au byte près) au contenu pré-refonte : mêmes champs, mêmes sections, mêmes conventions.
- [ ] Le "mode init" (création du squelette `docs/`) apparaît **avant** l'étape "Cadrage produit" dans le processus, avec une numérotation cohérente.
- [ ] Les "Exemples de calibrage qualité" (critère bien formulé vs vague) sont extraits de `## Règles` et placés en section autonome `## Exemples de calibrage` après le processus.
- [ ] `./sync.sh` passe sans erreur ; inspection manuelle du SKILL.md compilé OK.
- [ ] `agents/product.md` a perdu environ 80 lignes (ou équivalent aux templates retirés).

## Dépendances

- **Ne dépend pas** de S-0001/S-0002/S-0003 (zones distinctes), mais recommandé après S-0001 pour valider le fonctionnement des includes neufs.
- **Bloque** S-0008 (release v0.2.0).

## Notes techniques

- Fichiers impactés : `agents/product.md` (réécrit partiellement), régénération `plugins/kp-agents/skills/product/SKILL.md` + `dist/`.
- Vérifier que les includes `epic-template`, `story-template`, `product-template` sont bien listés dans `CLAUDE.md` (stratégie d'inclusion par agent) — normalement déjà le cas.
- Ne pas oublier d'ajouter `{{include:epic-template}}` et `{{include:story-template}}` à l'agent product s'ils n'y sont pas déjà (vérifier via la dernière ligne de `agents/product.md`).

## Instrumentation / mesure

- Mesure quantitative : `wc -l agents/product.md` avant / après (cible : −60 à −80 lignes).
- Mesure qualitative : diff des SKILL.md compilés avant/après → doit être équivalent (hormis l'ordre éventuel des sections si le mode init est déplacé).

## Questions ouvertes

- La section "Vue globale produit" (étape 6 actuelle) fait doublon partiel avec `{{include:product-template}}` déjà présent en fin de fichier. Faut-il la conserver comme étape explicite ou la retirer ? Proposition : la conserver (elle indique **quand** mettre à jour), mais raccourcir à 2-3 lignes renvoyant à l'include.
