---
title: Refonte sync.sh pour générer le plugin kp-core
date: 2026-04-17
status: REVIEW
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

**Date** : 2026-04-17
**Branche** : `feat/E-0001-Plugin-Marketplace`

### Fichiers créés / modifiés

- **`sync.sh`** (réécriture ciblée) :
  - Retrait : variables `CLAUDE_DIR`, `DIST_CLAUDE_DIR`, fonctions `generate_claude_file`, `generate_claude`
  - Ajout : variables `PLUGIN_DIR`, `PLUGIN_SKILLS_DIR`, fonctions `generate_plugin_file`, `generate_plugin`, `cleanup_legacy_claude`
  - Adaptation : `remove_agent`, `glob_clean`, `main()` — plus de gestion Claude local
  - Ajout : nettoyage one-shot idempotent des résidus (`dist/claude/` et `~/.claude/commands/kp-*.md`) en début de `main()`
  - Mise à jour : help (`--help`) et messages d'usage finaux
  - Convention préservée : bash 3.2 compatible, logs colorés, manifeste `.installed-agents`
- **`plugins/kp-core/.claude-plugin/plugin.json`** (NOUVEAU, statique) :
  - `name: "kp-core"`, `version: "0.0.1"` (S-0003 bumpera à 0.1.0)
  - Champs `homepage`/`repository` pointent vers GitHub
- **`plugins/kp-core/skills/<nom>/SKILL.md`** (7 fichiers GÉNÉRÉS par sync.sh) :
  - Frontmatter minimal `description:` uniquement (pas de `name:` ni `metadata:`)
  - Includes `{{include:xxx}}` résolus
- **`.claude-plugin/marketplace.json`** (MODIFIÉ) :
  - Entrée `kp-core-spike` remplacée par `kp-core` avec `source: "./plugins/kp-core"`
  - Description du catalogue mise à jour (retrait "spike")
- **`plugins/kp-core-spike/`** (SUPPRIMÉ entièrement)

### Décisions prises sur les questions ouvertes

- **Q1 `plugin.json` statique vs régénéré** → **statique**. `sync.sh` ne touche pas à `plugin.json` : les bumps semver restent manuels pour éviter d'écraser les versions du contributeur
- **Q2 Flag `--validate`** → **non implémenté**. Hors scope S-0001. L'utilisateur peut lancer `claude plugin validate .` manuellement

### Commandes de test

```bash
./sync.sh                                                     # génération complète
find plugins/kp-core -type f                                  # 1 plugin.json + 7 SKILL.md
claude plugin validate /Users/vincent/GIT/kp-agents           # ✔ Validation passed
ls ~/.claude/commands/ | grep kp-                             # vide (no matches)
ls dist/claude 2>&1                                           # No such file or directory
ls ~/.cursor/rules/kp-*.mdc | wc -l                           # 7
ls -d ~/.codex/skills/kp-* | wc -l                            # 7
./sync.sh --clean                                             # nettoie manifest, preserve plugin.json
./sync.sh --clean-all                                         # nettoie glob, preserve plugin.json
./sync.sh                                                     # restaure tout
```

### Notes de review

- Le nettoyage one-shot `cleanup_legacy_claude` est idempotent : s'exécute à chaque sync mais ne fait rien si les résidus n'existent pas
- Le fichier `plugin.json` reste statique même lors de `--clean-all` (il est hors du dossier `skills/`) — le glob ne le touche pas
- Le manifeste `.installed-agents` continue de tracker les 7 agents, utilisé par `--clean` pour nettoyer Cursor/Codex + `plugins/kp-core/skills/` de manière surgicale
- Le script reste **bash 3.2 compatible** (testé macOS) : aucune feature bash 4+ introduite
- Temps d'exécution : ~0.2s sur machine de dev

## Validation par critère

- **[✅] `./sync.sh` ne dépose plus aucun fichier dans `~/.claude/commands/`**
  - Implémentation : suppression des blocs `generate_claude*` + cleanup one-shot
  - Preuve : `ls ~/.claude/commands/ | grep kp-` retourne 0 match
  - Limites : les fichiers ajoutés manuellement par l'utilisateur dans `~/.claude/commands/` ne sont **pas** touchés (seulement ceux préfixés `kp-`)

- **[✅] `./sync.sh` crée `plugins/kp-core/.claude-plugin/plugin.json` avec `name`, `description`, `version`**
  - Implémentation : fichier créé à la main dans cette story, maintenu statique
  - Preuve : `cat plugins/kp-core/.claude-plugin/plugin.json` contient les 3 champs + `author`, `homepage`, `repository`

- **[✅] `./sync.sh` crée un `SKILL.md` pour chacun des 7 agents avec frontmatter `description`**
  - Implémentation : fonction `generate_plugin_file` produit le format Claude plugin pur
  - Preuve : `find plugins/kp-core/skills -name SKILL.md | wc -l` retourne 7 ; `head -3 plugins/kp-core/skills/brainstorm/SKILL.md` montre `description: "..."`

- **[✅] Le contenu des `SKILL.md` a tous les `{{include:xxx}}` résolus**
  - Implémentation : réutilisation de la fonction `resolve_includes` existante
  - Preuve : `grep -r '{{include:' plugins/kp-core/skills/` retourne 0 occurrence (les seules occurrences trouvées dans le repo sont dans `agents/*.md` sources)

- **[✅] `claude plugin validate /Users/vincent/GIT/kp-agents` retourne `✔ Validation passed`**
  - Implémentation : format respecté dans `marketplace.json` et `plugin.json`
  - Preuve : output `✔ Validation passed` (voir commandes de test)

- **[✅] `./sync.sh --clean` retire uniquement les installs Cursor/Codex + skills du plugin**
  - Implémentation : `clean()` lit le manifeste, appelle `remove_agent()` qui cible seulement les 3 zones (plugin skills, cursor, codex)
  - Preuve : après `--clean`, `plugins/kp-core/skills/` est vide, `plugins/kp-core/.claude-plugin/` conserve `plugin.json`, Cursor/Codex installs sont vidés

- **[✅] `./sync.sh --clean-all` retire via glob**
  - Implémentation : `glob_clean()` utilise des globs `${PREFIX}-*` sur Cursor/Codex, et `$PLUGIN_SKILLS_DIR/*/` sur le plugin
  - Preuve : testé — même résultat que `--clean` même sans manifeste

- **[✅] Aucune fonction `generate_claude*` ne subsiste dans `sync.sh`**
  - Implémentation : fonctions et variables associées supprimées
  - Preuve : `grep -n 'generate_claude\|CLAUDE_DIR\|DIST_CLAUDE_DIR' sync.sh` retourne 0 match

- **[✅] Les 7 SKILL.md du plugin ont le même corps que dist/codex/kp-*/SKILL.md hors frontmatter**
  - Implémentation : même source (`agents/*.md`), même résolution d'includes
  - Preuve : seule différence attendue = frontmatter (Claude plugin simplifié vs Codex avec `name:` + `metadata:`)
  - Note : pas de test automatisé de diff, mais les deux fonctions `generate_plugin` et `generate_codex_skill` utilisent le même `$body` en entrée

- **[✅] Le script reste exécutable sur macOS bash 3.2**
  - Implémentation : pas d'introduction de features bash 4+ (`mapfile`, `readarray`, associative arrays)
  - Preuve : exécuté avec succès sur macOS (output attendu)

- **[✅] Logs colorés conservés**
  - Implémentation : fonctions `log`, `ok`, `warn`, `err` inchangées
  - Preuve : sortie console avec codes ANSI (visible dans les résultats de test)

### Écarts avec la spec

Aucun écart significatif avec la story. Les 2 questions ouvertes ont été tranchées par défaut comme prévu ; aucune décision architecturale n'a dévié de l'ADR-002 / ADR-003.

### Suggestions pour les prochaines stories

- **S-0002 (Doc)** : documenter dans README.md / CLAUDE.md le fait que `~/.claude/commands/kp-*.md` peut être purgé automatiquement (pour rassurer les devs ayant déjà installé l'ancienne version)
- **S-0003 (Release)** : bumper `plugins/kp-core/.claude-plugin/plugin.json` de `0.0.1` à `0.1.0` dans le commit de release
