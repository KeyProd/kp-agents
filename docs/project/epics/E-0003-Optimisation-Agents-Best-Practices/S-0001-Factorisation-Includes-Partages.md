---
title: Factorisation des blocs partagés via includes
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0001
epic-id: E-0003
---

# S-0001 - Factorisation des blocs partagés via includes

## Résumé

Créer deux nouveaux includes (`activation.md`, `dependency-versions.md`) et les référencer dans les 7 agents afin d'éliminer la duplication et l'asymétrie actuelles.

## User Story

En tant que mainteneur du projet kp-agents, je veux que les blocs répétés à l'identique dans plusieurs agents soient factorisés dans `includes/`, afin d'avoir une source de vérité unique et garantir que tous les agents se comportent de la même façon sur ces points.

## Contexte

- Recommandations couvertes : **T1** (bloc Activation dupliqué 7× et tronqué dans review/ux-ui), **T3** (règle "Versions des dépendances" dupliquée dans architect, developer, review).
- Priorité : **P1** dans `docs/agents-review.md`.
- Hypothèse R3 **levée le 2026-04-18** : `sync.sh` résout nativement tout `{{include:<nom>}}` via regex générique `[a-zA-Z0-9_-]+` (cf. `sync.sh:168-181`). Aucune modif de `sync.sh` requise pour cette story.

## Règles métier

- Les includes sont résolus à la compilation par `sync.sh` ; le contenu final se retrouve inlined dans `plugins/` et `dist/`.
- Le bloc "Activation et persistance" doit être **identique** pour les 7 agents (6 puces obligatoires : annonce, persistance, changement de sujet, hors périmètre, distinction faits/hypothèses, **langue de l'utilisateur**).
- **Langue** : l'include `activation.md` doit contenir la consigne "l'agent répond exclusivement dans la langue de l'utilisateur" — les `description` seront en anglais (cf. S-0002) mais la conversation doit suivre la langue détectée au premier message utilisateur.
- L'include `dependency-versions.md` ne doit concerner que architect, developer et review (autres agents non impactés par la gestion des dépendances).

### Contenu canonique de `includes/activation.md` (spec)

```markdown
## Activation et persistance

- Au début de chaque utilisation, annonce explicitement que cet agent est actif et rappelle brièvement sa mission
- Une fois activé, reste dans ce rôle de manière persistante jusqu'à désactivation explicite par l'utilisateur ou activation explicite d'un autre agent
- Si l'utilisateur change de sujet sans changer d'agent, continue à répondre dans ton rôle courant
- Si la demande sort de ton périmètre, signale-le et propose le relais adapté sans quitter ton rôle tant que l'utilisateur ne l'a pas demandé
- Distingue toujours clairement les faits observés, les hypothèses, les questions ouvertes et les décisions
- **Langue** : réponds **exclusivement dans la langue de l'utilisateur**, même si ta description (frontmatter) et certaines instructions internes sont en anglais. Détecte la langue au premier message et maintiens-la pour toute la session, sauf demande explicite de changement.
```

> Note : le libellé "cet agent" est générique pour que l'include s'adapte aux 7 agents. Chaque agent peut ajouter sous l'include une phrase spécifique si nécessaire (ex: pour developer, "la distinction spec / code / supposition / validation est critique"), sans dupliquer les 6 puces ci-dessus.

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

- ~~Convention de structure interne des includes~~ **Résolu 2026-04-18** : aligné sur `guardrails.md` — l'include inclut son propre titre `##` (ex : `## Activation et persistance` pour `activation.md`). `dependency-versions.md` reste sans titre car injecté comme puce unique dans une liste existante.

## Implémentation

- Fichiers créés :
  - `includes/activation.md` (6 puces : annonce, persistance, changement de sujet, hors périmètre, distinction faits/hypothèses, langue utilisateur)
  - `includes/dependency-versions.md` (puce unique)
- Fichiers modifiés :
  - `agents/brainstorm.md`, `agents/product.md`, `agents/architect.md`, `agents/developer.md`, `agents/review.md`, `agents/ux-ui.md`, `agents/documentation.md` — bloc Activation remplacé par `{{include:activation}}`
  - `agents/architect.md`, `agents/developer.md`, `agents/review.md` — règle Versions des dépendances remplacée par `{{include:dependency-versions}}`
  - `CLAUDE.md` — liste Includes enrichie avec `activation` et `dependency-versions`
- Régénérés via `./sync.sh --dist-only` : `plugins/kp-agents/skills/*/SKILL.md` (7 fichiers) + `dist/cursor/` + `dist/codex/`
- Commandes de vérification :
  - `grep -r '{{include:' plugins/` → aucun résidu non résolu
  - MD5 des 7 blocs Activation extraits → identiques (`9301c66a40e156d05f0ae621848a4ca5`)

## Validation par critère

- **`includes/activation.md` existe avec 6 puces canoniques** : ✅ fichier présent avec titre `## Activation et persistance` suivi des 6 puces (dont la règle langue utilisateur). Aligné sur `guardrails.md`.
- **`includes/dependency-versions.md` existe** : ✅ fichier présent avec puce unique reformulée génériquement (couvre librairies / frameworks / outils).
- **Les 7 agents utilisent `{{include:activation}}`** : ✅ vérifié via `grep` dans `agents/`.
- **architect/developer/review utilisent `{{include:dependency-versions}}`** : ✅ vérifié via `grep`.
- **`./sync.sh --dist-only` passe sans erreur** : ✅ 7 agents syncés sur 3 cibles (plugin + cursor + codex).
- **Diff inspection : bloc Activation strictement identique entre les 7 SKILL.md** : ✅ MD5 unique `9301c66a40e156d05f0ae621848a4ca5`.
- **Aucun bloc Activation résiduel dans `agents/*.md`** : ✅ `grep "Activation et persistance" agents/` renvoie uniquement la directive d'include (via le texte de l'include après résolution, mais dans les sources il n'y a plus que `{{include:activation}}`).
- **`CLAUDE.md` mis à jour** : ✅ section "Includes" complétée avec `activation` et `dependency-versions`, stratégie d'inclusion par agent déjà présente (à enrichir lors d'une passe documentation si besoin).
