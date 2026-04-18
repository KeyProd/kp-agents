---
title: Auto-bump patch à chaque sync
date: 2026-04-18
status: TODO
author: product-agent
story-id: S-0001
epic-id: E-0002
---

# S-0001 - Auto-bump patch à chaque sync

## Résumé

Intégrer dans `sync.sh` un mécanisme qui calcule un hash SHA256 du contenu des skills générés et incrémente le composant `patch` de la version dans `plugin.json` si ce hash diffère du précédent. Le hash précédent est stocké dans un champ custom `_contentHash` de `plugin.json`.

## User Story

En tant que **contributeur kp-agents**, je veux que la version `patch` du plugin soit **automatiquement incrémentée** chaque fois que je modifie le contenu d'un agent afin que **la mise à jour soit détectée par tous les consommateurs Claude Code sans que j'aie à y penser**.

## Contexte

- La version actuelle du plugin est stockée dans `plugins/kp-agents/.claude-plugin/plugin.json` (`"version": "0.1.0"` après release v0.1.0)
- `sync.sh` régénère à chaque run les 7 fichiers `plugins/kp-agents/skills/<nom>/SKILL.md` à partir de `agents/<nom>.md`
- Sans bump, Claude Code skipe la mise à jour côté client (problème rencontré lors de E-0001)
- La modification de `plugin.json` doit rester minimale : un nouveau champ `_contentHash` + mise à jour de `version`

## Règles métier

- **RM-1** (epic) : le hash est calculé uniquement sur les fichiers `plugins/kp-agents/skills/**/SKILL.md`
- **RM-2** (epic) : seul le composant `patch` est incrémenté automatiquement
- **RM-4** (epic) : la documentation CLAUDE.md et README.md doit être mise à jour dans cette story (bloquant)
- **RM-5** (epic) : `claude plugin validate` doit continuer à passer après ajout du champ `_contentHash`
- Si `plugin.json` ne contient pas encore `_contentHash` (cas du tout premier run), on initialise le hash sans bumper (la version courante est considérée comme la référence)
- Le hash est calculé **après** la génération des skills (donc sur les SKILL.md finaux avec includes résolus)

## Scénarios

### Nominal — modification d'un agent suivi de sync

- Étant donné un `plugin.json` avec `version: "0.1.0"` et `_contentHash: "abc123..."`
- Et un contributeur qui modifie `agents/brainstorm.md`
- Quand il lance `./sync.sh`
- Alors `sync.sh` régénère les 7 SKILL.md (contenu de `brainstorm/SKILL.md` modifié)
- Et `sync.sh` calcule un nouveau hash `"def456..."`
- Et comme `"def456..." != "abc123..."`, le patch est incrémenté : `version` passe de `"0.1.0"` à `"0.1.1"`
- Et `_contentHash` devient `"def456..."`
- Et un log affiche : `Plugin version bumped: 0.1.0 → 0.1.1 (content changed)`

### Alternatif 1 — re-sync sans changement

- Étant donné un `plugin.json` avec `version: "0.1.1"` et `_contentHash: "def456..."`
- Et aucune modification dans `agents/`
- Quand le contributeur lance `./sync.sh`
- Alors les SKILL.md sont régénérés à l'identique
- Et le hash calculé est toujours `"def456..."`
- Et la version reste `"0.1.1"`, `_contentHash` inchangé
- Et un log affiche : `Plugin version unchanged: 0.1.1 (no content change)`

### Alternatif 2 — premier run après S-0001 (champ `_contentHash` absent)

- Étant donné un `plugin.json` avec `version: "0.1.0"` **sans** champ `_contentHash`
- Quand le contributeur lance `./sync.sh`
- Alors `sync.sh` calcule le hash courant
- Et ajoute `_contentHash: "xxx..."` dans `plugin.json`
- Et **ne bumpe pas** la version (initialisation silencieuse)
- Et un log affiche : `Plugin content hash initialized (no version bump)`

### Cas d'erreur — outil de hash indisponible

- Étant donné un environnement où ni `shasum` ni `openssl` ne sont disponibles
- Quand le contributeur lance `./sync.sh`
- Alors `sync.sh` affiche un warning explicite : `WARNING: No SHA256 tool available — auto-bump skipped`
- Et la génération des skills se poursuit normalement (non bloquant)
- Et la version n'est pas modifiée

## Cas limites

- [ ] État vide : `plugins/kp-agents/skills/` existe mais est vide (aucun agent) → hash calculé sur chaîne vide, comportement cohérent (pas de bump spontané)
- [ ] `plugin.json` corrompu ou JSON invalide : erreur explicite, pas de modification
- [ ] Modification concernant **uniquement** `plugin.json` ou `marketplace.json` sans toucher aux skills : pas de bump (le hash ne couvre pas ces fichiers)
- [ ] Modification de l'ordre des agents dans `agents/` (renommage) : impact sur le hash → bump attendu
- [ ] Permissions lecture insuffisantes sur `plugin.json` : erreur explicite

## Critères d'acceptation

- [ ] Après un `./sync.sh` avec modification d'un agent, la version `patch` est incrémentée (ex: `0.1.0` → `0.1.1`)
- [ ] Après un `./sync.sh` sans modification, la version reste identique
- [ ] `plugin.json` contient un champ `_contentHash` après chaque sync (initialisation au premier run, maintenance aux suivants)
- [ ] `claude plugin validate` retourne `✔ Validation passed` après ajout du champ
- [ ] Un log clair dans la sortie `sync.sh` indique le résultat : bump effectué, initialisation, ou pas de changement
- [ ] Le hash est calculé **uniquement** sur `plugins/kp-agents/skills/**/SKILL.md` (pas sur `plugin.json`, `marketplace.json`, Cursor, Codex)
- [ ] Si ni `shasum` ni `openssl` ne sont disponibles, un warning explicite s'affiche et la génération continue sans bump
- [ ] **Documentation mise à jour** (bloquant, règle RM-4) :
  - `README.md` : section "Publier une mise à jour Claude Code" : retirer l'étape "bumper manuellement"
  - `CLAUDE.md` : section "Ajouter ou modifier un agent" : retirer l'étape de bump manuel
  - Note explicite dans les deux docs que `./sync.sh` gère le bump automatiquement
- [ ] Bash 3.2 compatible (pas de features bash 4+)
- [ ] Le temps d'exécution de `sync.sh` ne dépasse pas de plus de 0.5s la version actuelle (overhead du hash négligeable)

## Dépendances

- Epic E-0001 terminée (`plugin.json` existe avec version `0.1.0`) ✅
- Architecture sync.sh en place
- Outil `shasum` ou `openssl` disponible localement (macOS + Linux standard)

## Notes techniques

- **Hash calculation** : deux options à trancher par Architect —
  - `find plugins/kp-agents/skills -type f -name SKILL.md | sort | xargs shasum -a 256 | shasum -a 256 | awk '{print $1}'`
  - Ou via une commande plus simple via `tar` + `shasum`
- **Manipulation JSON** : `plugin.json` est un JSON simple. À modifier via `jq` si dispo, sinon via sed/awk rigoureux. Architect tranche — note que `jq` n'est pas dans la dépendance actuelle
- **Timing dans sync.sh** : le bump se fait après la génération des SKILL.md et avant le message final (dernière étape)
- **Log formatting** : utiliser les helpers `log`, `ok`, `warn` existants pour rester cohérent
- **Écriture de `plugin.json`** : préserver l'indentation et l'ordre des champs autant que possible pour un diff lisible

## Instrumentation / mesure

- Log de sortie `sync.sh` qui indique systématiquement un statut parmi : `bumped`, `unchanged`, `initialized`, `skipped (no hash tool)`
- Vérifier que la version dans `plugin.json` est cohérente avec le commit qui introduit le changement (observable via `git log -p plugins/kp-agents/.claude-plugin/plugin.json`)

## Questions ouvertes

- Faut-il offrir un flag `./sync.sh --no-bump` pour désactiver l'auto-bump dans certains contextes (ex: tests locaux, CI) ? **Hypothèse par défaut** : non au départ, à revoir si un use case concret émerge. Architect peut trancher.
- Le champ `_contentHash` doit-il être préfixé pour éviter tout conflit avec un éventuel futur champ standard Claude Code ? **Hypothèse** : `_contentHash` (underscore = convention "interne") ou `kpContentHash`. Architect tranche.

## Implémentation

*à compléter par l'agent Developer*

- Fichiers créés / modifiés : `sync.sh`, `plugins/kp-agents/.claude-plugin/plugin.json`, `README.md`, `CLAUDE.md`
- Commandes de test :
  - `./sync.sh` deux fois sans rien modifier → 1er run initialise hash, 2e run unchanged
  - Modifier `agents/brainstorm.md`, `./sync.sh` → patch bumpé
  - `claude plugin validate .` après bump
- Notes de review : à compléter

## Validation par critère

*à compléter lors de la review*
