---
title: Agent setup (périmètre sources)
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0002
epic-id: E-0004
---

# S-0002 - Agent setup (périmètre sources)

## Résumé

Créer le 8ᵉ agent `setup`, dédié à la configuration projet. Périmètre initial : gérer les sources (`product.mode`, `tickets.mode`, chemins) via conversation avec l'utilisateur. Les préférences Git arriveront en S-0007 (livraison progressive).

## User Story

En tant qu'utilisateur de `kp-agents`, je veux un agent dédié à la configuration de mon projet, afin de ne pas éditer manuellement les fichiers de config et d'être guidé par des questions claires.

## Contexte

- Le brainstorm (S-0002 de la logique de l'epic) a décidé d'un agent unique évolutif plutôt que de disperser la config entre plusieurs agents.
- Périmètre initial volontairement restreint aux sources pour livrer vite. S-0007 étendra à Git.
- L'agent doit être invocable directement (`/kp-agents:setup`) ET via auto-redirect depuis un autre agent qui détecte une config manquante.

## Règles métier

- L'agent audite l'état courant avant de prompter : s'il existe déjà une config valide, il l'affiche et demande ce que l'utilisateur veut modifier.
- L'agent ne modifie **jamais** un `.kp-agents.yml` sans confirmation explicite.
- L'agent écrit `.kp-agents.local.yml` uniquement si une dimension externe est activée (sinon inutile).
- L'agent ajoute automatiquement `.kp-agents.local.yml` au `.gitignore` si l'entrée n'y est pas.
- L'agent vérifie l'accessibilité du chemin `product.path` (lecture) avant de l'enregistrer et warn si inaccessible.
- À la fin, l'agent propose un handoff vers l'agent approprié (souvent `/kp-agents:product` si on vient d'activer le mode externe).

## Scénarios

### Nominal
- Étant donné un projet vierge sans `.kp-agents.yml`
- Quand l'utilisateur invoque `/kp-agents:setup`
- Alors l'agent lui pose 3-4 questions (sources product locale/externe, sources tickets locale/mcp, chemin OneDrive si externe, clé JIRA si mcp) et écrit les fichiers de config + mise à jour du `.gitignore`.

### Alternatif
- Étant donné un projet avec config complète et valide
- Quand l'utilisateur invoque `/kp-agents:setup`
- Alors l'agent affiche la config courante et demande quoi modifier (ou confirme que tout est OK).

### Erreur / refus
- Étant donné l'utilisateur renseigne un `product.path` inaccessible (dossier inexistant, permissions insuffisantes)
- Quand l'agent vérifie le chemin
- Alors il warn, propose 3 options : (a) corriger le chemin, (b) enregistrer quand même en mode dégradé, (c) annuler.

## Cas limites

- [ ] Utilisateur annule en cours de configuration → l'agent ne laisse pas de fichiers partiels
- [ ] `.gitignore` inexistant → l'agent le crée avec la seule entrée `.kp-agents.local.yml`
- [ ] Utilisateur redéclenche `setup` alors qu'une session d'un autre agent est active → pas de lock, comportement transparent (le prochain agent relira la config)
- [ ] Projet avec un `.kp-agents.yml` mais pas de `.kp-agents.local.yml` alors que mode externe actif → l'agent complète sans tout réécraser

## Critères d'acceptation

- [ ] Fichier `agents/setup.md` créé avec frontmatter conforme (`name`, `description`, `short_description`, `default_prompt`)
- [ ] L'agent inclut `{{include:activation}}`, `{{include:handoff}}`, `{{include:sources-config}}`, et `{{include:gotchas-transverses}}`
- [ ] Invocation `/kp-agents:setup` fonctionne après `./sync.sh` (plugin Claude Code)
- [ ] Présence dans `dist/cursor/kp-setup.mdc` et `dist/codex/kp-setup/` après `./sync.sh`
- [ ] Présence dans `.claude-plugin/marketplace.json` (liste des agents du plugin)
- [ ] Mise à jour de `CLAUDE.md` : section « Agents disponibles » inclut `setup`, workflow diagram mis à jour
- [ ] L'agent audite l'existant avant de prompter (lit `.kp-agents.yml` si présent)
- [ ] L'agent crée/met à jour `.kp-agents.yml`, `.kp-agents.local.yml`, `.gitignore`
- [ ] L'agent vérifie l'accessibilité du `product.path` (test de lecture) avant d'enregistrer
- [ ] Test manuel : depuis un projet vierge, `/kp-agents:setup` génère une config fonctionnelle pour les 4 combinaisons (local/local, external/local, local/mcp, external/mcp)
- [ ] Release automatique minor bump car ajout d'agent (géré par `sync.sh --minor` au moment de la release)

## Dépendances

- **S-0001** : le schéma de config doit être défini avant que `setup` puisse l'écrire.

## Notes techniques

- L'agent `setup` est le seul qui écrit dans `.kp-agents.yml` et `.kp-agents.local.yml` → les autres agents sont en **lecture seule** sur ces fichiers.
- Le prompt par défaut (`default_prompt`) doit démarrer par un audit de l'état courant (lire ce qui existe avant de prompter).
- Prévoir un `short_description` explicite pour que l'utilisateur comprenne à quoi sert l'agent dès la liste des commandes.

## Instrumentation / mesure

- Nombre de questions posées en mode fresh setup (attendu : ≤ 5) — indicateur de fluidité.

## Questions ouvertes

- Faut-il un mode `--dry-run` qui affiche ce qui serait écrit sans modifier les fichiers ? → **Décision V1 : non**, l'agent annonce ce qu'il va faire avant d'écrire.

## Implémentation

### Fichiers créés / modifiés

- **`agents/setup.md`** (créé) — 153 lignes source / 285 lignes après résolution des includes dans le SKILL.md Claude. Frontmatter complet (`name`, `description`, `short_description`, `default_prompt`, `user-invocable: true`). Process 5 étapes (audit → intention → questions → vérification → écriture atomique). 6 includes résolus : `activation`, `gotchas-transverses`, `handoff`, `sources-config`, `docs-structure-light`.
- **`.claude-plugin/marketplace.json`** (modifié) — description enrichie (ajout `setup` dans la liste des 8 agents).
- **`plugins/kp-agents/.claude-plugin/plugin.json`** (modifié) — description alignée sur les 8 agents. Version auto-bumpée 1.0.0 → 1.0.1 (SHA256 `08ed4375…`). Ce patch bump sera **écrasé par un minor bump `--minor` à la release S-0008** (règle : ajout d'agent = minor) ; acceptable tel quel pendant l'epic.
- **`CLAUDE.md`** (modifié) — section « Agents disponibles » : ligne `setup` ajoutée. Workflow diagram mermaid : node `setup` avec arête `setup → product` (config prête) + 3 arêtes pointillées auto-redirect depuis `product`, `architect`, `developer` (config manquante). Commentaire pipeline mis à jour.

### Sync et non-régression

`./sync.sh --dist-only` → **8 agents syncés** (les 7 existants + `setup`) dans les 3 cibles :
- `plugins/kp-agents/skills/setup/SKILL.md` (285 lignes, includes résolus)
- `dist/cursor/kp-setup.mdc`
- `dist/codex/kp-setup/SKILL.md` + `dist/codex/kp-setup/agents/`

Vérification de la résolution des includes dans le SKILL.md Claude :
- `grep '{{include'` → **0 résidu** non résolu
- `grep 'Configuration des sources'` → 1 seul match (titre H2 de l'include `sources-config.md` correctement inliné à la ligne 161)

### Limites de validation

- **Test conversationnel end-to-end non exécuté** : le comportement de l'agent dépend de l'interaction utilisateur en temps réel, non reproductible dans cette implémentation. Le test manuel des 4 combinaisons (`local/local`, `external/local`, `local/mcp`, `external/mcp`) doit être fait par l'utilisateur sur un projet vierge après distribution. Critère d'acceptation correspondant marqué « non vérifié » ci-dessous.
- **Auto-redirect depuis autres agents non implémenté dans cette story** : c'est le périmètre de S-0003. Le diagramme CLAUDE.md anticipe le flux, mais aucun des 7 agents existants ne référence `/kp-agents:setup` aujourd'hui.

### Commandes de test

- Génération : `./sync.sh --dist-only` puis vérifier que `plugins/kp-agents/skills/setup/SKILL.md` existe et n'a aucun `{{include` résiduel (`grep '{{include' plugins/kp-agents/skills/setup/SKILL.md`).
- Test utilisateur (manuel, post-merge) : depuis un dossier vierge, installer le plugin puis invoquer `/kp-agents:setup` et dérouler les 4 combinaisons.

## Validation par critère

- **Fichier `agents/setup.md` créé avec frontmatter conforme** : ✅ créé à [agents/setup.md](agents/setup.md). Frontmatter : `name: setup`, `description` (décrit déclencheurs + auto-redirect + périmètre), `short_description: "KeyProd Setup — Configurer les sources du projet"`, `default_prompt: "Utilise $kp-setup pour configurer les sources du projet."`, `user-invocable: true`.
- **L'agent inclut `{{include:activation}}`, `{{include:handoff}}`, `{{include:sources-config}}`, et `{{include:gotchas-transverses}}`** : ✅ les 4 includes présents, + `{{include:docs-structure-light}}` bonus pour cohérence avec les autres agents. Résolution vérifiée : 0 directive résiduelle dans le SKILL.md généré.
- **Invocation `/kp-agents:setup` fonctionne après `./sync.sh` (plugin Claude Code)** : ✅ `plugins/kp-agents/skills/setup/SKILL.md` généré, taille 285 lignes, frontmatter valide. L'invocation réelle sera testée post-distribution. Limite : test end-to-end dans un projet Claude Code non exécuté (dépend de la distribution via marketplace).
- **Présence dans `dist/cursor/kp-setup.mdc` et `dist/codex/kp-setup/` après `./sync.sh`** : ✅ les deux fichiers sont bien générés (`ls dist/cursor/kp-setup.mdc dist/codex/kp-setup/` retourne les artefacts attendus).
- **Présence dans `.claude-plugin/marketplace.json` (liste des agents du plugin)** : ✅ description mise à jour dans `.claude-plugin/marketplace.json` et `plugins/kp-agents/.claude-plugin/plugin.json` (8 agents listés).
- **Mise à jour de `CLAUDE.md` : section « Agents disponibles » inclut `setup`, workflow diagram mis à jour** : ✅ ligne `setup` ajoutée au tableau (ligne 135), diagramme mermaid enrichi avec node `S`, arête `setup → product` et 3 arêtes pointillées auto-redirect. Commentaire pipeline mis à jour pour citer setup comme agent transversal.
- **L'agent audite l'existant avant de prompter (lit `.kp-agents.yml` si présent)** : ✅ processus documenté en étape 1 du skill : « Audit de l'existant (obligatoire, avant toute question) » — lecture systématique des 3 fichiers (`.kp-agents.yml`, `.kp-agents.local.yml`, `.gitignore`) et production d'un rapport avant toute question. Limite : comportement non testable statiquement (dépend de l'exécution par l'agent).
- **L'agent crée/met à jour `.kp-agents.yml`, `.kp-agents.local.yml`, `.gitignore`** : ✅ règle documentée en étape 5 du skill avec ordre d'écriture atomique. Gotcha explicite : « Jamais d'écriture partielle » + « `.gitignore` auto-complété ».
- **L'agent vérifie l'accessibilité du `product.path` (test de lecture) avant d'enregistrer** : ✅ documenté en étape 4 du skill, avec 3 options en cas d'échec (corriger / mode dégradé / annuler). Le test réel utilise `Read` sur le chemin cible.
- **Test manuel : depuis un projet vierge, `/kp-agents:setup` génère une config fonctionnelle pour les 4 combinaisons** : ⚠️ **non vérifié dans cette story** — test end-to-end à exécuter par l'utilisateur après distribution du plugin (post-release). Le skill couvre les 4 combinaisons via la logique indépendante `product.mode` × `tickets.mode` documentée dans l'include `sources-config`.
- **Release automatique minor bump car ajout d'agent (géré par `sync.sh --minor`)** : ⚠️ **non applicable à S-0002** — pendant l'epic, `sync.sh --dist-only` auto-bumpe en patch (1.0.0 → 1.0.1) ce qui est acceptable. Le minor bump `1.0.x → 1.1.0` sera fait à la release en S-0008 via `./sync.sh --minor`. À tracer dans S-0008.
