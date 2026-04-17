---
title: Refonte sync.sh pour générer le plugin kp-core
date: 2026-04-17
status: TODO
author: product-agent
story-id: S-0001
epic-id: E-0001
---

# S-0001 - Refonte sync.sh pour générer le plugin kp-core

## Résumé

Transformer `sync.sh` pour qu'il produise le dossier `plugins/kp-core/` (structure plugin Claude Code native) à partir de `agents/*.md`, et retire complètement la cible d'installation Claude locale (`~/.claude/commands/`). Les cibles Cursor et Codex sont conservées à l'identique.

## User Story

En tant que **contributeur kp-agents**, je veux que **`./sync.sh` produise automatiquement `plugins/kp-core/` à partir de `agents/`** afin de **maintenir une source unique tout en distribuant via le mécanisme plugin Claude Code natif**.

## Contexte

- Aujourd'hui `sync.sh` génère 3 cibles : `dist/claude/`, `dist/cursor/`, `dist/codex/` + installe dans `~/.claude/`, `~/.cursor/`, `~/.codex/`
- Décisions d'architecture ([docs/architect.md](../../architect.md) ADR-002 et ADR-003) :
  - La cible Claude locale est remplacée par le plugin marketplace
  - `agents/` reste la source, `plugins/` est généré et commité
- Le spike a démontré qu'un plugin manuel fonctionne ([docs/ideas/plugin-claude-code.md](../../ideas/plugin-claude-code.md)). Cette story automatise la génération

## Règles métier

- Un seul plugin produit pour l'instant : `kp-core` (7 agents génériques)
- Le plugin a son propre `plugin.json` avec un champ `version` (semver) bumpé manuellement
- Les includes `{{include:xxx}}` sont résolus avant écriture dans `plugins/kp-core/skills/<nom>/SKILL.md`
- Le fichier `.claude-plugin/marketplace.json` existe déjà à la racine et n'est pas régénéré par sync.sh (statique, géré à la main)
- Les fichiers dans `plugins/` DOIVENT être commités (c'est ce que Claude Code télécharge)

## Scénarios

### Nominal — sync complet depuis un état propre

- Étant donné un `agents/` contenant 7 fichiers valides et des `includes/` résolvables
- Quand j'exécute `./sync.sh`
- Alors `plugins/kp-core/.claude-plugin/plugin.json` est créé avec la version courante
- Et `plugins/kp-core/skills/<nom>/SKILL.md` est créé pour chacun des 7 agents, avec includes résolus et frontmatter Claude plugin (champ `description` uniquement)
- Et `dist/cursor/kp-*.mdc` et `dist/codex/kp-*/` sont générés comme avant
- Et **aucun fichier n'est déposé dans `~/.claude/commands/`**
- Et le manifeste `.installed-agents` reflète uniquement ce qui a été installé dans Cursor/Codex

### Alternatif — sync après suppression d'un agent

- Étant donné un `agents/` où un agent (ex: `ux-ui.md`) a été supprimé
- Et le sync précédent avait installé ses artefacts
- Quand j'exécute `./sync.sh`
- Alors `plugins/kp-core/skills/ux-ui/` est supprimé
- Et `dist/cursor/kp-ux-ui.mdc` et `dist/codex/kp-ux-ui/` sont supprimés
- Et les installations Cursor/Codex correspondantes sont retirées via le manifeste

### Alternatif — `--clean`

- Étant donné un `plugins/kp-core/` existant et des installs Cursor/Codex
- Quand j'exécute `./sync.sh --clean`
- Alors les installs Cursor/Codex du manifeste sont retirées
- Et les artefacts dans `dist/` sont retirés
- Et `plugins/kp-core/` n'est **pas** modifié (c'est du contenu commité, pas une install)
- Et le script sort sans faire de sync

### Alternatif — `--clean-all`

- Étant donné un état quelconque
- Quand j'exécute `./sync.sh --clean-all`
- Alors toutes les installs Cursor/Codex préfixées `kp-*` sont retirées (glob)
- Et tous les artefacts dans `dist/` sont retirés
- Et `plugins/kp-core/` n'est **pas** modifié
- Et le script sort sans faire de sync

### Erreur — include manquant

- Étant donné un agent qui référence `{{include:inexistant}}`
- Quand j'exécute `./sync.sh`
- Alors un warning clair est émis pour le fichier concerné (`Include not found: ...`)
- Et la génération continue pour les autres agents (comportement actuel préservé)
- Et le SKILL.md produit pour ce skill contient un marqueur visible de l'include manquant (vide ou commentaire)

## Cas limites

- [ ] État vide : `agents/` ne contient aucun fichier → sync produit un `plugins/kp-core/` vide (ou pas de plugin du tout ?) + message informatif. **Décision** : produire un plugin vide avec juste le `plugin.json` est acceptable, le marketplace s'occupe du reste
- [ ] Frontmatter invalide dans un agent source → warning et skip de cet agent (comportement actuel)
- [ ] Manifeste `.installed-agents` absent au premier run → pas d'installs à nettoyer (fallback glob `kp-*`)
- [ ] Les fonctions `generate_claude*` existantes doivent être **supprimées** du script (pas juste commentées)
- [ ] Le sous-dossier `dist/claude/` ne doit plus être créé par `sync.sh`. Son existence résiduelle n'est pas une régression mais devra être nettoyée

## Critères d'acceptation

- [ ] `./sync.sh` ne dépose plus aucun fichier dans `~/.claude/commands/` (vérifiable par `ls ~/.claude/commands/kp-*` qui retourne vide après sync)
- [ ] `./sync.sh` crée `plugins/kp-core/.claude-plugin/plugin.json` avec au minimum les champs `name`, `description`, `version`
- [ ] `./sync.sh` crée un fichier `plugins/kp-core/skills/<nom>/SKILL.md` pour chacun des 7 agents, avec frontmatter YAML contenant au moins `description`
- [ ] Le contenu des `SKILL.md` a tous les `{{include:xxx}}` résolus (aucune directive non-substituée)
- [ ] `claude plugin validate /Users/vincent/GIT/kp-agents` retourne `✔ Validation passed`
- [ ] `./sync.sh --clean` retire uniquement les installs Cursor/Codex (vérifiable par comparaison avant/après)
- [ ] `./sync.sh --clean-all` retire les mêmes + via glob
- [ ] Aucune fonction `generate_claude*` ne subsiste dans `sync.sh`
- [ ] Les 7 SKILL.md de `plugins/kp-core/skills/` sont identiques en contenu aux anciens `dist/codex/kp-*/SKILL.md` à l'exception du frontmatter (qui est simplifié — pas de champs Codex-spécifiques)
- [ ] Le script reste exécutable sur macOS (bash 3.2 supporté — pas de features bash 4+ utilisées)
- [ ] Le script conserve ses messages de log colorés (BLUE/GREEN/YELLOW/RED)

## Dépendances

- Architecture : [docs/architect.md](../../architect.md) ADR-002 et ADR-003
- Format source inchangé : `agents/<nom>.md` avec frontmatter et includes
- Aucune story préalable

## Notes techniques

- Nom de la nouvelle fonction suggéré : `generate_plugin_kp_core` (ou `generate_plugin` si on anticipe plusieurs plugins, mais ça complique pour peu d'intérêt à ce stade)
- Le dossier `plugins/kp-core-spike/` existant dans le repo **doit être supprimé** dans cette story (le spike est remplacé par le plugin définitif)
- Le `.claude-plugin/marketplace.json` à la racine doit être mis à jour pour pointer vers `kp-core` (plus vers `kp-core-spike`)
- Attention au frontmatter des SKILL.md : le format Codex ajoute `name:` et `metadata:` → ces champs doivent être **absents** dans la version plugin (seul `description` reste)
- Considérer d'invoquer `claude plugin validate` en fin de `sync.sh` comme garde-fou (optionnel si `claude` CLI dispo)
- Mettre à jour `CLAUDE.md` et `README.md` est **hors périmètre** de cette story (géré en S-0002)

## Instrumentation / mesure

- Log final attendu : `━━━ Done: 7 agents synced to 3 tools (plugin + cursor + codex) ━━━` ou équivalent reflétant la nouvelle architecture
- Compter le temps d'exécution : ne doit pas dépasser 2 secondes sur la machine de dev

## Questions ouvertes

- Faut-il regénérer `plugin.json` à chaque `sync.sh`, ou le conserver statique en le laissant à la maintenance manuelle ? **Hypothèse** : statique — sync.sh ne touche pas à `plugin.json` (le contributeur bump manuellement). À confirmer avec Architect si doute.
- Faut-il ajouter un flag `sync.sh --validate` qui appelle `claude plugin validate` à la fin ? **Hypothèse** : non pour S-0001, à considérer pour une story future.

## Implémentation

*à compléter par l'agent Developer*

- Fichiers créés / modifiés :
  - `sync.sh` (réécriture des fonctions cibles)
  - `plugins/kp-core/` (nouveau dossier, remplace `plugins/kp-core-spike/`)
  - `.claude-plugin/marketplace.json` (mise à jour du nom de plugin)
- Commandes de test :
  - `./sync.sh && ls plugins/kp-core/skills/`
  - `ls ~/.claude/commands/kp-*` (doit être vide)
  - `claude plugin validate .`
- Notes de review :

## Validation par critère

*à compléter lors de la review*
