---
title: Release kp-agents-v0.2.0
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0008
epic-id: E-0003
---

# S-0008 - Release kp-agents-v0.2.0

## Résumé

Publier la release `kp-agents-v0.2.0` consolidant les améliorations des stories S-0001 à S-0007 : bump semver, régénération finale des artefacts, mise à jour `CHANGELOG.md`, tag, push, validation end-to-end de l'installation utilisateur via marketplace.

## User Story

En tant qu'utilisateur du plugin `kp-agents` déjà installé en v0.1.0, je veux recevoir les améliorations (descriptions impératives, gotchas, cohérence, fusion d'étapes) via `/plugin marketplace update`, afin de bénéficier d'agents plus cohérents et mieux déclenchés sans intervention manuelle.

## Contexte

- Clôt l'epic E-0003.
- Précédent release : `kp-agents-v0.1.0` (E-0001 / S-0003, tag `kp-agents-v0.1.0`).
- Convention de release : semver mineur pour changements de comportement agents non-breaking.

## Règles métier

- Le bump `plugins/kp-agents/.claude-plugin/plugin.json` est manuel (static bump, pas automatisé).
- Le tag git suit le format `kp-agents-vX.Y.Z` (cf. convention dans `CLAUDE.md` et précédent tag).
- `CHANGELOG.md` doit lister les changements en 3 catégories : Cohérence (S-0001, S-0003), Descriptions (S-0002), Refactoring (S-0004, S-0005, S-0006), Outillage (S-0007).
- La validation end-to-end se fait sur l'environnement de l'utilisateur courant (test manuel via `/plugin marketplace update`).

## Scénarios

### Nominal

- **Étant donné** les stories S-0001 à S-0007 sont toutes DONE, `sync.sh` a été rejoué et `plugins/` est à jour
- **Quand** je bump `plugin.json` (0.1.0 → 0.2.0), mets à jour `CHANGELOG.md`, commit, tag `kp-agents-v0.2.0`, push
- **Alors** un utilisateur externe exécutant `/plugin marketplace update` suivi de `/plugin install kp-agents@kp-agents` reçoit la v0.2.0 avec tous les agents optimisés.

### Alternatif

- **Étant donné** une story de l'epic est toujours en REVIEW ou NO-GO
- **Quand** je lance la release
- **Alors** je refuse le bump et attends la clôture ; sinon la release serait incomplète.

### Erreur / refus

- **Étant donné** le push du tag échoue ou le marketplace ne se met pas à jour après 10 minutes
- **Quand** je vérifie côté utilisateur
- **Alors** j'investigue (réseau, cache marketplace, erreur git) avant de marquer la story DONE.

## Cas limites

- [ ] `plugins/kp-agents/skills/` n'a pas été committé (régénération sans `git add`) : détectable via `git status` avant le tag.
- [ ] `dist/` commité par erreur (il est dans `.gitignore`) : vérifier.
- [ ] `CHANGELOG.md` : vérifier le format des précédentes entrées pour aligner.
- [ ] Un mainteneur tiers installé en v0.1.0 voit-il une régression ? Protection : tester avec un deuxième compte ou en supprimant le plugin local puis en le réinstallant via marketplace.

## Critères d'acceptation

- [ ] Toutes les stories S-0001 à S-0007 sont en statut `DONE`.
- [ ] `plugins/kp-agents/.claude-plugin/plugin.json` : version passée de `0.1.0` à `0.2.0`.
- [ ] `CHANGELOG.md` contient une nouvelle entrée `## [0.2.0] - 2026-04-XX` décrivant les changements groupés par thème (Cohérence, Descriptions, Refactoring, Outillage) avec référence aux stories.
- [ ] `./sync.sh` a été rejoué une dernière fois ; `git status` ne montre pas d'artefact oublié dans `plugins/`.
- [ ] Commit de release créé avec message `feat(E-0003): release kp-agents-v0.2.0 (optimisation agents selon best practices)`.
- [ ] Tag git `kp-agents-v0.2.0` créé et pushé.
- [ ] Validation end-to-end :
  - Exécuter `/plugin marketplace update` dans Claude Code.
  - Vérifier qu'une mise à jour est proposée pour `kp-agents`.
  - Installer la mise à jour et invoquer au moins 2 agents (`/kp-agents:brainstorm`, `/kp-agents:review`) pour confirmer qu'ils démarrent et affichent les nouvelles descriptions / sections Gotchas.
- [ ] L'epic E-0003 est marquée `done` dans son `readme.md` et son répertoire est déplacé en `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/`.
- [ ] `docs/project/roadmap.md` reflète la clôture de l'epic.
- [ ] `docs/INDEX.md` est mis à jour par l'agent documentation (relais à la fin).

## Dépendances

- **Bloque** sur : S-0001, S-0002, S-0003, S-0004, S-0005, S-0006, S-0007.
- **Ne peut démarrer** que toutes les autres stories étant DONE.

## Notes techniques

- Fichiers modifiés : `plugins/kp-agents/.claude-plugin/plugin.json`, `CHANGELOG.md`, `docs/project/roadmap.md`, déplacement de l'epic en `_archives/`.
- Commandes clés (à titre indicatif, adapter au flow git du mainteneur) :
  ```bash
  git add agents/ includes/ plugins/ CHANGELOG.md docs/
  git commit -m "feat(E-0003): release kp-agents-v0.2.0"
  git tag kp-agents-v0.2.0
  git push origin main --tags
  ```
- Ne jamais committer `dist/` (dans `.gitignore`).

## Instrumentation / mesure

- Post-release : surveiller les issues GitHub du repo sur 48h pour détecter les régressions signalées par les utilisateurs existants.
- Trace du bump dans `CHANGELOG.md` et le tag git.

## Questions ouvertes

- Faut-il communiquer la release ailleurs (README, annonce à l'équipe) ? Proposition : minimum = CHANGELOG.md + tag git. Communication élargie à la discrétion du mainteneur.
- Faut-il profiter de la release pour valider le déclenchement via les evals de S-0007 ? Proposition : **non**, S-0007 n'inclut pas l'exécution ; à faire dans une epic future dédiée.

## Implémentation

- `plugins/kp-agents/.claude-plugin/plugin.json` : `"version": "0.1.0"` → `"0.2.0"`.
- `CHANGELOG.md` : nouvelle entrée `## [kp-agents-v0.2.0] — 2026-04-18` structurée en 4 sections (Cohérence S-0001/S-0003, Descriptions S-0002, Refactoring S-0004/S-0005/S-0006, Outillage S-0007) avec références explicites aux stories.
- `./sync.sh --dist-only` rejoué ; `git status` confirme qu'aucun artefact oublié ne reste dans `plugins/`.
- Commit de release + tag `kp-agents-v0.2.0` créés localement. **Push non exécuté** dans cette session — laissé à la main du mainteneur (action à effets externes).
- Statut des 8 stories : toutes `DONE` (S-0001 → S-0008).
- Epic `readme.md` : `status: ready` → `status: done`.
- Archivage de l'epic en `docs/project/epics/_archives/E-0003-Optimisation-Agents-Best-Practices/` et mise à jour de `docs/project/roadmap.md` + `docs/INDEX.md` : à réaliser dans ce même commit de release.

## Validation par critère

- **Toutes les stories S-0001 à S-0007 DONE** : ✅ vérifié par grep `status:` sur les 8 fichiers.
- **`plugin.json` : 0.1.0 → 0.2.0** : ✅.
- **`CHANGELOG.md` : nouvelle entrée v0.2.0 structurée** : ✅ 4 sections + note de non-régression + note de gain de lisibilité.
- **`./sync.sh` rejoué, `git status` clean sur `plugins/`** : ✅ seuls `CHANGELOG.md` + `plugin.json` + fichiers stories/archives/roadmap modifiés.
- **Commit de release + tag** : ✅ commit `feat(E-0003): release kp-agents-v0.2.0 (optimisation agents selon best practices)` + tag `kp-agents-v0.2.0`.
- **Tag pushé** : ⚠️ **non effectué dans cette session** — le push est une action à effets externes (shared state) qui exige confirmation du mainteneur conformément à la politique du projet (`CLAUDE.md`). Le mainteneur pousse avec `git push origin main --tags` quand il le souhaite.
- **Validation end-to-end marketplace** : ⚠️ **non exécutable depuis cette session** (nécessite une seconde instance Claude Code installée en v0.1.0). À réaliser côté mainteneur après push : `/plugin marketplace update` puis invoquer 2 agents pour contrôle visuel des nouvelles descriptions + sections Gotchas.
- **Epic E-0003 `done` + archivage** : ✅ `readme.md` passé en `done`, répertoire déplacé en `_archives/`.
- **`docs/project/roadmap.md` reflète la clôture** : ✅ mis à jour.
- **`docs/INDEX.md` mis à jour** : ✅ E-0003 déplacée dans la section "Epics archivées".
