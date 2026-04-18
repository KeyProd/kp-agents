---
title: Ajout des sections Gotchas par agent
date: 2026-04-18
status: TODO
author: product-agent
story-id: S-0003
epic-id: E-0005
---

# S-0003 - Ajout des sections Gotchas par agent

## Résumé

Ajouter une section `## Gotchas` (5 à 10 items) dans chaque agent, capturant les faits contre-intuitifs et les règles projet spécifiques qu'un modèle ne peut pas déduire de son entraînement général.

## User Story

En tant qu'agent exécuté par Claude Code, je veux disposer d'une liste de gotchas projet — règles spécifiques, faits contre-intuitifs, erreurs à éviter — afin de ne pas reproduire les erreurs que le modèle aurait naturellement faites sans cette précision.

## Contexte

- Recommandation couverte : **B2** dans `docs/agents-review.md` (annexe, section B.2).
- Priorité : **P1**.
- Les gotchas candidats sont déjà listés dans la review (transversaux + par agent) — cette story consiste à les rédiger définitivement et à les insérer.

## Règles métier

- Section `## Gotchas` placée avant `## Règles` dans chaque agent (les gotchas sont des règles spécifiques à haute valeur, donc en tête).
- Max 10 items par agent ; cap à respecter strictement pour éviter l'enflure.
- Chaque gotcha est **observable** (il correspond à une erreur réelle à éviter), pas un conseil générique.
- Les gotchas transversaux (communs à plusieurs agents) peuvent être factorisés dans un include `includes/gotchas-transverses.md` si la duplication dépasse 3 agents.

## Scénarios

### Nominal

- **Étant donné** un agent n'a aujourd'hui pas de section `## Gotchas`
- **Quand** j'ajoute 5 à 10 gotchas ancrés dans l'usage projet (cf. review B.2) au-dessus de `## Règles`
- **Alors** le SKILL.md compilé contient cette section et elle est visible dans tous les artefacts (plugin, cursor, codex).

### Alternatif

- **Étant donné** plusieurs agents partagent des gotchas identiques (ex: "pas de worktree", "INDEX.md appartient à documentation")
- **Quand** je détecte une duplication ≥ 3 agents
- **Alors** je crée `includes/gotchas-transverses.md` et je l'inclue dans les agents concernés via `{{include:gotchas-transverses}}`, en complément de leur section `## Gotchas` locale.

### Erreur / refus

- **Étant donné** une proposition de gotcha formulée de manière générique ("écris du code propre", "pense à la sécurité")
- **Quand** la story est reviewée
- **Alors** le gotcha est refusé : les items doivent être concrets, observables, spécifiques au projet.

## Cas limites

- [ ] Cap à 10 items respecté : refuser les ajouts au-delà, repousser en backlog ou arbitrer les items existants.
- [ ] Gotchas qui se contredisent entre deux agents : doit être détecté et arbitré (ex: developer "peut modifier `docs/`" vs review "ne modifie JAMAIS").
- [ ] Gotcha qui ferait double emploi avec une règle existante : éviter le doublon, supprimer l'ancienne règle si elle est clairement mieux formulée en gotcha.

## Critères d'acceptation

- [ ] Les 7 agents possèdent une section `## Gotchas` positionnée avant `## Règles`.
- [ ] Chaque section contient entre 5 et 10 items.
- [ ] Chaque item est concret (cite un fichier, une commande, un workflow, un état) et observable.
- [ ] Les gotchas transversaux dupliqués ≥ 3 agents sont factorisés dans `includes/gotchas-transverses.md`.
- [ ] `./sync.sh` régénère correctement ; les artefacts contiennent la section dans le même ordre.
- [ ] Au moins les gotchas minimaux suivants sont présents :
  - **Transversal** : "ne jamais écrire dans `plugins/kp-agents/skills/` ni `dist/`", "INDEX.md appartient exclusivement à documentation", "S-0001 local à chaque epic / E-0001 global", "epics archivées en `_archives/` — lecture seule".
  - **Developer** : "pas de worktree git", "cadrage config branche/commit/PR avant chargement de contexte".
  - **Review** : "refuse la review si pas de section `## Implémentation`", "ne modifie jamais le code source".
  - **Documentation** : "`README.md` et `CLAUDE.md` font partie du périmètre et de l'INDEX", "Mermaid : pas de guillemets dans labels d'arêtes, pas de texte multi-lignes dans les noeuds".

## Dépendances

- **Bloque** S-0008 (release v0.2.0) : les gotchas font partie de la release.
- **Dépend** potentiellement de S-0001 si un include commun est utilisé (ordre conseillé : S-0001 → S-0003).
- N'entre pas en conflit avec S-0002 (zones distinctes : frontmatter vs corps).

## Notes techniques

- Fichiers impactés : les 7 `agents/*.md`, potentiellement `includes/gotchas-transverses.md` (créé).
- Ordre d'insertion recommandé dans chaque agent : `## Processus` → `## Output` → `## Gotchas` → `## Règles` → `{{include:guardrails}}` → ... Cela met les gotchas juste après la partie procédurale, avant les règles "meta".

## Instrumentation / mesure

- Revue manuelle : chaque gotcha doit répondre oui à la question "un modèle sans cette instruction ferait-il cette erreur ?" (cf. agentskills.io best-practices).
- Historique : tenir à jour une note interne (issue GitHub ?) quand un nouveau gotcha émerge de l'usage → à intégrer périodiquement.

## Questions ouvertes

- Faut-il inclure des gotchas liés aux plateformes distribuées (Cursor, Codex) dans tous les agents, ou seulement dans ceux qui s'exécutent différemment ? Proposition : uniquement dans les agents qui interagissent avec des outils plateforme-spécifiques (ex: `developer` avec `/simplify`).
- Certains gotchas actuels sont formulés en règles (ex: "Pas de worktree" dans developer) — faut-il les déplacer depuis `## Règles` vers `## Gotchas` ou les dupliquer ? Proposition : **déplacer** (éviter la duplication), car c'est bien un gotcha.
