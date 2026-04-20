---
title: Intégration sources-config dans les 7 agents existants
date: 2026-04-21
status: TODO
author: product-agent
story-id: S-0003
epic-id: E-0004
---

# S-0003 - Intégration sources-config dans les 7 agents existants

## Résumé

Injecter l'include `sources-config` dans les 7 agents existants (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`), rendre leur section « Convention de sortie » conditionnelle selon la config du projet, et implémenter l'auto-redirect vers `/kp-agents:setup` quand la config est manquante ou incomplète.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux que chaque agent respecte la configuration des sources du projet courant, afin que mes fichiers produit aillent au bon endroit (local ou externe) sans intervention manuelle.

## Contexte

- Story bloquée par S-0001 (include) et S-0002 (agent setup).
- Modification à minima invasive : ajouter l'include + adapter la section « Convention de sortie » de chaque agent.
- Les agents restent rétro-compatibles : sans `.kp-agents.yml`, leur comportement est identique à aujourd'hui.

## Règles métier

- Chaque agent lit la config en début de session (après l'audit initial type « rôle et persistance »).
- Si la config est absente → mode local par défaut, aucun prompt.
- Si la config est présente mais incomplète pour le périmètre de l'agent → proposer `/kp-agents:setup`, continuer sans bloquer si l'utilisateur refuse.
- La section « Convention de sortie - Répertoire docs/ » de chaque agent précise désormais :
  - Les chemins externalisables (selon la config `product.mode` / `tickets.mode`)
  - Les chemins toujours locaux (architecture, doc technique)
  - La logique de fallback write

## Scénarios

### Nominal
- Étant donné un projet avec `product.mode: external` et `product.path` configuré
- Quand l'utilisateur invoque `/kp-agents:product` pour créer une epic
- Alors l'agent écrit dans `<product.path>/project/epics/E-XXXX-.../readme.md` (et non dans `./docs/`).

### Alternatif
- Étant donné un projet sans `.kp-agents.yml`
- Quand l'utilisateur invoque n'importe quel agent
- Alors l'agent écrit dans `./docs/` (comportement actuel, non-régression).

### Erreur / refus
- Étant donné `product.mode: external` mais le chemin externe est en lecture seule (écriture refusée par l'OS)
- Quand l'agent tente d'écrire une nouvelle story
- Alors l'agent warn explicitement, écrit dans `./docs/` en fallback, et indique le chemin exact du fichier écrit.

## Cas limites

- [ ] Agent `developer` travaille sur du code : ne lit que la doc produit externe, ses propres outputs (stories en IN PROGRESS) suivent la config `tickets.mode`
- [ ] Agent `architect` produit toujours en local (périmètre technique), ignore complètement `product.mode`
- [ ] Agent `documentation` maintient `docs/INDEX.md` : INDEX reste **toujours local** (référence locale du repo code)
- [ ] Agent `brainstorm` écrit dans `ideas/` : si `product.mode: external`, les ideas vont dans le chemin externe

## Critères d'acceptation

- [ ] Les 7 agents (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`) incluent `{{include:sources-config}}` dans leur frontmatter body
- [ ] La section « Convention de sortie » de chaque agent est mise à jour pour référencer la logique de config (pas de duplication — l'include centralise)
- [ ] Auto-redirect implémenté : si un agent détecte config manquante/incomplète, il propose `/kp-agents:setup` dès son premier message, sans bloquer
- [ ] Pour chaque agent, matrice claire documentée : quels outputs sont externalisables, quels restent locaux
- [ ] Test manuel non-régression : sur un projet sans config (ex: `kp-agents` lui-même), chaque agent se comporte exactement comme aujourd'hui
- [ ] Test manuel mode mixte : projet avec `product.mode: external`, `tickets.mode: local` → `/kp-agents:brainstorm` écrit externe, `/kp-agents:developer` écrit local, `/kp-agents:architect` écrit local
- [ ] `./sync.sh` produit des SKILL.md cohérents pour les 7 agents (hash valide, taille raisonnable)
- [ ] Auto-bump patch déclenché par `./sync.sh` si changement de contenu

## Dépendances

- **S-0001** (include créé)
- **S-0002** (agent setup invocable pour l'auto-redirect)

## Notes techniques

- Ne **jamais** modifier directement `plugins/kp-agents/skills/` — toujours éditer `agents/*.md` puis lancer `./sync.sh`.
- L'include doit rester **court** : il est inliné 8 fois. Chaque ligne superflue coûte.
- Les chemins dans les agents doivent rester des **placeholders logiques** (`<product-root>/ideas/`), résolus par l'include.
- L'agent `documentation` a un rôle spécial sur `INDEX.md` : ce fichier reste toujours local. À documenter explicitement dans son agent.

## Instrumentation / mesure

- Nombre de lignes ajoutées à chaque agent (attendu : ~5-10 lignes nettes)
- Taille finale de chaque SKILL.md généré (comparatif avant/après)

## Questions ouvertes

- Est-ce que l'agent `architect` a besoin de savoir lire la doc produit externe (pour référence) ? → **Oui**, il lit tout en mode externe si configuré, mais écrit toujours en local.

## Implémentation

- Fichiers modifiés : `agents/brainstorm.md`, `agents/product.md`, `agents/architect.md`, `agents/developer.md`, `agents/review.md`, `agents/documentation.md`, `agents/ux-ui.md`
- Commandes de test : `./sync.sh` + invocations manuelles par agent dans un projet test
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
