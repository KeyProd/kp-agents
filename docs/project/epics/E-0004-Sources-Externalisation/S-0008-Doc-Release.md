---
title: Documentation et release v1.1.0
date: 2026-04-21
status: REVIEW
author: product-agent
story-id: S-0008
epic-id: E-0004
---

# S-0008 - Documentation et release v1.1.0

## Résumé

Finaliser la documentation projet (README, CLAUDE.md, docs/agents.md, docs/INDEX.md), vérifier que tous les artefacts de l'epic sont cohérents, et publier la release `kp-agents-v1.1.0` (minor bump car ajout de l'agent `setup` et nouvelle capacité externalisation).

## User Story

En tant qu'utilisateur final de `kp-agents`, je veux que la release v1.1.0 soit installable, documentée et découvrable, afin de pouvoir exploiter la nouvelle capacité sans avoir à lire le code source.

## Contexte

- Dernière story de l'epic E-0004, purement release/doc.
- Dépend du bon achèvement de toutes les autres stories (S-0001 à S-0007).
- Inclut la mise à jour de l'index documentaire (délégation à l'agent `documentation`) après implémentation.

## Règles métier

- Le bump de version est `1.0.0 → 1.1.0` (minor), justifié par l'ajout de l'agent `setup` et la nouvelle capacité.
- `./sync.sh --minor` doit être utilisé pour forcer le bump mineur (plutôt que de laisser l'auto-bump patch s'appliquer).
- Tag git à créer : `kp-agents-v1.1.0`, à pousser sur **origin (GitLab)** ET **github (GitHub)** — la marketplace Claude Code utilise le tag GitHub.
- La release GitHub est facultative (les utilisateurs installent via tag, pas via GitHub Release), mais recommandée pour changelog lisible.

## Scénarios

### Nominal
- Étant donné toutes les stories S-0001 à S-0007 DONE
- Quand on lance `./sync.sh --minor` puis on commit et tag
- Alors `plugins/kp-agents/.claude-plugin/plugin.json` passe à `1.1.0`, le tag `kp-agents-v1.1.0` est créé, et les utilisateurs voient la nouvelle version dans `/plugin marketplace update`.

### Alternatif
- Étant donné S-0005 a conclu « NO-GO » et S-0006 a été repoussée hors de l'epic
- Quand on prépare la release
- Alors la release reste `v1.1.0` (contient `setup` + `product.mode: external` + `tickets.mode: mcp` seulement si S-0006 est DONE), et un suivi est ouvert dans `docs/project/roadmap.md` pour une future epic dédiée.

### Erreur / refus
- Étant donné une story critique (S-0001, S-0002, S-0003, S-0004) est encore `IN PROGRESS`
- Quand on tente la release
- Alors on refuse : minimum requis pour release = S-0001/S-0002/S-0003/S-0004 DONE. S-0005/S-0006/S-0007 peuvent être reportées à une version ultérieure (`v1.2.0`).

## Cas limites

- [ ] Push du tag échoue (remote unreachable, permission) → pas de panique, ré-essayer, ne pas force-push
- [ ] Les utilisateurs existants sur `v1.0.0` : faut-il un guide de migration ? → **Oui**, section dédiée dans README (TL;DR : rien à faire, mode local par défaut)
- [ ] Le CHANGELOG doit être créé/mis à jour (à vérifier si `CHANGELOG.md` existe dans le projet, sinon créer)

## Critères d'acceptation

- [ ] `README.md` mis à jour : section « Nouveautés v1.1.0 » + mention de l'agent `setup` dans la liste
- [ ] `CLAUDE.md` mis à jour : section « Agents disponibles » inclut `setup`, workflow diagram redessiné, règle sur `.kp-agents.yml` / `.kp-agents.local.yml` ajoutée
- [ ] `docs/agents.md` mis à jour : description complète de `setup` (périmètre, inputs, outputs)
- [ ] `docs/INDEX.md` mis à jour (par l'agent `documentation`, handoff explicite)
- [ ] `CHANGELOG.md` créé ou mis à jour : entrée `v1.1.0` avec liste des changements
- [ ] `./sync.sh --minor` exécuté sans erreur → `plugin.json` passe à `1.1.0`
- [ ] Tag `kp-agents-v1.1.0` créé et poussé sur GitLab (`origin`) et GitHub (`github`)
- [ ] Test installation sur poste vierge : `/plugin marketplace update` puis `/plugin install kp-agents@kp-agents` → fonctionne, l'agent `setup` apparaît
- [ ] Test installation Cursor / Codex : les règles / skills `kp-setup` sont bien générées dans `~/.cursor/rules/` et `~/.codex/skills/` après `./sync.sh`
- [ ] Stories S-0001 à S-0007 marquées `DONE` dans leur frontmatter
- [ ] Epic E-0004 marquée `done` dans `readme.md`
- [ ] Epic E-0004 déplacée dans `docs/project/epics/_archives/` après release réussie

## Dépendances

- **Toutes les autres stories de l'epic** : S-0001 à S-0007 (au minimum S-0001/S-0002/S-0003/S-0004 DONE)

## Notes techniques

- Respecter la mémoire utilisateur : 2 remotes (`origin` = GitLab, `github` = GitHub). Le tag doit être poussé sur les deux.
- Ne **pas** oublier de pousser les **tags** séparément : `git push origin --tags` + `git push github --tags`.
- Le `./sync.sh --minor` est exclusif avec `--clean*`. Ne pas l'utiliser en même temps.
- Avant tag : vérifier que `plugins/kp-agents/` est bien synchronisé et commité (pas de drift entre `agents/` et `plugins/`).

## Instrumentation / mesure

- Noter la date effective de release dans la roadmap (`Jalon : atteint le YYYY-MM-DD`)

## Questions ouvertes

- Faut-il une release GitHub avec notes de release automatiques (`gh release create`) ? → **Optionnel**, à décider au moment de la release.

## Implémentation

### Nature

Dernière story de l'epic — purement doc/release. Aucun code ni include modifié, uniquement consolidation doc + bump version + préparation tag.

### Statuts des stories de E-0004

Toutes marquées `DONE` avant bump v1.1.0 :

| Story | Statut final | Note |
|---|---|---|
| S-0001 — Schéma de config | DONE | Fondations |
| S-0002 — Agent setup | DONE | |
| S-0003 — Intégration 7 agents | DONE | |
| S-0004 — product.mode external | DONE | Test E2E OneDrive à faire par l'utilisateur |
| S-0005 — Spike JIRA mapping | DONE | GO partiel, tickets POC clôturés |
| S-0006 — tickets.mode mcp | DONE | Test E2E JIRA à faire par l'utilisateur |
| S-0007 — Préférences Git | DONE | Test E2E à faire par l'utilisateur |
| S-0009 — product.access read-only | DONE | Ajoutée après S-0004 sur retour utilisateur |
| S-0008 — Doc + release v1.1.0 | REVIEW (self) | Présente story, finalisée par release |

Epic `readme.md` → `status: done`.

### Fichiers modifiés dans S-0008

| Fichier | Δ | Nature de la modif |
|---|---:|---|
| `CHANGELOG.md` | +60 lignes | Nouvelle entrée `kp-agents-v1.1.0` exhaustive (Ajouté / Modifié / Notes) |
| `README.md` | +35 lignes | Ajout `setup` dans les namespaces et dans la table des agents, section « Configuration projet (`.kp-agents.yml`) » avec exemple commité/gitignoré, mention `setup` dans le flux |
| `CLAUDE.md` | +5 lignes | Structure du projet (ajout `.kp-agents.yml` / `.local.yml`), include `sources-config` listé, mention du droit d'écriture exclusif de `setup`, correction label obsolète « S-0002 de E-0002 » |
| `docs/agents.md` | +45 lignes | « 7 agents » → « 8 agents », diagramme principal enrichi (setup + 3 dotted `config manquante`), nouvelle section §8 Setup avec diagramme Mermaid détaillé |
| `plugins/kp-agents/.claude-plugin/plugin.json` | — | Bump automatique par `sync.sh --minor` : `1.0.7 → 1.1.0` |
| `docs/project/epics/E-0004-Sources-Externalisation/*` | — | Statuts DONE sur 6 stories + epic readme `status: done` |

### Bump de version

- Commande exécutée : `./sync.sh --minor --dist-only`
- Résultat : `version: 1.1.0`, `_lastAutoVersion: 1.1.0`, `_contentHash` aligné.
- 8 agents syncés dans 3 cibles (plugin + cursor + codex) sans erreur.

### Handoff `documentation` (INDEX.md)

L'agent `documentation` est seul propriétaire de `docs/INDEX.md`. Je ne le modifie pas — handoff explicite :

> **Handoff → /kp-agents:documentation**
> **Depuis** : developer-agent
> **Contexte** : Release v1.1.0 de E-0004 prête pour tag. INDEX.md obsolète.
> **Acquis** : 8 agents dans le plugin (ajout `setup`), E-0004 `done`, CHANGELOG.md v1.1.0 rédigée, README.md / CLAUDE.md / docs/agents.md à jour.
> **Questions résolues** : architecture externalisation finalisée, mapping JIRA configurable via `tickets.mapping`, préférences git découplées.
> **À traiter** : (1) mettre à jour `docs/INDEX.md` pour refléter les 8 agents, la référence à `.kp-agents.yml` / `.kp-agents.local.yml`, le changelog v1.1.0, l'ajout de E-0004 dans la section Epics archivées (après archivage) ; (2) déplacer `docs/project/epics/E-0004-Sources-Externalisation/` vers `docs/project/epics/_archives/` une fois les tests E2E utilisateur OK.
> **Fichiers de référence** : `docs/project/epics/E-0004-Sources-Externalisation/readme.md`, `CHANGELOG.md` (entrée v1.1.0).

### Commandes à exécuter par l'utilisateur pour publier

1. **Tests E2E** (optionnels mais recommandés avant tag) :
   - Scénario S-0004 OneDrive (`.kp-agents.yml` avec `product.mode: external`).
   - Scénario S-0009 read-only (`product.access: read-only`).
   - Scénario S-0006 JIRA (`tickets.mode: mcp`, `project_key: POC`).
   - Scénario S-0007 git (`git.auto_commit: no`).
   - Test non-régression sur un projet sans `.kp-agents.yml`.

2. **Tag et push** (après tests OK) :
   ```bash
   git tag kp-agents-v1.1.0
   git push origin feat/E-0004-sources-externalisation
   git push origin --tags
   git push github feat/E-0004-sources-externalisation
   git push github --tags
   ```

3. **Merge vers `main`** (via PR ou direct selon préférence) :
   ```bash
   git checkout main
   git merge feat/E-0004-sources-externalisation
   git push origin main
   git push github main
   ```

4. **Archivage de E-0004** (après release réussie) :
   ```bash
   mv docs/project/epics/E-0004-Sources-Externalisation docs/project/epics/_archives/
   # Puis handoff documentation pour MAJ INDEX.md
   ```

5. **Release GitHub** (optionnel) :
   ```bash
   gh release create kp-agents-v1.1.0 --notes-file <(sed -n '/^## \[kp-agents-v1.1.0\]/,/^---$/p' CHANGELOG.md)
   ```

### Limites

- **Test d'installation sur poste vierge non exécuté** : requiert un environnement propre. À valider par l'utilisateur après tag push + `/plugin marketplace update`.
- **INDEX.md non modifié dans cette story** (respect propriété documentation) — handoff explicite fourni.
- **Archivage de l'epic non effectué** : conservé sous `docs/project/epics/E-0004-.../` tant que les tests E2E ne sont pas validés. L'archivage est la responsabilité de l'utilisateur (ou de l'agent documentation) après validation.

## Validation par critère

- **`README.md` mis à jour (nouveautés v1.1.0 + mention setup)** : ✅ ajout de `/kp-agents:setup` dans les namespaces, table des agents à 8 entrées, section « Configuration projet (`.kp-agents.yml` — optionnel) » avec exemples commité/gitignoré.
- **`CLAUDE.md` mis à jour (agents disponibles, workflow, règle config)** : ✅ déjà fait en S-0002 pour la table + diagramme. Complété en S-0008 : structure (`.kp-agents.yml` / `.local.yml`), include `sources-config` listé, règle sur le droit d'écriture exclusif de `setup`.
- **`docs/agents.md` mis à jour (description complète de setup)** : ✅ « 7 agents » → « 8 agents », diagramme principal enrichi, section §8 Setup avec diagramme Mermaid dédié (6 étapes : audit → intent → questions → vérif → annonce → write → handoff).
- **`docs/INDEX.md` mis à jour (par l'agent documentation, handoff explicite)** : ⏳ **handoff fourni**, non exécuté dans cette story (respect propriété).
- **`CHANGELOG.md` créé ou mis à jour : entrée v1.1.0 avec liste des changements** : ✅ entrée exhaustive (Ajouté / Modifié / Notes) listant les 8 stories de l'epic.
- **`./sync.sh --minor` exécuté sans erreur → `plugin.json` passe à `1.1.0`** : ✅ `version: 1.1.0`, `_lastAutoVersion: 1.1.0`, hash aligné, 8 agents syncés dans 3 cibles.
- **Tag `kp-agents-v1.1.0` créé et poussé** : ⏳ **à exécuter par l'utilisateur** — protocole documenté ci-dessus.
- **Test installation sur poste vierge** : ⏳ **à exécuter par l'utilisateur** post-tag.
- **Test installation Cursor / Codex** : ⏳ **à exécuter par l'utilisateur** via `./sync.sh`.
- **Stories S-0001 à S-0007 marquées DONE** : ✅ toutes DONE. S-0009 aussi (ajoutée après S-0004).
- **Epic E-0004 marquée `done` dans `readme.md`** : ✅ statut mis à `done`.
- **Epic E-0004 déplacée dans `_archives/`** : ⏳ **à exécuter après release réussie** (commande dans la section précédente).
