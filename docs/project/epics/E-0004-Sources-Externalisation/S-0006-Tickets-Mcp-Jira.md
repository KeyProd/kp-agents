---
title: Mode tickets.mode mcp (JIRA)
date: 2026-04-21
status: TODO
author: product-agent
story-id: S-0006
epic-id: E-0004
---

# S-0006 - Mode `tickets.mode: mcp` (JIRA)

## Résumé

Implémenter le mode externe pour la dimension `tickets` : les epics et stories sont créées/lues/mises à jour dans JIRA via MCP, selon le mapping validé en S-0005. Les agents `product`, `developer` et `review` apprennent à travailler avec cette nouvelle source.

**Bloqué par S-0005** : n'ouvrir cette story que lorsque le spike a statué GO ou GO partiel.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux que les epics et stories de mon projet soient gérées directement dans JIRA, afin que mon équipe voie et collabore sur ces tickets sans friction ni duplication.

## Contexte

- Dépend du résultat de S-0005 : mapping de champs, gestion des statuts, stratégie pour champs custom requis.
- Les agents affectés : `product` (crée epics/stories), `developer` (change status vers IN PROGRESS, écrit en section Implémentation), `review` (change status vers REVIEW/DONE).
- Les agents non affectés : `brainstorm` (ideas restent sur `product.mode`), `architect` (doc technique local), `documentation` (INDEX local), `ux-ui` (écrit dans docs/features, suit `product.mode`).

## Règles métier

- Le mapping précis est défini par le document de S-0005 (`spike-jira-mapping.md`), référence normative.
- Les agents `product`, `developer`, `review` écrivent dans JIRA si `tickets.mode: mcp` est actif, sinon en local (comportement actuel).
- **Pas de cache persistant** : à chaque invocation, l'agent relit depuis JIRA. Pas de fichiers `.json` de cache dans le repo.
- Les **handoffs** entre agents (bloc structuré en chat) restent textuels et ne sont pas persistés dans JIRA — ils sont inter-sessions Claude Code.
- Conservation du lien Epic ↔ Story : JIRA a un issue type `Epic` et un champ « Epic Link » natif → mapping direct.

## Scénarios

### Nominal
- Étant donné un projet avec `tickets.mode: mcp`, `mcp_server: jira`, `project_key: KP`
- Quand l'utilisateur demande à `/kp-agents:product` de créer une nouvelle epic
- Alors l'agent crée un issue de type `Epic` dans le projet JIRA `KP` avec les champs mappés, et ne crée **pas** de fichier local `E-XXXX-*/readme.md`.

### Alternatif
- Étant donné une epic existante dans JIRA
- Quand l'utilisateur demande à `/kp-agents:product` de découper une feature en stories sous cette epic
- Alors l'agent cherche l'epic JIRA (par titre ou ID), crée les stories enfants avec le « Epic Link » vers l'epic parente.

### Erreur / refus
- Étant donné le MCP JIRA est down (hors service, token expiré)
- Quand un agent tente une opération
- Alors l'agent warn explicitement, propose de (a) réessayer, (b) basculer ponctuellement en local pour cette session, (c) annuler l'opération.

## Cas limites

- [ ] Epic `kp-agents` actuelle vs epic JIRA : comment migrer des epics locales déjà existantes ? → **Hors scope V1**, migration manuelle si l'utilisateur le souhaite.
- [ ] Caractères spéciaux dans le titre (accents, emojis) : JIRA gère, à tester
- [ ] Stories marquées `DONE` : l'archivage `_archives/` local n'a pas d'équivalent côté JIRA (statut `Done` suffit)
- [ ] Lecture d'un ticket qui a été modifié hors agent : les agents lisent toujours la version fraîche, pas de merge conflit
- [ ] Projet JIRA avec workflow custom (ex: `Backlog → To Do → In Progress → Review → Done` au lieu du workflow standard) : mapping configuré côté `.kp-agents.yml` ?

## Critères d'acceptation

- [ ] Mapping implémenté conformément au document de S-0005
- [ ] `/kp-agents:product` peut créer une epic dans JIRA via MCP
- [ ] `/kp-agents:product` peut créer une story sous une epic JIRA existante
- [ ] `/kp-agents:developer` peut transitionner une story JIRA vers `In Progress` puis `Review`
- [ ] `/kp-agents:review` peut transitionner une story JIRA vers `Done`
- [ ] Les agents affichent clairement l'ID et le lien JIRA des tickets manipulés dans leurs réponses
- [ ] Gestion d'erreur MCP : warn clair + options présentées à l'utilisateur
- [ ] Test manuel end-to-end : créer epic → story → passer IN PROGRESS → passer REVIEW → passer DONE, 100% via les agents, 100% reflété dans JIRA
- [ ] Test manuel non-régression : projet en `tickets.mode: local` continue de fonctionner comme avant
- [ ] Documentation du mapping dans `includes/sources-config.md` ou document dédié référencé

## Dépendances

- **S-0005** (spike validé — bloquant)
- **S-0001, S-0002, S-0003** (fondations, agent setup, intégration)

## Notes techniques

- L'utilisateur doit avoir configuré le serveur MCP JIRA dans ses `settings.json` Claude Code avant d'activer `tickets.mode: mcp`. L'agent `setup` le rappelle mais ne configure pas le MCP lui-même.
- Risque de couplage fort au schéma MCP : prévoir une abstraction minimale dans `sources-config.md` pour faciliter un futur support d'autres systèmes (Linear, etc.).
- Les identifiants `S-XXXX` et `E-XXXX` `kp-agents` n'ont pas de sens en mode MCP (JIRA a ses propres IDs). En mode MCP, utiliser les IDs JIRA partout dans les handoffs et références. Laisser l'utilisateur décider de conserver ou non les préfixes `E-XXXX` dans les titres.

## Instrumentation / mesure

- Temps de réponse d'une création de ticket (baseline attendu : < 3s via MCP)
- Nombre d'appels MCP par opération courante (indicateur de sur-consommation d'appels)

## Questions ouvertes

- Faut-il persister un fichier d'index `tickets.json` local pour suivre la correspondance `S-XXXX` ↔ JIRA ID ? → **Probablement non**, les agents demandent l'ID JIRA ou le retrouvent par recherche. À trancher lors de l'implémentation.

## Implémentation

- Fichiers modifiés : `includes/sources-config.md` (logique MCP), `agents/product.md`, `agents/developer.md`, `agents/review.md`, potentiellement un nouvel include `tickets-mcp-mapping.md`
- Commandes de test : MCP JIRA sandbox configuré + scénario E2E manuel
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
