---
title: Mise à jour de la documentation projet
date: 2026-04-17
status: TODO
author: product-agent
story-id: S-0002
epic-id: E-0001
---

# S-0002 - Mise à jour de la documentation projet

## Résumé

Aligner l'ensemble de la documentation (README.md, CLAUDE.md, docs/agents.md, docs/INDEX.md) sur la nouvelle architecture : plugin marketplace Claude Code, suppression de la cible Claude locale de `sync.sh`, retrait des agents RecetteMoi, nouveaux namespaces `/kp-core:<nom>`.

## User Story

En tant que **développeur découvrant kp-agents**, je veux que la **documentation reflète fidèlement l'architecture actuelle** afin de **comprendre comment installer et utiliser les agents sans consulter le code source**.

## Contexte

La refonte (S-0001) modifie la manière d'installer et d'invoquer les agents Claude. Sans mise à jour documentaire, un nouvel arrivant serait induit en erreur par les instructions actuelles qui mentionnent encore :
- L'installation Claude via `sync.sh` (obsolète)
- Les agents RecetteMoi (supprimés le 2026-04-17)
- Les namespaces anciens `/kp-brainstorm` (remplacés par `/kp-core:brainstorm`)
- Les flags `sync.sh` couvrant Claude local (à retirer)

## Règles métier

- Toute mention d'installation Claude via `sync.sh` doit être remplacée par la procédure plugin marketplace
- Toutes les références aux agents `recettemoi-*` doivent être retirées
- Les exemples d'invocation doivent utiliser les nouveaux namespaces `/kp-core:<nom>`
- Les schémas Mermaid dans `docs/agents.md` doivent être ajustés (labels, noms de commandes)
- `docs/INDEX.md` est maintenu par l'agent Documentation uniquement → cette story signale la mise à jour nécessaire sans la faire elle-même

## Scénarios

### Nominal — lecture linéaire du README

- Étant donné un nouveau dev qui arrive sur le repo
- Quand il lit `README.md` en partant du haut
- Alors il trouve clairement les 2 canaux d'installation (Claude via plugin, Cursor/Codex via sync.sh)
- Et les commandes d'installation Claude sont `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-core@kp-agents`
- Et aucune référence à `/kp-brainstorm` (non-namespacé) ou à `kp-recettemoi` n'apparaît

### Nominal — lecture CLAUDE.md par un contributeur

- Étant donné un contributeur qui veut modifier un agent
- Quand il lit `CLAUDE.md` section "Ajouter ou modifier un agent"
- Alors le workflow décrit inclut : édition `agents/<nom>.md`, `./sync.sh`, bump de `plugins/kp-core/.claude-plugin/plugin.json`, commit, tag, push
- Et les flags `sync.sh` documentés reflètent la nouvelle réalité (plus de mention Claude local)

### Alternatif — lecture docs/agents.md

- Étant donné un dev qui veut comprendre quel agent utiliser
- Quand il consulte `docs/agents.md`
- Alors les 7 agents génériques sont documentés (plus de section RecetteMoi)
- Et les schémas Mermaid utilisent les noms complets `/kp-core:<nom>` ou une convention explicite
- Et le workflow inter-agents reflète l'absence des agents RecetteMoi

### Erreur — vérification automatique de complétude

- Étant donné la documentation mise à jour
- Quand on lance une recherche `grep -r "recettemoi" README.md CLAUDE.md docs/agents.md`
- Alors la seule occurrence résiduelle acceptable est un historique (ex: CHANGELOG) explicitement daté

## Cas limites

- [ ] Les liens entre documents doivent rester valides (ex: `README.md` vers `docs/architect.md`)
- [ ] Les exemples de commandes ne doivent pas référencer d'agents absents (ex: `/kp-recettemoi-support` à retirer)
- [ ] `docs/INDEX.md` n'est pas modifié par cette story (maintenu par Documentation). La story signale le besoin d'appeler l'agent Documentation après merge
- [ ] Si un tableau ou une liste énumère "10 agents", mettre à jour à "7 agents"
- [ ] Le fichier `docs/product.md` créé par cette session Product est déjà aligné → pas à reprendre

## Critères d'acceptation

- [ ] `README.md` section "Utilisation" documente l'installation Claude via `/plugin marketplace add` + `/plugin install kp-core@kp-agents`
- [ ] `README.md` section "Utilisation" distingue clairement Claude (plugin) vs Cursor/Codex (`sync.sh`)
- [ ] `README.md` ne mentionne plus `--clean` ou `--clean-all` touchant Claude local
- [ ] `README.md` liste les 7 agents (plus de section "Workflow RecetteMoi")
- [ ] `CLAUDE.md` section "Structure du projet" documente `plugins/` (dossier commité généré par sync.sh)
- [ ] `CLAUDE.md` section "Ajouter ou modifier un agent" inclut le bump semver et le tag
- [ ] `CLAUDE.md` retire la table des agents RecetteMoi
- [ ] `CLAUDE.md` met à jour le diagramme Mermaid du workflow inter-agents (7 agents)
- [ ] `docs/agents.md` retire la section "Pipeline RecetteMoi" complète
- [ ] `docs/agents.md` met à jour la légende et les schémas pour refléter les namespaces `/kp-core:<nom>`
- [ ] Aucune mention résiduelle de `recettemoi-*`, `kp-recettemoi-*`, ni de `~/.claude/commands/` dans les 3 docs principales (README, CLAUDE.md, docs/agents.md)
- [ ] La story finit par déclencher explicitement un passage vers l'agent `/kp-documentation` pour maintenir `docs/INDEX.md`

## Dépendances

- **Story S-0001** doit être achevée (la refonte `sync.sh` doit être effective, sinon la doc décrirait un état irréel)
- Accès à l'ensemble des fichiers doc du repo

## Notes techniques

- Les mises à jour de `docs/agents.md` incluent une révision de 12 schémas Mermaid — vérifier la syntaxe Mermaid après édition (labels d'arêtes, noms de nœuds)
- Les emojis dans les docs sont à conserver uniquement s'ils existent déjà (pas en ajouter sauf demande explicite)
- Éviter la réécriture massive : préférer des Edits ciblés sur les sections obsolètes
- Ne pas toucher à `docs/INDEX.md` (propriété de l'agent Documentation)
- Ne pas toucher à `docs/architect.md` (propriété de l'agent Architect)
- Ne pas toucher à `docs/ideas/*` (propriété de l'agent Brainstorm)

## Instrumentation / mesure

- Après merge, un `grep -ril "recettemoi\|kp-brainstorm\s\|~/.claude/commands" README.md CLAUDE.md docs/agents.md` ne retourne aucun faux positif

## Questions ouvertes

- Faut-il archiver les anciennes versions de docs avant réécriture ? **Hypothèse** : non, l'historique git suffit
- Le `docs/agents.md` faisait 18K, mis à jour par Documentation récemment — la réécriture risque de perdre de la richesse. **Mitigation** : faire des Edits ciblés, pas de Write global

## Implémentation

*à compléter par l'agent Developer (ou Documentation si passage d'agent)*

- Fichiers créés / modifiés :
  - `README.md`
  - `CLAUDE.md`
  - `docs/agents.md`
- Commandes de test :
  - `grep -r "recettemoi\|kp-brainstorm[^:]" README.md CLAUDE.md docs/agents.md`
  - Rendu Mermaid des schémas modifiés (visuel)
- Notes de review :

## Validation par critère

*à compléter lors de la review*
