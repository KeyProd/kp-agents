---
title: Agent setup (périmètre sources)
date: 2026-04-21
status: TODO
author: product-agent
story-id: S-0002
epic-id: E-0004
---

# S-0002 - Agent setup (périmètre sources)

## Résumé

Créer le 8ᵉ agent `setup`, dédié à la configuration projet. Périmètre initial : gérer les sources (`product.mode`, `tickets.mode`, chemins) via conversation avec l'utilisateur. Les préférences Git arriveront en S-0007 (livraison progressive).

## User Story

En tant qu'utilisateur de `kp-agents`, je veux un agent dédié à la configuration de mon projet, afin de ne pas éditer manuellement les fichiers de config et d'être guidé par des questions claires.

## Contexte

- Le brainstorm (S-0002 de la logique de l'epic) a décidé d'un agent unique évolutif plutôt que de disperser la config entre plusieurs agents.
- Périmètre initial volontairement restreint aux sources pour livrer vite. S-0007 étendra à Git.
- L'agent doit être invocable directement (`/kp-agents:setup`) ET via auto-redirect depuis un autre agent qui détecte une config manquante.

## Règles métier

- L'agent audite l'état courant avant de prompter : s'il existe déjà une config valide, il l'affiche et demande ce que l'utilisateur veut modifier.
- L'agent ne modifie **jamais** un `.kp-agents.yml` sans confirmation explicite.
- L'agent écrit `.kp-agents.local.yml` uniquement si une dimension externe est activée (sinon inutile).
- L'agent ajoute automatiquement `.kp-agents.local.yml` au `.gitignore` si l'entrée n'y est pas.
- L'agent vérifie l'accessibilité du chemin `product.path` (lecture) avant de l'enregistrer et warn si inaccessible.
- À la fin, l'agent propose un handoff vers l'agent approprié (souvent `/kp-agents:product` si on vient d'activer le mode externe).

## Scénarios

### Nominal
- Étant donné un projet vierge sans `.kp-agents.yml`
- Quand l'utilisateur invoque `/kp-agents:setup`
- Alors l'agent lui pose 3-4 questions (sources product locale/externe, sources tickets locale/mcp, chemin OneDrive si externe, clé JIRA si mcp) et écrit les fichiers de config + mise à jour du `.gitignore`.

### Alternatif
- Étant donné un projet avec config complète et valide
- Quand l'utilisateur invoque `/kp-agents:setup`
- Alors l'agent affiche la config courante et demande quoi modifier (ou confirme que tout est OK).

### Erreur / refus
- Étant donné l'utilisateur renseigne un `product.path` inaccessible (dossier inexistant, permissions insuffisantes)
- Quand l'agent vérifie le chemin
- Alors il warn, propose 3 options : (a) corriger le chemin, (b) enregistrer quand même en mode dégradé, (c) annuler.

## Cas limites

- [ ] Utilisateur annule en cours de configuration → l'agent ne laisse pas de fichiers partiels
- [ ] `.gitignore` inexistant → l'agent le crée avec la seule entrée `.kp-agents.local.yml`
- [ ] Utilisateur redéclenche `setup` alors qu'une session d'un autre agent est active → pas de lock, comportement transparent (le prochain agent relira la config)
- [ ] Projet avec un `.kp-agents.yml` mais pas de `.kp-agents.local.yml` alors que mode externe actif → l'agent complète sans tout réécraser

## Critères d'acceptation

- [ ] Fichier `agents/setup.md` créé avec frontmatter conforme (`name`, `description`, `short_description`, `default_prompt`)
- [ ] L'agent inclut `{{include:activation}}`, `{{include:handoff}}`, `{{include:sources-config}}`, et `{{include:gotchas-transverses}}`
- [ ] Invocation `/kp-agents:setup` fonctionne après `./sync.sh` (plugin Claude Code)
- [ ] Présence dans `dist/cursor/kp-setup.mdc` et `dist/codex/kp-setup/` après `./sync.sh`
- [ ] Présence dans `.claude-plugin/marketplace.json` (liste des agents du plugin)
- [ ] Mise à jour de `CLAUDE.md` : section « Agents disponibles » inclut `setup`, workflow diagram mis à jour
- [ ] L'agent audite l'existant avant de prompter (lit `.kp-agents.yml` si présent)
- [ ] L'agent crée/met à jour `.kp-agents.yml`, `.kp-agents.local.yml`, `.gitignore`
- [ ] L'agent vérifie l'accessibilité du `product.path` (test de lecture) avant d'enregistrer
- [ ] Test manuel : depuis un projet vierge, `/kp-agents:setup` génère une config fonctionnelle pour les 4 combinaisons (local/local, external/local, local/mcp, external/mcp)
- [ ] Release automatique minor bump car ajout d'agent (géré par `sync.sh --minor` au moment de la release)

## Dépendances

- **S-0001** : le schéma de config doit être défini avant que `setup` puisse l'écrire.

## Notes techniques

- L'agent `setup` est le seul qui écrit dans `.kp-agents.yml` et `.kp-agents.local.yml` → les autres agents sont en **lecture seule** sur ces fichiers.
- Le prompt par défaut (`default_prompt`) doit démarrer par un audit de l'état courant (lire ce qui existe avant de prompter).
- Prévoir un `short_description` explicite pour que l'utilisateur comprenne à quoi sert l'agent dès la liste des commandes.

## Instrumentation / mesure

- Nombre de questions posées en mode fresh setup (attendu : ≤ 5) — indicateur de fluidité.

## Questions ouvertes

- Faut-il un mode `--dry-run` qui affiche ce qui serait écrit sans modifier les fichiers ? → **Décision V1 : non**, l'agent annonce ce qu'il va faire avant d'écrire.

## Implémentation

- Fichiers créés / modifiés : `agents/setup.md` (nouveau), `.claude-plugin/marketplace.json` (ajout), `CLAUDE.md` (mise à jour section agents + workflow diagram)
- Commandes de test : `./sync.sh --minor` puis `/kp-agents:setup` depuis un projet vierge
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
