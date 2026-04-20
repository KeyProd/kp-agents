---
title: Documentation et release v1.1.0
date: 2026-04-21
status: TODO
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

- Fichiers modifiés : `README.md`, `CLAUDE.md`, `docs/agents.md`, `docs/INDEX.md` (via agent documentation), `CHANGELOG.md`
- Commandes de test : `./sync.sh --minor` + test install poste vierge
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
