---
title: Factorisation des blocs partagés via includes
date: 2026-04-18
status: TODO
author: product-agent
story-id: S-0001
epic-id: E-0005
---

# S-0001 - Factorisation des blocs partagés via includes

## Résumé

Créer deux nouveaux includes (`activation.md`, `dependency-versions.md`) et les référencer dans les 7 agents afin d'éliminer la duplication et l'asymétrie actuelles.

## User Story

En tant que mainteneur du projet kp-agents, je veux que les blocs répétés à l'identique dans plusieurs agents soient factorisés dans `includes/`, afin d'avoir une source de vérité unique et garantir que tous les agents se comportent de la même façon sur ces points.

## Contexte

- Recommandations couvertes : **T1** (bloc Activation dupliqué 7× et tronqué dans review/ux-ui), **T3** (règle "Versions des dépendances" dupliquée dans architect, developer, review).
- Priorité : **P1** dans `docs/agents-review.md`.
- Hypothèse à vérifier en début de story (risque R3) : `sync.sh` résout bien n'importe quel nom `{{include:xxx}}`.

## Règles métier

- Les includes sont résolus à la compilation par `sync.sh` ; le contenu final se retrouve inlined dans `plugins/` et `dist/`.
- Le bloc "Activation et persistance" doit être **identique** pour les 7 agents (5 puces obligatoires : annonce, persistance, changement de sujet, hors périmètre, distinction faits/hypothèses).
- L'include `dependency-versions.md` ne doit concerner que architect, developer et review (autres agents non impactés par la gestion des dépendances).

## Scénarios

### Nominal

- **Étant donné** les 7 agents dans `agents/` utilisent 5 puces verbatim différentes pour "Activation et persistance"
- **Quand** je crée `includes/activation.md` et remplace le bloc par `{{include:activation}}` dans les 7 agents puis lance `./sync.sh --dist-only`
- **Alors** les 7 fichiers `plugins/kp-agents/skills/<nom>/SKILL.md` contiennent exactement le même bloc Activation (5 puces identiques), et `dist/cursor/` + `dist/codex/` aussi.

### Alternatif

- **Étant donné** `review.md` et `ux-ui.md` avaient une version tronquée (3 puces) du bloc Activation
- **Quand** je remplace leur bloc tronqué par `{{include:activation}}`
- **Alors** le bloc final compilé contient les 5 puces complètes (récupération automatique de la cohérence).

### Erreur / refus

- **Étant donné** `sync.sh` ne supporte pas le nouvel include `{{include:activation}}` (hypothèse R3 invalidée)
- **Quand** je tente la compilation
- **Alors** l'erreur doit être détectée avant tout commit : `sync.sh` échoue ou l'include reste non résolu dans les artefacts, et la story est remontée en dépendance technique (modifier `sync.sh` d'abord).

## Cas limites

- [ ] Vérifier que les agents qui utilisaient déjà un include (`guardrails`, `handoff`, `docs-structure`) ne sont pas impactés par l'ordre des includes.
- [ ] Vérifier que `dependency-versions` n'est pas inséré dans les agents non concernés (brainstorm, product, documentation, ux-ui).
- [ ] Vérifier l'idempotence : relancer `sync.sh` une deuxième fois produit le même résultat.
- [ ] Vérifier que `.installed-agents` reste cohérent (les 7 agents toujours listés).

## Critères d'acceptation

- [ ] `includes/activation.md` existe et contient les 5 puces canoniques en une seule section (sans titre `##`, car c'est le corps à injecter — ou avec titre `## Activation et persistance` selon convention existante des autres includes).
- [ ] `includes/dependency-versions.md` existe et contient la règle unique "Versions des dépendances — recherche internet" telle que présente aujourd'hui dans architect/developer/review.
- [ ] Les 7 fichiers dans `agents/` remplacent leur bloc Activation par `{{include:activation}}`.
- [ ] Les 3 fichiers `architect.md`, `developer.md`, `review.md` remplacent leur règle "Versions des dépendances" par `{{include:dependency-versions}}`.
- [ ] `./sync.sh --dist-only` passe sans erreur et génère `plugins/kp-agents/skills/*/SKILL.md` + `dist/` à jour.
- [ ] Diff inspection : le bloc Activation compilé est strictement identique entre les 7 skills générés.
- [ ] Aucun bloc "Activation" résiduel dans `agents/*.md` après la story.
- [ ] `CLAUDE.md` mis à jour avec les deux nouveaux includes dans la liste "Includes" (section "Includes" du fichier, relais éventuel à `/kp-agents:documentation`).

## Dépendances

- Aucune dépendance inter-story dans l'epic : cette story peut démarrer en premier.
- Dépendance technique à valider : compatibilité `sync.sh` avec n'importe quel nom d'include (cf. R3).

## Notes techniques

- Fichiers impactés : `includes/activation.md` (créé), `includes/dependency-versions.md` (créé), les 7 `agents/*.md`, `plugins/kp-agents/skills/*/SKILL.md` (régénérés), `dist/` (régénéré), `CLAUDE.md` (modifié).
- Ne pas oublier la ligne d'index `## Includes` dans `CLAUDE.md` + le tableau "Stratégie d'inclusion par agent".
- Bump `plugin.json` **non nécessaire** pour cette story isolément — sera fait en S-0008 en regroupement.

## Instrumentation / mesure

- Mesure qualitative : comparaison `diff` entre les 7 SKILL.md générés sur la portion "Activation" → doit être vide.
- Pas de KPI runtime à ce stade (l'effet sur le déclenchement sera mesurable via B6 en S-0007).

## Questions ouvertes

- Convention de structure interne des includes : avec ou sans titre `##` en tête ? Vérifier les includes existants (`guardrails.md`, `handoff.md`) pour aligner le style.
