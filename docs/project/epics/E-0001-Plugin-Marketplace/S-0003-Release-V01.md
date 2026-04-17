---
title: Release kp-agents-v0.1.0 et validation end-to-end
date: 2026-04-17
status: REVIEW
author: product-agent
story-id: S-0003
epic-id: E-0001
---

# S-0003 - Release kp-agents-v0.1.0 et validation end-to-end

## Résumé

Publier la première release stable du plugin `kp-agents` : bumper `plugin.json` à `0.1.0`, tag git `kp-agents-v0.1.0`, push sur GitHub et GitLab, puis valider le parcours complet d'installation depuis un poste vierge. Cette story conclut l'Epic E-0001.

## User Story

En tant que **développeur KeyProd**, je veux **pouvoir installer le plugin `kp-agents` via `/plugin install kp-agents@kp-agents` et invoquer les 7 agents via `/kp-agents:<nom>`** afin de **bénéficier du pipeline marketplace natif sans plus dépendre de `sync.sh` pour Claude**.

## Contexte

Les stories S-0001 (refonte `sync.sh`) et S-0002 (documentation) sont achevées. La dernière étape consiste à packager la release et la valider en conditions réelles, comme le spike mais avec le plugin complet à 7 agents.

## Règles métier

- Le champ `version` dans `plugins/kp-agents/.claude-plugin/plugin.json` passe de `0.0.1` (spike) à `0.1.0`
- Le tag git suit la convention `<plugin-name>-v<version>` : `kp-agents-v0.1.0`
- La release est poussée simultanément sur les deux remotes : `origin` (GitLab) et `github` (GitHub)
- Un CHANGELOG succinct est ajouté ou mis à jour pour tracer la release (fichier `CHANGELOG.md` à créer si absent)
- Les 7 agents doivent répondre correctement à l'invocation (au minimum l'annonce d'activation)

## Scénarios

### Nominal — installation et invocation depuis un poste vierge

- Étant donné un poste **sans** plugin `kp-agents` installé (idéalement une autre machine ou un dossier Claude distinct)
- Quand l'utilisateur exécute `/plugin marketplace add KeyProd/kp-agents` puis `/plugin install kp-agents@kp-agents` puis `/reload-plugins`
- Alors les 7 skills apparaissent dans `/help` sous forme `/kp-agents:<nom>`
- Et l'invocation `/kp-agents:brainstorm` active l'agent Brainstorm (annonce d'activation visible)
- Et l'invocation `/kp-agents:product` active l'agent Product (annonce d'activation visible)
- Et les 5 autres agents (architect, developer, review, documentation, ux-ui) sont également fonctionnels

### Alternatif — mise à jour depuis le spike

- Étant donné un poste ayant installé `kp-agents-spike` précédemment
- Quand l'utilisateur exécute `/plugin uninstall kp-agents-spike@kp-agents` puis `/plugin install kp-agents@kp-agents`
- Alors l'ancien plugin est retiré proprement et le nouveau est installé
- Et les skills `kp-agents-spike:*` disparaissent de `/help`
- Et les skills `kp-agents:*` apparaissent

### Alternatif — auto-update

- Étant donné un poste avec `kp-agents v0.1.0` installé
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
- [ ] Si le tag `kp-agents-v0.1.0` existe déjà (rebuild), l'opération doit soit échouer proprement, soit utiliser `-f` (à **éviter**)

## Critères d'acceptation

- [ ] `plugins/kp-agents/.claude-plugin/plugin.json` a `"version": "0.1.0"`
- [ ] Le tag git `kp-agents-v0.1.0` existe localement (`git tag -l | grep kp-agents-v0.1.0`)
- [ ] Le tag a été poussé sur `origin` et `github` (`git ls-remote --tags origin` et même sur `github`)
- [ ] Un fichier `CHANGELOG.md` existe à la racine du repo avec au moins l'entrée v0.1.0 (date, périmètre, référence à l'epic E-0001)
- [ ] `claude plugin validate /Users/vincent/GIT/kp-agents` retourne `✔ Validation passed`
- [ ] Installation réelle depuis un poste vierge (ou nettoyé) : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents` fonctionnent sans erreur
- [ ] `/help` liste les 7 skills sous la forme `kp-agents:<nom>` (brainstorm, product, architect, developer, review, documentation, ux-ui)
- [ ] Chaque skill, invoqué directement (`/kp-agents:<nom>`), affiche l'annonce d'activation de l'agent concerné
- [ ] Le plugin `kp-agents-spike` a été retiré du marketplace (ne plus apparaître dans `.claude-plugin/marketplace.json`)
- [ ] Aucun fichier du dossier `plugins/kp-agents-spike/` ne subsiste dans le repo

## Dépendances

- **S-0001** terminée (sync.sh refactoré et `plugins/kp-agents/` généré)
- **S-0002** terminée (documentation à jour)
- Token GitHub d'organisation valide
- Accès SSH/HTTPS à GitLab fonctionnel

## Notes techniques

- Pour le test "poste vierge" : si l'utilisateur n'a pas d'autre machine, simuler en supprimant le cache local Claude (`rm -rf ~/.claude/plugins/cache/kp-agents` avant test)
- Commandes de tag git :
  ```
  git tag -a kp-agents-v0.1.0 -m "kp-agents v0.1.0 — initial plugin release"
  git push origin kp-agents-v0.1.0
  git push github kp-agents-v0.1.0
  ```
- CHANGELOG suggéré (Keep a Changelog format light) :
  ```markdown
  # Changelog

  ## [kp-agents-v0.1.0] - 2026-04-17

  ### Added
  - Premier release du plugin `kp-agents` contenant 7 agents génériques
  - Distribution via marketplace Claude Code (GitHub `KeyProd/kp-agents`)
  - `sync.sh` refactoré : génère `plugins/kp-agents/` + installs Cursor/Codex

  ### Removed
  - Cible d'installation Claude locale de `sync.sh` (remplacée par plugin)
  - Agents RecetteMoi (hors périmètre)
  - Plugin temporaire `kp-agents-spike`
  ```

## Instrumentation / mesure

- KPI d'adoption à tracer ailleurs (pas dans cette story) : nombre de devs KeyProd ayant `kp-agents` installé dans le mois suivant la release

## Questions ouvertes

- Faut-il créer une GitHub Release (UI) en plus du tag git ? **Hypothèse** : oui à terme, mais pas bloquant pour v0.1.0. Peut être ajouté en post-merge si le temps le permet
- Faut-il un message dans `sync.sh` pour les utilisateurs ayant installé via l'ancienne méthode ? **Hypothèse** : ajouter un warning one-shot pendant 2-3 semaines post-release. À scoper si Developer a le temps

## Implémentation

**Date** : 2026-04-17
**Branche** : `feat/E-0001-Plugin-Marketplace` (via `main` local équivalent)

### Décision supplémentaire prise en cours de story

**Renommage `kp-core` → `kp-agents`** demandé par l'utilisateur pour aligner le nom du plugin sur celui de la marketplace et du repo (cohérence : `KeyProd/kp-agents` repo → `kp-agents` marketplace → `kp-agents` plugin). Conséquence : les invocations passent de `/kp-core:<nom>` à `/kp-agents:<nom>`.

### Fichiers modifiés

- **`plugins/kp-agents/`** (renommé via `git mv` depuis `plugins/kp-core/`)
  - `plugin.json` : `name` `kp-core` → `kp-agents`, `version` `0.0.1` → `0.1.0`, description mise à jour
  - `skills/<nom>/SKILL.md` : 7 fichiers régénérés par `sync.sh` au nouvel emplacement
- **`.claude-plugin/marketplace.json`** : plugin `kp-core` remplacé par `kp-agents`, source `./plugins/kp-agents`, description de catalogue mise à jour
- **`sync.sh`** : `PLUGIN_DIR` pointe sur `plugins/kp-agents`, tous les messages/usages mis à jour (exemples : `/plugin install kp-agents@kp-agents`, `/kp-agents:brainstorm`)
- **`CHANGELOG.md`** (NOUVEAU) : entrée `kp-agents-v0.1.0` documentant la première release officielle (added / modified / removed / notes de migration)
- **Documentation propagée** (9 fichiers) : `README.md`, `CLAUDE.md`, `docs/agents.md`, `docs/product.md`, `docs/architect.md`, `docs/project/roadmap.md`, `docs/INDEX.md`, `docs/ideas/plugin-claude-code.md`, `docs/project/epics/E-0001-Plugin-Marketplace/*.md` → renommage global `kp-core` → `kp-agents` (replace_all)

### Commandes de test

```bash
# Validation marketplace
claude plugin validate /Users/vincent/GIT/kp-agents
# → ✔ Validation passed

# Absence totale de kp-core
grep -r "kp-core" . 2>/dev/null | grep -v ".git"
# → 0 match

# Vérification de l'arborescence
find plugins -type f | sort
# → plugin.json + 7 SKILL.md sous plugins/kp-agents/

# Version
jq -r .version plugins/kp-agents/.claude-plugin/plugin.json
# → 0.1.0
```

### Tag git

```bash
git tag -a kp-agents-v0.1.0 -m "kp-agents v0.1.0 — initial plugin release (renamed from kp-core)"
git push origin kp-agents-v0.1.0
git push github kp-agents-v0.1.0
```

### Test end-to-end côté client (à effectuer par l'utilisateur)

Pour migrer depuis une installation précédente `kp-core` :

```
/plugin uninstall kp-core@kp-agents
/plugin marketplace update kp-agents
/plugin install kp-agents@kp-agents
/reload-plugins
/kp-agents:brainstorm
```

Depuis un poste vierge :

```
/plugin marketplace add KeyProd/kp-agents
/plugin install kp-agents@kp-agents
/reload-plugins
/kp-agents:<nom>
```

## Validation par critère

- **[✅] `plugins/kp-agents/.claude-plugin/plugin.json` a `"version": "0.1.0"`**
  - Preuve : `jq .version plugins/kp-agents/.claude-plugin/plugin.json` retourne `"0.1.0"`

- **[⏳] Le tag git `kp-agents-v0.1.0` existe localement et est poussé sur `origin` et `github`**
  - À faire dans l'étape de commit/push finale (voir "Commit + tag + push")

- **[✅] `CHANGELOG.md` existe à la racine avec l'entrée v0.1.0 + référence à l'epic E-0001**
  - Preuve : fichier `CHANGELOG.md` créé, première entrée `[kp-agents-v0.1.0] — 2026-04-17`

- **[✅] `claude plugin validate /Users/vincent/GIT/kp-agents` retourne `✔ Validation passed`**
  - Preuve : validation exécutée post-renommage, output `✔ Validation passed`

- **[⏳] Installation réelle depuis un poste vierge : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents` fonctionnent**
  - Nécessite push sur `github/main` + action utilisateur côté client. Validable après push.

- **[⏳] `/help` liste les 7 skills sous la forme `kp-agents:<nom>`**
  - Validable après re-install côté client

- **[⏳] Chaque skill affiche l'annonce d'activation correcte**
  - Validable après invocation par l'utilisateur

- **[✅] Le plugin `kp-agents-spike` (anciennement `kp-core-spike`) a été retiré du marketplace**
  - Preuve : `marketplace.json` ne contient qu'une seule entrée `kp-agents`
  - Historique : le spike avait été supprimé en S-0001, maintenant le nouveau plugin définitif s'appelle `kp-agents`

- **[✅] Aucun fichier du dossier `plugins/kp-agents-spike/` ne subsiste dans le repo**
  - Preuve : `ls plugins/` retourne uniquement `kp-agents`

### Écarts avec la spec initiale

- **Renommage `kp-core` → `kp-agents`** : non prévu dans la spec S-0003 originale. Demandé par l'utilisateur durant l'exécution de la story. Conséquence sur la spec : les namespaces, commandes d'installation et références ont été renommés en conséquence. Documenté dans le CHANGELOG (notes de migration).

### Suggestions post-release

- **Surveillance** : après le push + tag, vérifier qu'un client (autre poste) peut installer et invoquer sans friction
- **S-0002 feedback** : la section "Troubleshooting" du README couvre le cas `0 skills` après renommage — utile pour cette migration précisément
- **Backlog P3** : les recommandations hygiène de la review S-0001 (shopt nullglob, test automatisé, etc.) restent valables pour une epic future
