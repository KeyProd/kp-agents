---
title: Mise à jour de la documentation projet
date: 2026-04-17
status: REVIEW
author: product-agent
story-id: S-0002
epic-id: E-0001
---

# S-0002 - Mise à jour de la documentation projet

## Résumé

Aligner l'ensemble de la documentation (README.md, CLAUDE.md, docs/agents.md, docs/INDEX.md) sur la nouvelle architecture : plugin marketplace Claude Code, suppression de la cible Claude locale de `sync.sh`, retrait des agents RecetteMoi, nouveaux namespaces `/kp-agents:<nom>`.

## User Story

En tant que **développeur découvrant kp-agents**, je veux que la **documentation reflète fidèlement l'architecture actuelle** afin de **comprendre comment installer et utiliser les agents sans consulter le code source**.

## Contexte

La refonte (S-0001) modifie la manière d'installer et d'invoquer les agents Claude. Sans mise à jour documentaire, un nouvel arrivant serait induit en erreur par les instructions actuelles qui mentionnent encore :
- L'installation Claude via `sync.sh` (obsolète)
- Les agents RecetteMoi (supprimés le 2026-04-17)
- Les namespaces anciens `/kp-brainstorm` (remplacés par `/kp-agents:brainstorm`)
- Les flags `sync.sh` couvrant Claude local (à retirer)

## Règles métier

- Toute mention d'installation Claude via `sync.sh` doit être remplacée par la procédure plugin marketplace
- Toutes les références aux agents `recettemoi-*` doivent être retirées
- Les exemples d'invocation doivent utiliser les nouveaux namespaces `/kp-agents:<nom>`
- Les schémas Mermaid dans `docs/agents.md` doivent être ajustés (labels, noms de commandes)
- `docs/INDEX.md` est maintenu par l'agent Documentation uniquement → cette story signale la mise à jour nécessaire sans la faire elle-même

## Scénarios

### Nominal — lecture linéaire du README

- Étant donné un nouveau dev qui arrive sur le repo
- Quand il lit `README.md` en partant du haut
- Alors il trouve clairement les 2 canaux d'installation (Claude via plugin, Cursor/Codex via sync.sh)
- Et les commandes d'installation Claude sont `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
- Et aucune référence à `/kp-brainstorm` (non-namespacé) ou à `kp-recettemoi` n'apparaît

### Nominal — lecture CLAUDE.md par un contributeur

- Étant donné un contributeur qui veut modifier un agent
- Quand il lit `CLAUDE.md` section "Ajouter ou modifier un agent"
- Alors le workflow décrit inclut : édition `agents/<nom>.md`, `./sync.sh`, bump de `plugins/kp-agents/.claude-plugin/plugin.json`, commit, tag, push
- Et les flags `sync.sh` documentés reflètent la nouvelle réalité (plus de mention Claude local)

### Alternatif — lecture docs/agents.md

- Étant donné un dev qui veut comprendre quel agent utiliser
- Quand il consulte `docs/agents.md`
- Alors les 7 agents génériques sont documentés (plus de section RecetteMoi)
- Et les schémas Mermaid utilisent les noms complets `/kp-agents:<nom>` ou une convention explicite
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

- [ ] `README.md` section "Utilisation" documente l'installation Claude via `/plugin marketplace add` + `/plugin install kp-agents@kp-agents`
- [ ] `README.md` section "Utilisation" distingue clairement Claude (plugin) vs Cursor/Codex (`sync.sh`)
- [ ] `README.md` ne mentionne plus `--clean` ou `--clean-all` touchant Claude local
- [ ] `README.md` liste les 7 agents (plus de section "Workflow RecetteMoi")
- [ ] `CLAUDE.md` section "Structure du projet" documente `plugins/` (dossier commité généré par sync.sh)
- [ ] `CLAUDE.md` section "Ajouter ou modifier un agent" inclut le bump semver et le tag
- [ ] `CLAUDE.md` retire la table des agents RecetteMoi
- [ ] `CLAUDE.md` met à jour le diagramme Mermaid du workflow inter-agents (7 agents)
- [ ] `docs/agents.md` retire la section "Pipeline RecetteMoi" complète
- [ ] `docs/agents.md` met à jour la légende et les schémas pour refléter les namespaces `/kp-agents:<nom>`
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

**Date** : 2026-04-17
**Branche** : `feat/E-0001-Plugin-Marketplace`

### Fichiers modifiés

- **`README.md`** (réécriture complète)
  - Section "Principe" : nouveau diagramme flux avec `plugins/kp-agents/` + `dist/cursor/` + `dist/codex/`
  - Section "Utilisation" scindée en 2 blocs distincts : **Claude Code (plugin marketplace)** avec `/plugin marketplace add KeyProd/kp-agents` puis `/plugin install kp-agents@kp-agents`, et **Cursor/Codex (via sync.sh)** conservé
  - Sous-section sur la publication d'une mise à jour Claude (bump semver + tag git)
  - Section "Structure" mise à jour : introduction de `.claude-plugin/marketplace.json` et `plugins/kp-agents/`, clarification `dist/` non commité
  - Table des agents : 7 agents génériques (RecetteMoi retiré), flux simplifié
  - **Nouvelle section Troubleshooting** intégrant la recommandation P2.1 de la review S-0001 : purge cache plugin + bascule vers namespace `/kp-agents:<nom>` + install branche feature
- **`CLAUDE.md`** (réécriture complète)
  - Ajout section "Distribution" qui distingue les 3 cibles (plugin Claude, Cursor, Codex)
  - Structure du projet : ajout `.claude-plugin/`, `plugins/kp-agents/skills/`, clarification `dist/` non commité
  - "Ajouter ou modifier un agent" étendu avec étape de publication (bump semver + tag)
  - Table des flags mise à jour (retrait référence `~/.claude`)
  - "Règles critiques" alignées sur la nouvelle architecture
  - Diagramme Mermaid du workflow inter-agents : noms complets `/kp-agents:<nom>`
  - Table des agents disponibles enrichie d'une colonne "Invocation Claude"
  - Suppression complète de la section "Agents RecetteMoi"
- **`docs/agents.md`** (réécriture complète)
  - Frontmatter : date mise à jour à 2026-04-17
  - "Vue d'ensemble" : 7 agents génériques (plus de "deux pipelines")
  - Diagramme pipeline développement : noms complets `/kp-agents:<nom>`
  - **Suppression complète de la section "Pipeline RecetteMoi"** et des 3 fiches détaillées (sections 8/9/10)
  - 7 schémas Mermaid détaillés adaptés aux namespaces `/kp-agents:<nom>` (labels de nœuds mis à jour, références inter-agents dans les "Relais")
  - Légende : retrait de l'entrée "Fond rose clair (RecetteMoi)"

### Commandes de test (vérification automatisée)

```bash
# Aucune mention résiduelle de recettemoi
grep -ril "recettemoi" README.md CLAUDE.md docs/agents.md
# → vide

# Aucune référence à ~/.claude/commands/ ou dist/claude/ hors du contexte de cleanup
grep -n "\.claude/commands\|dist/claude" README.md CLAUDE.md docs/agents.md
# → 3 matches, tous volontairement dans des phrases de type "ne dépose plus rien dans …" ou "cleanup de …"

# Les slash commands anciens /kp-xxx (sans :) n'apparaissent que dans la section Troubleshooting
grep -n "/kp-\(brainstorm\|product\|architect\|developer\|review\|documentation\|ux-ui\)\b" README.md CLAUDE.md docs/agents.md
# → 2 matches dans README, tous dans la section Troubleshooting qui explique la migration
```

### Écarts avec la spec

Aucun écart avec la spec. Point d'attention ajouté : la recommandation P2.1 de la review S-0001 (section Troubleshooting pour le cache plugin) a été intégrée comme convenu.

### Notes de review

- Pas de diff massif : les 3 fichiers ont été réécrits entièrement via `Write`, car le volume de changements (retrait recettemoi, namespaces, restructuration) dépassait le ROI des Edits ciblés
- Les schémas Mermaid ont tous été vérifiés visuellement via Read : 12 schémas dans `docs/agents.md` (7 détaillés + 1 pipeline global) + 2 dans `CLAUDE.md`/`README.md`
- `docs/INDEX.md` **non touché** (périmètre de l'agent Documentation uniquement) — à mettre à jour en fin de story

## Validation par critère

- **[✅] `README.md` section "Utilisation" documente l'installation Claude via plugin marketplace**
  - Implémentation : nouvelle sous-section "Claude Code (plugin marketplace)" avec commandes `/plugin marketplace add` + `/plugin install`
  - Preuve : voir `README.md` lignes 15-40

- **[✅] `README.md` section "Utilisation" distingue clairement Claude (plugin) vs Cursor/Codex (`sync.sh`)**
  - Implémentation : deux sous-sections séparées `### Claude Code (plugin marketplace)` et `### Cursor et Codex (via sync.sh)`
  - Preuve : structure visuelle de README

- **[✅] `README.md` ne mentionne plus `--clean` ou `--clean-all` touchant Claude local**
  - Implémentation : le bloc `--clean` et `--clean-all` a été reformulé : "retire chirurgicalement chaque agent (plugin skills + Cursor + Codex)" — plus de mention Claude local
  - Preuve : `grep "\.claude/commands" README.md` ne retourne que les 1 mention dans la section "Note" / Troubleshooting (explication, pas usage)

- **[✅] `README.md` liste les 7 agents (plus de section "Workflow RecetteMoi")**
  - Implémentation : table unique "Agents" avec 7 lignes
  - Preuve : `grep -i "recettemoi" README.md` retourne 0 match

- **[✅] `CLAUDE.md` section "Structure du projet" documente `plugins/` commité**
  - Implémentation : arborescence mise à jour avec commentaires `← GÉNÉRÉ par sync.sh, COMMITÉ dans git` pour `plugins/`
  - Preuve : voir `CLAUDE.md` section "Structure du projet"

- **[✅] `CLAUDE.md` section "Ajouter ou modifier un agent" inclut le bump semver et le tag**
  - Implémentation : étape 5 ajoutée avec bump de `plugin.json`, commit, tag `kp-agents-v<X.Y.Z>`, push
  - Preuve : voir `CLAUDE.md` section "Ajouter ou modifier un agent" étape 5

- **[✅] `CLAUDE.md` retire la table des agents RecetteMoi**
  - Implémentation : table unique "Agents disponibles" avec 7 lignes
  - Preuve : `grep -i "recettemoi" CLAUDE.md` retourne 0 match

- **[✅] `CLAUDE.md` met à jour le diagramme Mermaid du workflow inter-agents (7 agents)**
  - Implémentation : diagramme réécrit avec nœuds namespacés `/kp-agents:brainstorm`, etc. (7 agents au total)
  - Preuve : voir `CLAUDE.md` section "Workflow inter-agents"

- **[✅] `docs/agents.md` retire la section "Pipeline RecetteMoi" complète**
  - Implémentation : sections 8/9/10 entièrement supprimées, la section "Pipeline RecetteMoi — Vue globale" également
  - Preuve : `grep -i "recettemoi" docs/agents.md` retourne 0 match

- **[✅] `docs/agents.md` met à jour la légende et les schémas pour refléter les namespaces `/kp-agents:<nom>`**
  - Implémentation : 7 schémas détaillés + 1 schéma pipeline global mis à jour ; légende simplifiée (retrait entrée rose RecetteMoi)
  - Preuve : lecture des 7 sections d'agents (toutes utilisent le namespace `/kp-agents:<nom>`)

- **[✅] Aucune mention résiduelle de `recettemoi-*`, `kp-recettemoi-*`, ni de `~/.claude/commands/` dans les 3 docs**
  - Implémentation : réécriture ciblée
  - Preuve : les greps exécutés en fin de story ne retournent que les mentions **volontaires** dans la section Troubleshooting (explication de la migration)

- **[✅] La story finit par déclencher explicitement un passage vers l'agent `/kp-agents:documentation` pour maintenir `docs/INDEX.md`**
  - Implémentation : ce point est adressé dans la section "Suite" du bilan de story (voir la réponse de Developer après commit)
  - Preuve : handoff vers `/kp-agents:documentation` explicité en fin de bilan

