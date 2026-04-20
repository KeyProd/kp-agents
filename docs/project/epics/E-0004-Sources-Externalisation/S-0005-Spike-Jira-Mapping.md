---
title: Spike mapping story-markdown vers ticket JIRA
date: 2026-04-21
status: TODO
author: product-agent
story-id: S-0005
epic-id: E-0004
---

# S-0005 - Spike mapping story-markdown ↔ ticket JIRA

## Résumé

Spike technique de 2-4 heures pour valider la **faisabilité** du mapping entre la structure d'une story `kp-agents` (markdown + frontmatter YAML + sections Gherkin + handoff) et un ticket JIRA standard via le MCP JIRA. Le résultat conditionne l'implémentation de S-0006.

Ce n'est pas une story d'implémentation : elle produit un **rapport de décision** (GO / NO-GO / GO partiel) et un **document de mapping** versionné.

## User Story

En tant que mainteneur du projet, je veux savoir si le modèle de story `kp-agents` peut être fidèlement représenté dans JIRA via MCP, afin de décider si j'implémente S-0006 dans cette epic ou si je scinde.

## Contexte

- Hypothèse critique H1 de l'epic : faisabilité du mapping sans perte d'info structurelle.
- Le MCP JIRA standard expose les opérations `getJiraIssue`, `createJiraIssue`, `editJiraIssue`, `searchJiraIssuesUsingJql`, `transitionJiraIssue`.
- Les stories `kp-agents` ont une structure riche : frontmatter YAML (story-id, epic-id, status, author, date, title), sections markdown (Résumé, User Story, Contexte, Règles métier, Scénarios nominal/alternatif/erreur, Cas limites, Critères d'acceptation, Dépendances, Notes techniques, Instrumentation, Questions ouvertes, Implémentation, Validation par critère).

## Règles métier

- Le spike ne crée **pas** de ticket pérenne : tout ce qui est créé dans JIRA pendant le spike doit être supprimé ou fermé en fin de spike.
- Le spike est réalisé sur une **instance JIRA sandbox** ou un projet JIRA dédié « SPIKE » — **ne jamais** le mener sur le projet JIRA de production d'une équipe.
- Le rapport de spike doit trancher : GO (mapping 1:1 fidèle), GO partiel (perte d'info acceptable, liste ce qui est perdu), NO-GO (perte d'info inacceptable, recommander alternative).

## Scénarios

### Nominal
- Étant donné une story `kp-agents` réelle (ex: S-0001 de cette epic)
- Quand on la crée dans JIRA via MCP, puis on la relit via MCP, puis on la re-compare au fichier source
- Alors on obtient un round-trip fidèle (tous les champs clés préservés).

### Alternatif
- Étant donné une story complexe avec scénarios Gherkin et blocs de code
- Quand on la crée dans JIRA
- Alors on observe la manière dont JIRA rend (ou mutile) le markdown : identifier ce qui passe, ce qui est transformé, ce qui est perdu.

### Erreur / refus
- Étant donné une tentative de créer une story dans JIRA avec un champ custom requis non renseigné (ex: « Story Points » obligatoire)
- Quand l'appel MCP échoue
- Alors documenter la liste des champs requis côté JIRA et la stratégie de gestion (valeurs par défaut ? prompt utilisateur ?).

## Cas limites

- [ ] Mapping de l'Epic : JIRA a un issue type `Epic` → mapping direct. Valider que les liens Epic ↔ Story sont préservés.
- [ ] Statuts : `TODO | IN PROGRESS | REVIEW | DONE` côté `kp-agents` vs workflow JIRA variable côté client (ex: `To Do | In Progress | In Review | Done | Cancelled`). Documenter le mapping.
- [ ] Frontmatter YAML : où le stocker dans JIRA (custom fields, description, labels) ?
- [ ] Sections structurées (Scénarios, Cas limites) : tout dans le champ Description, ou éclater sur plusieurs champs ?
- [ ] Longueur maximum du champ Description dans JIRA (à vérifier)

## Critères d'acceptation

- [ ] Document de spike créé : `docs/project/epics/E-0004-Sources-Externalisation/spike-jira-mapping.md` (dans le repo ou externalisé selon config)
- [ ] Test round-trip réalisé sur au moins **2 stories réelles** (dont 1 avec scénarios complexes) et **1 epic**
- [ ] Décision tranchée : GO / GO partiel / NO-GO avec justification
- [ ] Si GO partiel : liste exhaustive des pertes d'information et stratégie de mitigation (ex: champ `kp-raw` custom contenant le markdown source)
- [ ] Proposition de schéma de mapping : tableau `champ kp-agents` ↔ `champ JIRA` pour chaque élément
- [ ] Tickets créés pendant le spike supprimés ou clôturés à la fin
- [ ] Recommandation explicite sur la suite : (a) GO sur S-0006 en l'état, (b) GO sur S-0006 avec ajustements, (c) scinder l'epic (E-A sans tickets MCP, E-B dédiée)

## Dépendances

- **S-0001** (schéma de config) pour déclarer `tickets.mode: mcp` dans un projet sandbox
- **S-0002** (setup) non bloquant mais utile pour configurer le sandbox via setup plutôt qu'à la main
- Accès à un **serveur MCP JIRA** opérationnel (sandbox ou projet de test dédié)

## Notes techniques

- Timeboxer strictement : 2h en première passe, maximum 4h. Au-delà, clôturer avec une décision « NO-GO » ou « GO avec scinder l'epic ».
- Utiliser une story **existante** de E-0004 comme cobaye (pas besoin de créer des stories fictives).
- Documenter les appels MCP exacts utilisés pour permettre une automatisation ultérieure.

## Instrumentation / mesure

- Temps passé sur le spike (pour calibrer les futurs spikes)
- Nombre d'allers-retours MCP pour obtenir un mapping fonctionnel (indicateur de complexité)

## Questions ouvertes

- La structure des champs custom JIRA varie selon le projet client. Le mapping doit-il être **configurable par projet** (`.kp-agents.yml` contient la matrice de mapping) ou **en dur** avec mapping générique ? → **À trancher dans ce spike.**

## Implémentation

- Fichiers créés / modifiés : `docs/project/epics/E-0004-Sources-Externalisation/spike-jira-mapping.md` (rapport)
- Commandes de test : appels MCP JIRA via Claude Code, comparaison diff entre source et récupération
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation du spike_
