---
title: Mise en place de la structure d'évaluation
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0007
epic-id: E-0003
---

# S-0007 - Mise en place de la structure d'évaluation

## Résumé

Créer la structure `agents/_evals/` avec trigger queries et output evals pour **2 agents pilotes** (developer et review), sans exécution réelle. Fournir un `README.md` expliquant le protocole et exclure le dossier de `sync.sh`.

## User Story

En tant que mainteneur du projet kp-agents, je veux disposer d'un dispositif d'évaluation reproductible — trigger rate + output quality — pour mesurer objectivement l'effet des modifications sur les agents, afin de valider les intuitions des guides de best practices avant de généraliser.

## Contexte

- Recommandation couverte : **B6** (`docs/agents-review.md` section C).
- Priorité : **P3**.
- **L'exécution** des evals (nécessite API Anthropic + environnement de test) est **hors périmètre** de cette story — elle pose les fondations uniquement.
- Pilotes choisis : **developer** et **review** car ce sont les agents aux prompts les plus discriminants et aux près-manqués les plus instructifs entre eux.

## Règles métier

- Les evals vivent dans `agents/_evals/<nom>/` — répertoire **ignoré par `sync.sh`** (ne doit pas être distribué aux cibles Cursor/Codex/plugin).
- Format conforme aux guides agentskills.io : `trigger_queries.json` (~20 items, 10 positive / 10 negative) + `output_evals.json` (2-3 cas avec `prompt`, `expected_output`, `assertions`).
- Près-manqués volontaires : mélanger des prompts proches des agents voisins pour tester la discrimination.

## Scénarios

### Nominal

- **Étant donné** aucune structure d'eval n'existe aujourd'hui
- **Quand** je crée `agents/_evals/developer/` + `agents/_evals/review/` avec les 2 fichiers + un README global dans `agents/_evals/README.md`
- **Alors** la structure est prête, documentée, et `sync.sh` l'ignore explicitement (pas de fichier parasite dans les artefacts).

### Alternatif

- **Étant donné** `sync.sh` parcourt actuellement tout `agents/*.md` sans distinction
- **Quand** je veux ignorer `agents/_evals/`
- **Alors** j'ajoute une règle d'exclusion (préfixe `_` ou pattern) dans `sync.sh`, testée avec un run `--dist-only`.

### Erreur / refus

- **Étant donné** les queries sont trop triviales (pas de près-manqués)
- **Quand** la story est reviewée
- **Alors** elle est NO-GO : retravailler pour inclure des prompts ambigus entre developer/review/product.

## Cas limites

- [ ] Pattern d'exclusion `sync.sh` : `_evals` est préfixé underscore donc l'exclusion via `agents/[!_]*.md` fonctionnerait nativement si le script utilise un glob. Vérifier et ajuster si nécessaire.
- [ ] Pas de risque de conflit avec `.installed-agents` : ce dernier n'inclut que les agents déployés (pas les répertoires).
- [ ] `agents/_evals/` doit être dans git (`_` n'est pas gitignore par défaut) : c'est **voulu** — les evals sont un artefact de maintenance.

## Critères d'acceptation

- [ ] Répertoire `agents/_evals/` créé avec :
  - `agents/_evals/README.md` — explique le protocole (format JSON, exécution externe, rôle de chaque fichier).
  - `agents/_evals/developer/trigger_queries.json` — au moins 20 items, équilibrés 10/10, avec au moins 3 près-manqués (confusion avec review, product, brainstorm).
  - `agents/_evals/developer/output_evals.json` — au moins 2 cas avec assertions objectives.
  - `agents/_evals/review/trigger_queries.json` — idem, 20 items, près-manqués avec developer.
  - `agents/_evals/review/output_evals.json` — idem, 2 cas.
- [ ] `sync.sh` ne copie **aucun** fichier de `_evals/` dans `plugins/`, `dist/cursor/`, `dist/codex/`. Validé par `ls` sur les artefacts.
- [ ] `sync.sh --dist-only` fonctionne normalement (pas d'erreur liée à `_evals`).
- [ ] `CLAUDE.md` mentionne la nouvelle structure dans "Structure du projet" + une phrase rappelant que c'est destiné aux mainteneurs.
- [ ] Les fichiers JSON sont syntaxiquement valides (`jq .` passe).

## Dépendances

- Indépendant des autres stories.
- Pourrait être fait en parallèle de n'importe quelle story fonctionnelle.
- **Hors-périmètre** : configuration d'exécution automatisée (API Anthropic, scripts de run, grading) — à prévoir dans une epic ultérieure si souhaité.

## Notes techniques

- Fichiers créés : 5 fichiers dans `agents/_evals/`.
- Fichier modifié : `sync.sh` (ajout d'une règle d'exclusion si le glob actuel l'impose), `CLAUDE.md`.
- Exemple de trigger query (pour documentation dans le README) :
  ```json
  { "query": "implémente S-0003 de l'epic E-0003", "should_trigger": true }
  { "query": "review ma PR #42", "should_trigger": false, "reason": "near-miss vers review-agent" }
  ```

## Instrumentation / mesure

- Aucune exécution dans cette story. Les métriques suivantes ne seront collectées qu'à l'exécution (ultérieure) :
  - Trigger rate (with skill / without skill)
  - Pass rate des assertions d'output
  - Delta en time / tokens
- Documenter dans le README quelle structure de `benchmark.json` sera attendue (pour préparer la future automatisation).

## Questions ouvertes

- Faut-il étendre à 7 agents avec 2 pilotes dès le départ ? Proposition : **commencer par 2** (developer, review) comme proof-of-concept ; si la structure fonctionne, généraliser dans une epic future.
- Langue des queries : français (le projet est francophone) ou bilingue (pour tester la robustesse des descriptions anglaises introduites en S-0002) ? Proposition : **bilingue**, au moins 25% en anglais, pour tester le trigger matching indépendamment de la langue.

## Implémentation

- Répertoire `agents/_evals/` créé avec 5 fichiers : `README.md` global + 2 sous-répertoires (`developer/`, `review/`) contenant chacun `trigger_queries.json` + `output_evals.json`.
- **Trigger queries** : 20 items par agent, équilibrés 10 positives / 10 négatives, avec ≥ 5 near-miss par agent. Mélange FR (~70%) + EN (~30%).
  - Near-miss developer : review (« check my implementation »), brainstorm (« on devrait peut-être »), architect (« what if we stored sessions in Redis »), product (« structure cette idée en epic »), documentation (« mets à jour le README »), ux-ui (« design the visual identity »).
  - Near-miss review : developer (« implémente S-0003 », « fix the bug »), documentation (« audit la documentation »), product (« structure cette feature »), brainstorm (« challenge-moi »), architect (« décide entre Postgres et DynamoDB »), ux-ui (« refais le flow d'onboarding »).
- **Output evals** : 3 cas par agent avec assertions objectives (`file_contains`, `frontmatter_field_equals`, `section_order`, `file_absent`, `git_files_unchanged`, `response_contains_any`).
  - developer : happy path (FIX-0001), spec ambiguë (FIX-0002 → handoff), mode epic (FIX-0003 + FIX-0004).
  - review : GO (FIX-0001), NO-GO avec critère manquant (FIX-0005), refus (FIX-0006 sans `## Implémentation`).
- **`sync.sh`** non modifié : le glob `agents/*.md` (sync.sh:423) n'est pas récursif et ignore naturellement `agents/_evals/**`. Vérifié : 0 fichier `_evals` dans `plugins/`, `dist/cursor/`, `dist/codex/`.
- **`CLAUDE.md`** : section « Structure du projet » enrichie avec `agents/_evals/` et sa mention « Mainteneurs uniquement, ignoré par sync.sh ».
- Tous les JSON sont validés par `jq .` (sortie OK x4).

## Validation par critère

- **`agents/_evals/README.md` avec protocole** : ✅ explique trigger rate + output quality, formats JSON, exécution hors périmètre, structure `benchmark.json` future.
- **`developer/trigger_queries.json` ≥ 20 items, 10/10, ≥ 3 near-miss** : ✅ 20 items exactement (10 positifs + 10 négatifs) ; les 10 négatifs sont tous des near-miss annotés avec la `reason` du near-miss.
- **`developer/output_evals.json` ≥ 2 cas avec assertions objectives** : ✅ 3 cas (happy, ambiguïté, mode epic) avec 4 types d'assertions utilisés.
- **`review/trigger_queries.json` idem, near-miss developer** : ✅ 20 items, 3 near-miss explicites developer (« implémente », « fix », « reprends IN PROGRESS ») + 5 autres near-miss (doc, product, brainstorm, architect, ux-ui).
- **`review/output_evals.json` ≥ 2 cas** : ✅ 3 cas (GO, NO-GO avec critère manquant, refus pour `## Implémentation` manquante) incluant `git_files_unchanged` (le reviewer ne modifie pas le code).
- **`sync.sh` n'inclut aucun fichier `_evals`** : ✅ vérifié par `ls` sur `plugins/`, `dist/cursor/`, `dist/codex/` → 0 match.
- **`sync.sh --dist-only` OK** : ✅ 7 agents syncés sans erreur, aucune mention de `_evals`.
- **`CLAUDE.md` mentionne la structure** : ✅ ligne ajoutée dans « Structure du projet » avec la précision « Mainteneurs uniquement, ignoré par sync.sh ».
- **JSON valides** : ✅ `jq .` passe sur les 4 fichiers.
