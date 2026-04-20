---
title: Préférences Git dans setup
date: 2026-04-21
status: TODO
author: product-agent
story-id: S-0007
epic-id: E-0004
---

# S-0007 - Préférences Git dans setup

## Résumé

Étendre l'agent `setup` (créé en S-0002) pour qu'il collecte et persiste des **préférences Git au niveau du projet** : règles de nommage des branches, commit automatique oui/non, push automatique oui/non. Ces préférences sont ensuite lues par les agents qui manipulent git (`developer`, `review`) pour aligner leur comportement.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux pouvoir définir les règles Git de mon projet une seule fois, afin que les agents qui touchent git (developer, review) respectent ma convention sans que je doive leur rappeler à chaque fois.

## Contexte

- Livraison progressive de l'agent `setup` : S-0002 couvre les sources, cette story étend au périmètre Git.
- Périmètre volontairement restreint à 3 préférences (branches, commit auto, push auto) — évite le sur-design.
- La persistance utilise la même mécanique que les sources : `.kp-agents.yml` (commité, car ces préférences sont spécifiques au projet et partagées en équipe).

## Règles métier

- Les 3 préférences gérées en V1 :
  1. **Convention de nommage de branches** : pattern texte, exemples `feat/{slug}`, `feature/KP-{ticket}-{slug}`, `feature/{slug}`. Libre, mais l'agent doit valider que c'est un pattern utilisable.
  2. **Commit automatique par l'agent** : oui / non / demander. Si `non`, l'agent annonce les modifications mais ne commit pas. Si `demander`, l'agent demande confirmation avant chaque commit.
  3. **Push automatique par l'agent** : oui / non / demander. Même sémantique que commit.
- Les préférences sont écrites dans `.kp-agents.yml` sous une clé `git:` dédiée :
  ```yaml
  git:
    branch_pattern: "feat/{slug}"
    auto_commit: ask        # yes | no | ask
    auto_push: no           # yes | no | ask
  ```
- **Par défaut (absence de config)** : `auto_commit: ask`, `auto_push: no`, `branch_pattern` non renseigné (l'agent ne force rien).
- Les agents `developer` et `review` lisent cette section en début de session et adaptent leur comportement.
- **Non-régression** : un projet sans section `git:` dans `.kp-agents.yml` garde exactement le comportement actuel (demande de confirmation avant commit/push).

## Scénarios

### Nominal
- Étant donné un projet avec déjà une config sources
- Quand l'utilisateur invoque `/kp-agents:setup` et demande à configurer les préférences Git
- Alors l'agent pose 3 questions (pattern de branche, auto_commit, auto_push), valide les réponses, et ajoute la section `git:` au `.kp-agents.yml`.

### Alternatif
- Étant donné un projet avec `git.auto_commit: no`
- Quand `/kp-agents:developer` termine l'implémentation d'une story
- Alors l'agent staged les changements mais **ne crée pas de commit** — il annonce à l'utilisateur ce qui est prêt et laisse la main.

### Erreur / refus
- Étant donné un `branch_pattern` mal formé (ex: `{slug` sans accolade fermante)
- Quand l'agent `setup` tente de le valider
- Alors il refuse l'entrée, explique le problème, et re-prompt.

## Cas limites

- [ ] `branch_pattern` avec un placeholder inconnu (ex: `{unknown}`) → warn mais accepter (l'utilisateur décide)
- [ ] Utilisateur invoque `setup` alors que `.kp-agents.yml` n'existe pas → `setup` crée le fichier avec la section `git:` uniquement (sources par défaut à `local`)
- [ ] Préférences présentes mais incomplètes (seulement `branch_pattern`, pas d'`auto_commit`) → utiliser valeurs par défaut pour les manquants, ne pas bloquer
- [ ] Agent `developer` ou `review` en mode `auto_commit: yes` mais la signature GPG échoue → **toujours** annoncer l'erreur à l'utilisateur, ne pas sauter silencieusement la signature

## Critères d'acceptation

- [ ] L'agent `setup` propose un flow dédié « configurer les préférences Git » distinct du flow « configurer les sources »
- [ ] Les 3 préférences sont écrites proprement sous la clé `git:` de `.kp-agents.yml`
- [ ] L'agent `setup` valide le `branch_pattern` (syntaxe parseable) avant d'enregistrer
- [ ] Les agents `developer` et `review` lisent la section `git:` et adaptent leur comportement :
  - `auto_commit: ask` (défaut) → demande avant de commit
  - `auto_commit: yes` → commit sans demander
  - `auto_commit: no` → ne commit jamais
- [ ] Même logique appliquée pour `auto_push`
- [ ] Le `branch_pattern` est respecté par `developer` lors de la création d'une branche feature
- [ ] Test manuel : configurer `auto_commit: no`, lancer une story, vérifier qu'aucun commit n'est créé
- [ ] Test manuel : configurer `auto_push: yes`, vérifier qu'après commit l'agent push sans demander
- [ ] Non-régression : projet sans section `git:` = comportement actuel (demande confirmation)

## Dépendances

- **S-0002** (agent setup existe) — bloquant
- **S-0003** (agents existants lisent la config) — souhaité pour cohérence

## Notes techniques

- La préférence `auto_commit: yes` **doit** respecter les règles globales de CLAUDE.md (jamais `--no-verify`, jamais skip hooks). Les préférences projet ne surchargent pas les règles de sécurité globales.
- Garder le périmètre strict : ne pas ajouter de convention de commit message (Conventional Commits, etc.) dans cette story — trop de choix subjectifs, candidat pour une future story.
- Le `branch_pattern` peut faire référence à des variables futures (numéro de ticket JIRA si `tickets.mode: mcp`). Documenter les placeholders supportés.

## Instrumentation / mesure

- Compter le nombre de projets qui activent `auto_commit: yes` vs `no` vs `ask` (anecdotique, pour calibrer les défauts)

## Questions ouvertes

- Faut-il supporter un `branch_pattern` différent selon le type de story (`feat/`, `fix/`, `chore/`) ? → **Décision V1 : non**, un seul pattern. Évolution candidate si le besoin se confirme.

## Implémentation

- Fichiers modifiés : `agents/setup.md` (extension du flow), `agents/developer.md` (lecture préférences), `agents/review.md` (lecture préférences)
- Commandes de test : projet test avec différentes combinaisons des 3 préférences
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
