---
title: Sources Externalisation
date: 2026-04-21
status: done
author: product-agent
epic-id: E-0004
phase: 3
---

# E-0004 - Sources Externalisation

## Résumé

Rendre les agents `kp-agents` configurables pour supporter des **sources de documentation et de tickets externes** au repo courant, tout en préservant le mode 100% local comme comportement par défaut. Ajout d'un 8ᵉ agent `setup` dédié à la configuration projet.

## Objectif

Permettre à un utilisateur de travailler avec `kp-agents` sur un projet dont :
- la doc produit vit sur OneDrive (partagée entre plusieurs projets d'une même entité),
- les tickets (epics + stories) sont gérés dans JIRA via MCP,

sans jamais modifier manuellement les agents, et **sans casser** les projets existants qui n'ont aucune config.

## Problème adressé

Aujourd'hui, les agents `kp-agents` supposent que toute la documentation vit dans le dossier `docs/` du repo courant. Cette hypothèse ne tient plus dès qu'on veut :
- partager la vision produit entre plusieurs repos techniques (monorepo éclaté, multi-services d'un même produit),
- centraliser la roadmap sur OneDrive où travaillent les PM non-dev,
- déporter le suivi des tickets dans JIRA où se trouvent déjà les équipes.

Sans solution, l'utilisateur est forcé soit de dupliquer manuellement la doc, soit de ne pas utiliser `kp-agents` sur ces projets.

## Résultat attendu

- Un fichier `.kp-agents.yml` (commité) déclare la politique de sources du projet (`product.mode`, `tickets.mode`)
- Un fichier `.kp-agents.local.yml` (gitignoré) contient les chemins machine-spécifiques (OneDrive)
- Un include `sources-config` est injecté dans les 8 agents par `sync.sh`
- Un agent `setup` invocable via `/kp-agents:setup` configure le projet interactivement
- Les agents lisant de la doc produit utilisent le chemin externe si configuré, sinon le `docs/` local
- Les agents écrivant de la doc produit tentent l'écriture externe, tombent en fallback local avec warn en cas de permission refusée
- Les agents gérant des tickets (product, developer, review) savent créer/lire via MCP JIRA si configuré
- Les 7 agents existants redirigent vers `/kp-agents:setup` quand la config est manquante ou incomplète

## Périmètre

### Inclus
- Schéma des fichiers `.kp-agents.yml` et `.kp-agents.local.yml`
- Include partagé `sources-config` (lecture config + résolution de chemin + logique de fallback)
- Nouvel agent `setup` (périmètre initial : sources uniquement)
- Intégration de l'include dans les 7 agents existants + l'agent `setup` lui-même
- Mode `product.mode: external` (OneDrive ou tout chemin filesystem)
- Spike de validation du mapping story-markdown ↔ ticket JIRA
- Mode `tickets.mode: mcp` (JIRA en cible initiale)
- Extension de `setup` aux préférences Git projet (nom de branche, commit auto oui/non, push oui/non)
- Documentation à jour (README, CLAUDE.md, docs/agents.md) et release `v1.1.0`

### Exclu
- Externalisation de la documentation **technique** (`docs/architect.md`, `docs/features/*/architect.md`) — reste toujours locale au repo code
- Support d'autres MCP que JIRA pour les tickets (Linear, Notion, ClickUp…) — extensible plus tard mais hors scope V1
- Synchronisation bidirectionnelle automatique (ex: modifier un ticket JIRA hors agent et le voir apparaître dans le repo) — les agents lisent à chaque invocation, pas de cache persistant
- UI graphique pour la configuration — l'agent `setup` reste conversationnel
- Préférences utilisateur **globales** (au niveau machine) — tout est au niveau projet pour cette epic
- Migration automatique de projets existants vers le mode externe — opération manuelle assistée par `setup`

## Règles métier concernées

- **Non-régression absolue** : un projet sans `.kp-agents.yml` doit se comporter exactement comme aujourd'hui
- **Confidentialité des chemins** : `.kp-agents.local.yml` est ajouté au `.gitignore` du projet (jamais commité)
- **Granularité indépendante** : `product.mode` et `tickets.mode` sont découplés (tous les 4 combinaisons valides)
- **Mode lecture seule produit** : `product.access: read-only` (pertinent uniquement si `mode: external`) bloque toute écriture d'outputs produit, y compris le fallback local — cas d'usage OneDrive partagé maintenu par un PM humain
- **Périmètre externalisable de `product`** : `docs/ideas/`, `docs/product.md`, `docs/features/*/product.md`, `docs/project/roadmap.md`
- **Périmètre externalisable de `tickets`** : `docs/project/epics/` (readme d'epic + stories)
- **Toujours local** : `docs/architect.md`, `docs/features/*/architect.md`, `docs/INDEX.md`, toute la doc technique
- **Fallback write** : en mode externe, tentative d'écriture sur la source externe ; si échec (permission, indisponibilité) → écriture locale dans `docs/` + warn explicite à l'utilisateur
- **Redirection vers setup** : un agent détectant une config manquante ou incohérente propose `/kp-agents:setup` (ne bloque pas l'utilisateur, la redirection est une suggestion)

## Dépendances

- **MCP JIRA** : l'utilisateur doit avoir configuré un serveur MCP JIRA dans ses `settings.json` Claude Code pour activer `tickets.mode: mcp`. L'agent `setup` ne configure pas le MCP lui-même, il le référence.
- **Structure existante** : convention `docs/` documentée dans `CLAUDE.md` et `includes/docs-structure.md` — les modifications doivent rester rétro-compatibles.
- **Mécanique `sync.sh`** : l'ajout d'un 8ᵉ agent et d'un include nouveau doit être pris en charge sans modification de la logique de sync (sync.sh parcourt `agents/` et `includes/` automatiquement).

## Risques / inconnues

- **H1 (critique)** — Faisabilité du mapping story-markdown ↔ ticket JIRA sans perte d'information structurelle (frontmatter YAML, scénarios Gherkin, critères d'acceptation, handoff). **À valider en S-0005 avant d'implémenter S-0006.** Si le mapping s'avère trop lourd, possibilité de scinder en 2 epics.
- **H2** — Permissions Claude Code pour lire/écrire hors `cwd` (cas du chemin OneDrive). À vérifier en S-0001.
- **H3** — Impact de l'include partagé sur la taille des skills (limite Claude Code ?). Mesure en S-0001 sur `developer.md`.
- **Inconnu** — Support Windows : non validé initialement, mais architecture des chemins OneDrive doit rester portable (pas de coded path Unix spécifique).

## Stories

- [S-0001 - Schéma de config et include sources-config](S-0001-Schema-Config.md) — fondations : fichiers `.kp-agents.yml` / `.kp-agents.local.yml` et logique partagée
- [S-0002 - Agent setup (périmètre sources)](S-0002-Agent-Setup.md) — création de l'agent `setup` avec périmètre initial sources
- [S-0003 - Intégration sources-config dans les 7 agents existants](S-0003-Integration-Agents.md) — injection de l'include et auto-redirect vers setup
- [S-0004 - Mode product.mode: external (OneDrive)](S-0004-Product-External.md) — lecture/écriture OneDrive avec fallback local
- [S-0005 - Spike mapping story-markdown ↔ ticket JIRA](S-0005-Spike-Jira-Mapping.md) — validation de faisabilité (bloquant pour S-0006)
- [S-0006 - Mode tickets.mode: mcp (JIRA)](S-0006-Tickets-Mcp-Jira.md) — implémentation du mapping validé
- [S-0007 - Préférences Git dans setup](S-0007-Git-Preferences.md) — extension de setup aux règles Git projet
- [S-0008 - Documentation et release v1.1.0](S-0008-Doc-Release.md) — finalisation doc et publication
- [S-0009 - Mode product.access: read-only](S-0009-Product-ReadOnly.md) — doc produit externe figée (lecture seule), agents product et brainstorm en mode conversationnel

## Critères de succès

- Un utilisateur peut travailler avec `kp-agents` sur un projet dont la doc produit vit sur OneDrive et les tickets sur JIRA, sans jamais modifier manuellement les agents, et en préservant 100% le comportement actuel pour les projets sans config.
- Aucun chemin machine-spécifique n'est commité dans le repo (`.kp-agents.local.yml` effectivement gitignoré).
- Un projet existant (par exemple `kp-agents` lui-même) continue de fonctionner sans friction après la release `v1.1.0`.
- Le nouvel agent `setup` est invocable via `/kp-agents:setup` et couvre sources + préférences Git après clôture de l'epic.
- Les 7 agents existants redirigent proprement vers `setup` lorsqu'une config est manquante (test manuel sur un projet vierge).
- Release `kp-agents-v1.1.0` taguée sur GitHub + GitLab et installable sur un poste vierge.
