---
title: Nettoyage ciblé des agents restants
date: 2026-04-18
status: TODO
author: product-agent
story-id: S-0006
epic-id: E-0005
---

# S-0006 - Nettoyage ciblé des agents restants

## Résumé

Appliquer les optimisations P2/P3 ciblées aux 5 agents non couverts par S-0004 et S-0005 : brainstorm (menu → défaut), architect (fusion sections), review (simplification étape 2), documentation (template index externalisé, dédoublonnage), ux-ui (mini-template specs). Une story groupée pour éviter un éclatement excessif.

## User Story

En tant que mainteneur, je veux appliquer en un seul passage les corrections ciblées qui touchent chacun un seul fichier dans `agents/`, afin de limiter les allers-retours de sync/test et d'avoir un lot cohérent.

## Contexte

Regroupement de plusieurs recommandations isolées, faibles en surface mais haute-valeur en clarté :

| Agent | Recommandations appliquées |
|-------|-----------------------------|
| brainstorm | **B3** (7 méthodes → défaut + alternatives), **O1.1** (STOP étape 4), **O1.2** (ouvrir les 3 approches imposées) |
| architect | **O3.2** (fusion "Format recommandé" et "Processus"), **B4** (élaguer contenu générique) |
| review | **O5.2** (simplifier étape 2 revue auto), **B4** (élaguer "sois factuel" etc.) |
| documentation | **O6.1** (template index → `includes/index-template.md`), **O6.2** (dédoublonner règles vs étapes), **B4** (élaguer) |
| ux-ui | **O7.2** (mini-template specs developer), **B4** (élaguer "belle mais confuse") |

## Règles métier

- Chaque sous-modification est circonscrite à **un** agent ; aucune mutualisation transversale hors de cette story.
- Aucune perte d'information fonctionnelle : les règles conservées ont une version plus concrète ou concise, pas une version dégradée.
- Le nouvel include `includes/index-template.md` (si créé) doit être référencé dans `agents/documentation.md` et rien d'autre.

## Scénarios

### Nominal

- **Étant donné** les 5 agents ci-dessus présentent chacun les défauts listés
- **Quand** j'applique les modifs ciblées et lance `./sync.sh`
- **Alors** les 5 SKILL.md compilés reflètent les améliorations, sans régression fonctionnelle.

### Alternatif

- **Étant donné** le template d'index de documentation est long (~50 lignes) et mérite l'extraction
- **Quand** je le déporte dans `includes/index-template.md` et le référence via `{{include:index-template}}`
- **Alors** `agents/documentation.md` perd ces 50 lignes mais le contenu final compilé reste identique.

### Erreur / refus

- **Étant donné** une modification d'un agent casse un comportement attendu (ex: brainstorm ne propose plus aucune méthode alternative)
- **Quand** un test manuel est effectué
- **Alors** la story est retournée en NO-GO avec le comportement cassé identifié.

## Cas limites

- [ ] La fusion "Format recommandé" + "Processus" dans architect ne doit pas perdre la checklist (Contexte / Contraintes / Hypothèses / Options / Recommandation / Risques / Migration / Validation / Impacts).
- [ ] Le dédoublonnage règles vs étapes dans documentation ne doit pas supprimer une règle si elle est mentionnée dans une étape sous une forme moins impérative.
- [ ] Le mini-template de specs UX pour developer doit rester suffisamment générique pour s'appliquer à différents types de projets.

## Critères d'acceptation

### brainstorm
- [ ] La section "Choix de méthode" propose un **défaut explicite** (recommandation : Starbursting) + 2 alternatives signalées par contexte.
- [ ] Les 7 méthodes restent listées en annexe ou sur demande explicite, pas comme équivalents.
- [ ] Étape 4 "Structuration" mentionne explicitement "propose la suite et attends choix utilisateur" (STOP doux).
- [ ] Phrase "3 approches distinctes" reformulée en "au moins 3 approches, dont idéalement conventionnelle / créative / minimaliste".

### architect
- [ ] Sections "Processus" et "Format recommandé" fusionnées en une checklist unique non redondante.
- [ ] Au moins 2 règles génériques élaguées ou reformulées en règles concrètes.

### review
- [ ] Étape 2 "Revue automatisée" raccourcie à ≤ 6 lignes : "utilise l'outil de review auto si disponible, sinon passe à l'étape 3".
- [ ] Mémoire utilisateur conservée mais concise.
- [ ] Au moins 1 règle générique élaguée.

### documentation
- [ ] Le bloc "Format de l'index" (≈50 lignes) est extrait en `includes/index-template.md` et référencé.
- [ ] Règles dupliquées entre `## Règles` et étapes du processus sont consolidées (pas de mention double).
- [ ] Au moins 1 règle générique élaguée.

### ux-ui
- [ ] Un mini-template "Specs pour le Developer" est ajouté (au moins : format tokens CSS, liste d'états par composant, breakpoints — avec exemple).
- [ ] Au moins 1 phrase slogan ("belle mais confuse") remplacée par une consigne actionnable.

### Global
- [ ] `./sync.sh` passe ; les 5 SKILL.md compilés sont vérifiés.
- [ ] Somme des lignes des 5 agents sources : **diminuée** par rapport à avant la story (cible : −30 à −60 lignes).
- [ ] `CLAUDE.md` mis à jour avec le nouvel include si créé (cf. S-0001 pour le pattern).

## Dépendances

- **Après** S-0001 (blocs Activation factorisés) et S-0003 (Gotchas) pour éviter les conflits de zones modifiées.
- **Avant** S-0008 (release).

## Notes techniques

- Fichiers impactés : `agents/brainstorm.md`, `agents/architect.md`, `agents/review.md`, `agents/documentation.md`, `agents/ux-ui.md`, `includes/index-template.md` (créé si retenu), `CLAUDE.md` (mis à jour si include ajouté).
- Pour éviter la taille explosive de cette story, traiter les 5 agents dans **l'ordre indiqué ci-dessus**, avec un commit par agent pour faciliter une éventuelle revue partielle.

## Instrumentation / mesure

- Avant/après : `wc -l` par agent + diff des SKILL.md compilés.
- Validation manuelle : invocation de chaque agent sur un prompt simple pour vérifier l'absence de régression.

## Questions ouvertes

- Le mini-template UX/Developer gagnerait-il à devenir un include `includes/ux-specs-template.md` ? Proposition : **non** dans un premier temps (utilisé par un seul agent), à reconsidérer si utilisé par plusieurs.
- Pour brainstorm, le défaut "Starbursting" est-il le bon choix ? Proposition : laisser le developer trancher à l'implémentation (c'est un choix éditorial à valider avec l'utilisateur lors de la story).
