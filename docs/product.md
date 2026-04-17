---
title: Product Overview
date: 2026-04-17
status: active
author: product-agent
---

# Produit - kp-agents

## Résumé

kp-agents est un système de **distribution d'agents IA** pour les environnements de développement. Il centralise une bibliothèque d'agents spécialisés (brainstorm, product, architect, developer, review, documentation, ux-ui) dans un repo unique, et les met à disposition des développeurs KeyProd via trois canaux : Claude Code (en tant que plugin marketplace installable), Cursor (règles importées localement), et Codex (skills importées localement).

## Problème adressé

- **Dispersion des pratiques d'agents IA** : chaque développeur définit ses propres prompts, résultats hétérogènes
- **Friction d'installation** : avant kp-agents, chaque mise à jour nécessitait un partage manuel de fichiers
- **Triple format à maintenir** : chaque plateforme (Claude / Cursor / Codex) a son propre format d'agent, source de duplication et de drift

## Utilisateurs / Personas

- **Développeur KeyProd** : utilise quotidiennement un ou plusieurs des trois IDE IA. Veut installer les agents en une commande, les avoir mis à jour automatiquement, et pouvoir les invoquer dans tous les contextes
- **Architecte / Product KeyProd** : contribue à faire évoluer les agents (modifier un prompt, ajouter un nouveau rôle). Veut un flux simple : édit → sync → commit
- **Consommateur externe ponctuel** (à venir) : un collaborateur hors KeyProd qui veut utiliser les agents génériques sans avoir accès aux outils internes

## Valeur apportée

- **Source unique de vérité** : un agent se modifie à un seul endroit (`agents/<nom>.md`)
- **Distribution multi-plateforme** : la même logique est portée sur Claude, Cursor et Codex sans duplication humaine
- **Installation d'un clic** (via Claude Code plugin marketplace) : plus besoin de cloner et de lancer un script

## Règles métier

- Un agent a une définition unique dans `agents/<nom>.md` (frontmatter + corps markdown + directives `{{include:xxx}}`)
- Les directives `{{include:xxx}}` sont résolues au moment de la génération (pas de dépendance runtime)
- Le préfixe `kp-` identifie les agents issus de ce projet dans toutes les cibles
- Les agents génériques (non spécifiques à un métier KeyProd) sont regroupés dans le plugin `kp-core`

## Parcours et cas d'usage clés

- **Consommateur Claude Code** : `/plugin marketplace add KeyProd/kp-agents` → `/plugin install kp-core@kp-agents` → `/kp-core:brainstorm` disponible
- **Consommateur Cursor / Codex** : `git clone kp-agents` → `./sync.sh` → règles/skills installées localement
- **Contributeur** : `edit agents/<nom>.md` → `./sync.sh` → commit + bump `plugin.json` → push → les utilisateurs reçoivent la mise à jour au prochain `/plugin marketplace update`

## Périmètre fonctionnel

### Inclus

- Distribution des 7 agents génériques (brainstorm, product, architect, developer, review, documentation, ux-ui)
- Installation via plugin marketplace Claude Code
- Installation via `sync.sh` pour Cursor et Codex
- Versioning semver par plugin
- Hébergement GitHub (primaire) + GitLab (miroir)

### Exclu

- Agents spécifiques à un projet métier (ex: recettemoi, retirés le 2026-04-17)
- Interface web / UI de gestion des agents
- Découverte automatique d'agents par contexte de projet
- Auto-update sans validation humaine du contenu

## Contraintes produit

- **Distribution interne** : le repo est actuellement privé. Ouverture publique à terme possible (agents génériques uniquement)
- **Pas de données sensibles** : aucun secret, aucune URL interne, aucun token dans les agents
- **Format Claude plugin imposé** : namespaces `/kp-core:<nom>`, structure `.claude-plugin/` obligatoire

## Mesure du succès

- **Adoption interne** : ≥ 80% des devs KeyProd utilisent au moins un agent par semaine
- **Friction d'install** : un nouveau dev est productif avec les agents en < 5 minutes
- **Fréquence de mise à jour** : les agents sont versionnés et bumpés au moins une fois par mois
- **Zéro incident de duplication** : jamais de dérive entre source (`agents/`) et artefacts installés

## Références

- [Architecture](architect.md)
- [Roadmap](project/roadmap.md)
- [Idée fondatrice — plugin Claude Code](ideas/plugin-claude-code.md)
- [Repo GitHub](https://github.com/KeyProd/kp-agents)
