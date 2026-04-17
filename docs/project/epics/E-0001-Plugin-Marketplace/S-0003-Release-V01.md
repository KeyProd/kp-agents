---
title: Release kp-core-v0.1.0 et validation end-to-end
date: 2026-04-17
status: TODO
author: product-agent
story-id: S-0003
epic-id: E-0001
---

# S-0003 - Release kp-core-v0.1.0 et validation end-to-end

## Résumé

Publier la première release stable du plugin `kp-core` : bumper `plugin.json` à `0.1.0`, tag git `kp-core-v0.1.0`, push sur GitHub et GitLab, puis valider le parcours complet d'installation depuis un poste vierge. Cette story conclut l'Epic E-0001.

## User Story

En tant que **développeur KeyProd**, je veux **pouvoir installer le plugin `kp-core` via `/plugin install kp-core@kp-agents` et invoquer les 7 agents via `/kp-core:<nom>`** afin de **bénéficier du pipeline marketplace natif sans plus dépendre de `sync.sh` pour Claude**.

## Contexte

Les stories S-0001 (refonte `sync.sh`) et S-0002 (documentation) sont achevées. La dernière étape consiste à packager la release et la valider en conditions réelles, comme le spike mais avec le plugin complet à 7 agents.

## Règles métier

- Le champ `version` dans `plugins/kp-core/.claude-plugin/plugin.json` passe de `0.0.1` (spike) à `0.1.0`
- Le tag git suit la convention `<plugin-name>-v<version>` : `kp-core-v0.1.0`
- La release est poussée simultanément sur les deux remotes : `origin` (GitLab) et `github` (GitHub)
- Un CHANGELOG succinct est ajouté ou mis à jour pour tracer la release (fichier `CHANGELOG.md` à créer si absent)
- Les 7 agents doivent répondre correctement à l'invocation (au minimum l'annonce d'activation)

## Scénarios

### Nominal — installation et invocation depuis un poste vierge

- Étant donné un poste **sans** plugin `kp-agents` installé (idéalement une autre machine ou un dossier Claude distinct)
- Quand l'utilisateur exécute `/plugin marketplace add KeyProd/kp-agents` puis `/plugin install kp-core@kp-agents` puis `/reload-plugins`
- Alors les 7 skills apparaissent dans `/help` sous forme `/kp-core:<nom>`
- Et l'invocation `/kp-core:brainstorm` active l'agent Brainstorm (annonce d'activation visible)
- Et l'invocation `/kp-core:product` active l'agent Product (annonce d'activation visible)
- Et les 5 autres agents (architect, developer, review, documentation, ux-ui) sont également fonctionnels

### Alternatif — mise à jour depuis le spike

- Étant donné un poste ayant installé `kp-core-spike` précédemment
- Quand l'utilisateur exécute `/plugin uninstall kp-core-spike@kp-agents` puis `/plugin install kp-core@kp-agents`
- Alors l'ancien plugin est retiré proprement et le nouveau est installé
- Et les skills `kp-core-spike:*` disparaissent de `/help`
- Et les skills `kp-core:*` apparaissent

### Alternatif — auto-update

- Étant donné un poste avec `kp-core v0.1.0` installé
- Quand une version `v0.1.1` est publiée (hypothétique, pour tester le flow) avec `version` bumpé dans `plugin.json`
- Quand l'utilisateur relance Claude Code
- Alors la nouvelle version est détectée et proposée (ou installée automatiquement selon config)

### Erreur — token GitHub expiré

- Étant donné un utilisateur dont le `GITHUB_TOKEN` est expiré
- Quand il tente `/plugin marketplace add KeyProd/kp-agents`
- Alors il obtient un message d'erreur clair indiquant le problème d'authentification
- Et la documentation `README.md` l'aide à régénérer un token

## Cas limites

- [ ] Test d'installation depuis une session Claude qui a déjà `kp-agents` en marketplace (il faut `remove` avant)
- [ ] Vérification que `sync.sh` en local et le plugin installé via marketplace n'entrent pas en conflit (en théorie non, car `sync.sh` n'installe plus sur Claude)
- [ ] Si un des 7 SKILL.md a un frontmatter invalide, le plugin devrait tout de même s'installer (Claude Code ne bloque pas sur ça selon la doc)
- [ ] Le `claude plugin validate` doit rester ✔ avant le tag
- [ ] Si le tag `kp-core-v0.1.0` existe déjà (rebuild), l'opération doit soit échouer proprement, soit utiliser `-f` (à **éviter**)

## Critères d'acceptation

- [ ] `plugins/kp-core/.claude-plugin/plugin.json` a `"version": "0.1.0"`
- [ ] Le tag git `kp-core-v0.1.0` existe localement (`git tag -l | grep kp-core-v0.1.0`)
- [ ] Le tag a été poussé sur `origin` et `github` (`git ls-remote --tags origin` et même sur `github`)
- [ ] Un fichier `CHANGELOG.md` existe à la racine du repo avec au moins l'entrée v0.1.0 (date, périmètre, référence à l'epic E-0001)
- [ ] `claude plugin validate /Users/vincent/GIT/kp-agents` retourne `✔ Validation passed`
- [ ] Installation réelle depuis un poste vierge (ou nettoyé) : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-core@kp-agents` fonctionnent sans erreur
- [ ] `/help` liste les 7 skills sous la forme `kp-core:<nom>` (brainstorm, product, architect, developer, review, documentation, ux-ui)
- [ ] Chaque skill, invoqué directement (`/kp-core:<nom>`), affiche l'annonce d'activation de l'agent concerné
- [ ] Le plugin `kp-core-spike` a été retiré du marketplace (ne plus apparaître dans `.claude-plugin/marketplace.json`)
- [ ] Aucun fichier du dossier `plugins/kp-core-spike/` ne subsiste dans le repo

## Dépendances

- **S-0001** terminée (sync.sh refactoré et `plugins/kp-core/` généré)
- **S-0002** terminée (documentation à jour)
- Token GitHub d'organisation valide
- Accès SSH/HTTPS à GitLab fonctionnel

## Notes techniques

- Pour le test "poste vierge" : si l'utilisateur n'a pas d'autre machine, simuler en supprimant le cache local Claude (`rm -rf ~/.claude/plugins/cache/kp-agents` avant test)
- Commandes de tag git :
  ```
  git tag -a kp-core-v0.1.0 -m "kp-core v0.1.0 — initial plugin release"
  git push origin kp-core-v0.1.0
  git push github kp-core-v0.1.0
  ```
- CHANGELOG suggéré (Keep a Changelog format light) :
  ```markdown
  # Changelog

  ## [kp-core-v0.1.0] - 2026-04-17

  ### Added
  - Premier release du plugin `kp-core` contenant 7 agents génériques
  - Distribution via marketplace Claude Code (GitHub `KeyProd/kp-agents`)
  - `sync.sh` refactoré : génère `plugins/kp-core/` + installs Cursor/Codex

  ### Removed
  - Cible d'installation Claude locale de `sync.sh` (remplacée par plugin)
  - Agents RecetteMoi (hors périmètre)
  - Plugin temporaire `kp-core-spike`
  ```

## Instrumentation / mesure

- KPI d'adoption à tracer ailleurs (pas dans cette story) : nombre de devs KeyProd ayant `kp-core` installé dans le mois suivant la release

## Questions ouvertes

- Faut-il créer une GitHub Release (UI) en plus du tag git ? **Hypothèse** : oui à terme, mais pas bloquant pour v0.1.0. Peut être ajouté en post-merge si le temps le permet
- Faut-il un message dans `sync.sh` pour les utilisateurs ayant installé via l'ancienne méthode ? **Hypothèse** : ajouter un warning one-shot pendant 2-3 semaines post-release. À scoper si Developer a le temps

## Implémentation

*à compléter par l'agent Developer*

- Fichiers créés / modifiés :
  - `plugins/kp-core/.claude-plugin/plugin.json` (version)
  - `.claude-plugin/marketplace.json` (retrait `kp-core-spike`)
  - `CHANGELOG.md` (nouveau)
  - Suppression du dossier `plugins/kp-core-spike/`
- Commandes de test :
  - `claude plugin validate /Users/vincent/GIT/kp-agents`
  - `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-core@kp-agents` + `/reload-plugins`
  - Invocations des 7 skills
- Notes de review :

## Validation par critère

*à compléter lors de la review*
