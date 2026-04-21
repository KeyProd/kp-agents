---
title: Schéma de config et include sources-config
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0001
epic-id: E-0004
---

# S-0001 - Schéma de config et include sources-config

## Résumé

Poser les fondations de l'externalisation : définir le format des fichiers de configuration `.kp-agents.yml` et `.kp-agents.local.yml`, créer l'include partagé `sources-config` qui sera injecté dans tous les agents, et vérifier les hypothèses techniques (permissions Claude Code hors `cwd`, taille des skills).

## User Story

En tant que mainteneur du projet `kp-agents`, je veux un schéma de configuration stable et un mécanisme d'inclusion partagé, afin que chaque agent applique la même logique de résolution de sources sans duplication.

## Contexte

- Première story de l'epic E-0004, fondations techniques pour toutes les suivantes.
- Deux fichiers de config distincts : `.kp-agents.yml` (commité, politique) et `.kp-agents.local.yml` (gitignoré, chemins machine).
- L'include sera résolu par `sync.sh` via la syntaxe `{{include:sources-config}}`.

## Règles métier

- Un projet sans `.kp-agents.yml` → comportement 100% local (par défaut, non-régression).
- `.kp-agents.local.yml` **doit** être gitignoré (entrée ajoutée au `.gitignore` du projet lors du setup).
- Schéma `.kp-agents.yml` :
  ```yaml
  product:
    mode: local | external       # default: local
  tickets:
    mode: local | mcp            # default: local
    mcp_server: <nom>            # requis si mode: mcp
    project_key: <clé>           # requis si mode: mcp (ex: KP)
  ```
- Schéma `.kp-agents.local.yml` :
  ```yaml
  product:
    path: <chemin absolu>        # requis si product.mode: external
  ```

## Scénarios

### Nominal
- Étant donné un projet sans aucun fichier de config
- Quand un agent démarre
- Alors il applique le comportement local (actuel) sans prompter l'utilisateur.

### Alternatif
- Étant donné un projet avec `.kp-agents.yml` déclarant `product.mode: external` mais sans `.kp-agents.local.yml`
- Quand un agent démarre
- Alors il détecte la config incomplète et propose `/kp-agents:setup` à l'utilisateur (ne bloque pas, suggestion).

### Erreur / refus
- Étant donné un `.kp-agents.yml` mal formé (YAML invalide, clés inconnues)
- Quand un agent tente de le lire
- Alors il warn explicitement l'utilisateur, liste les erreurs détectées, et propose `/kp-agents:setup` pour corriger.

## Cas limites

- [ ] Fichier `.kp-agents.yml` vide (0 octet) → traité comme absent
- [ ] Fichier présent mais tous les modes à `local` → équivalent à absent
- [ ] Chemin `product.path` pointant vers un dossier inexistant → warn, fallback local
- [ ] Caractères spéciaux / espaces dans le chemin OneDrive (`Library/CloudStorage/OneDrive - Entity Name/`)
- [ ] Exécution sur Windows : chemin avec backslashes (à vérifier — hypothèse : YAML gère les deux)

## Critères d'acceptation

- [ ] Fichier `includes/sources-config.md` créé, contenant la logique de lecture + résolution + fallback utilisable par tout agent
- [ ] Schéma `.kp-agents.yml` et `.kp-agents.local.yml` documentés dans le corps de l'include (exemples complets)
- [ ] Logique de lecture gère les 3 états : absent, présent+complet, présent+incomplet
- [ ] Logique de chemin : si `product.mode: external` et `product.path` résolu → retourne le chemin externe ; sinon retourne `docs/` local
- [ ] Logique de fallback write documentée : try external → catch permission/not-found → write local + warn utilisateur avec chemin du fichier écrit
- [ ] Entrée `.kp-agents.local.yml` ajoutée au `.gitignore` du projet `kp-agents` (dogfood)
- [ ] Mesure H3 documentée : taille de `agents/developer.md` avant/après ajout du `{{include:sources-config}}` (chiffre dans la story en section Implémentation)
- [ ] Mesure H2 documentée : test manuel Claude Code lecture/écriture dans un dossier hors `cwd` (ex: `/tmp/test-external/`) — résultat documenté
- [ ] `./sync.sh` continue de produire les 3 cibles sans erreur après ajout de l'include

## Dépendances

- Aucune (story de fondation). Bloquante pour S-0002, S-0003, S-0004.

## Notes techniques

- L'include `sources-config.md` suit la convention des includes existants dans `includes/` (pas de frontmatter propre, injecté en texte brut).
- La logique de lecture YAML est **déléguée à l'agent** (lecture via `Read`, parsing mental). Pas de dépendance runtime à un parseur YAML.
- La résolution du chemin doit gérer les chemins relatifs (rare) et absolus (cas standard OneDrive).
- L'include doit être **concis** : chaque agent l'inline, donc chaque ligne coûte en tokens × 8 agents.

## Instrumentation / mesure

- Taille de `agents/developer.md` avant/après, en lignes et en caractères (critère d'acceptation)
- Temps de lecture des 2 fichiers de config au démarrage d'un agent (attendu : négligeable)

## Questions ouvertes

- Faut-il prévoir un mode `strict` où un problème de config bloque au lieu de dégrader ? → **Décision V1 : non**, dégradation gracieuse systématique. Revisiter si feedback utilisateur.

## Implémentation

### Fichiers créés / modifiés

- **`includes/sources-config.md`** (créé) — 56 lignes / 3 227 caractères. Couvre : schémas YAML des 2 fichiers de config, comportement au démarrage, résolution de chemin `product`, mode `tickets.mode: mcp`, fallback write local, redirection vers `/kp-agents:setup`.
- **`.gitignore`** (modifié) — ajout de l'entrée `.kp-agents.local.yml` avec commentaire référençant l'epic.

### Mesures expérimentales

**H2 — Permissions Claude Code hors `cwd`** : ✅ Validé. Test manuel réalisé le 2026-04-21 :
- Création de `/tmp/kp-agents-h2-test/` via Bash (hors du `cwd` `/Users/vincent/GIT/kp-agents`)
- Écriture d'un fichier YAML via outil Write → **OK**
- Lecture du fichier via outil Read → **OK, contenu intact**
- Nettoyage effectué
- **Conclusion** : les agents Claude Code peuvent lire/écrire dans un chemin absolu arbitraire (comme un chemin OneDrive). Le sandbox de Claude Code n'impose pas de contrainte ici.

**H3 — Taille de `developer.md` après ajout de l'include** (mesure théorique) :

| Fichier | Lignes | Caractères |
|---|---|---|
| `agents/developer.md` (baseline) | 241 | 14 745 |
| `includes/sources-config.md` | 56 | 3 227 |
| **`agents/developer.md` après `{{include:sources-config}}`** (théorique) | 242 source / 297 après résolution | 14 773 source / 17 972 après résolution |
| `plugins/kp-agents/skills/developer/SKILL.md` (baseline, includes déjà résolus) | 332 | 21 224 |
| **`plugins/kp-agents/skills/developer/SKILL.md`** (théorique après S-0003) | **388** | **24 451** |

- **Conclusion** : l'include ajoute environ **17%** à la taille du SKILL.md final de l'agent le plus long (`developer`). Pas de limite technique Claude Code identifiée à ce niveau de taille. Acceptable pour V1.
- **Note** : mesure théorique (ajout de 56 lignes × 1 ligne de directive). La mesure empirique sera refaite en S-0003 lors de l'intégration réelle.

### Dérive détectée pendant l'implémentation (hors scope S-0001)

`./sync.sh --dist-only` a tenté un auto-bump `1.0.0 → 1.0.1` alors que ma story n'a touché aucun agent (include créé mais non référencé). Cause : dérive pré-existante entre le `_contentHash` stocké dans `plugins/kp-agents/.claude-plugin/plugin.json` (`33a7460…`) et le hash recalculé sur les SKILL.md actuels (`2520542…`), sans diff de contenu détectable (`git diff plugins/kp-agents/skills/` vide).

Revert effectué sur `plugin.json` pour éviter un bump involontaire dans cette story. **Écart documentaire à signaler** : la dérive sera corrigée naturellement en S-0003 lors du vrai bump patch dû à l'ajout de l'include dans les agents, mais mérite investigation pour identifier comment elle a été introduite (commit manuel sans re-sync probable).

### Commandes de test

- Test H2 : `mkdir -p /tmp/kp-agents-h2-test && echo 'product: { path: /tmp/test }' > /tmp/kp-agents-h2-test/test.yml && cat /tmp/kp-agents-h2-test/test.yml`
- Vérif non-régression sync : `./sync.sh --dist-only` puis `git diff plugins/kp-agents/skills/` (doit être vide tant que l'include n'est pas référencé dans un agent)
- Vérif gitignore : `echo "path: /fake" > .kp-agents.local.yml && git status` (le fichier ne doit pas apparaître comme untracked)

### Notes de review

- L'include est **volontairement concis** (56 lignes) car il sera inliné dans 8 agents. Toute expansion doit être pesée.
- Le contenu est 100% descriptif (prose markdown documentant le comportement attendu) — aucun code exécutable. Les agents appliqueront la logique en lisant les fichiers `.kp-agents.yml` / `.kp-agents.local.yml` comme texte via `Read`.
- L'include n'est référencé par **aucun** agent dans cette story (c'est le périmètre de S-0003). Il peut donc sembler « orphelin » — c'est voulu.
- Vérifier que la dérive de hash plugin.json (§ précédent) ne crée pas de confusion à la prochaine story qui modifiera un agent.

## Validation par critère

- **Fichier `includes/sources-config.md` créé, contenant la logique de lecture + résolution + fallback utilisable par tout agent** : ✅ créé à [includes/sources-config.md](includes/sources-config.md) (56 lignes, couvre les 6 sections attendues : config files, démarrage, résolution product, mode tickets MCP, fallback write, redirection setup).
- **Schéma `.kp-agents.yml` et `.kp-agents.local.yml` documentés dans le corps de l'include (exemples complets)** : ✅ deux blocs YAML avec commentaires inline précisant les valeurs par défaut et les prérequis par mode.
- **Logique de lecture gère les 3 états : absent, présent+complet, présent+incomplet** : ✅ documentée dans la section « Comportement au démarrage » points 1-3.
- **Logique de chemin : si `product.mode: external` et `product.path` résolu → retourne le chemin externe ; sinon retourne `docs/` local** : ✅ section « Résolution de chemin pour la dimension `product` » liste explicitement les fichiers redirigés et ceux toujours locaux.
- **Logique de fallback write documentée : try external → catch permission/not-found → write local + warn utilisateur avec chemin du fichier écrit** : ✅ section « Écriture avec fallback local » décrit le protocole en 2 étapes avec warn explicite cité.
- **Entrée `.kp-agents.local.yml` ajoutée au `.gitignore` du projet `kp-agents` (dogfood)** : ✅ ligne ajoutée au [.gitignore](.gitignore) avec commentaire référençant l'epic. Test : un fichier local créé à la racine n'apparaît pas dans `git status`.
- **Mesure H3 documentée** : ✅ tableau ci-dessus (baseline 241 / 332 lignes → théorique 242 / 388 lignes après S-0003). Limite : mesure théorique, à refaire empiriquement en S-0003.
- **Mesure H2 documentée** : ✅ test manuel `/tmp/kp-agents-h2-test/` réussi. Limite : testé sur macOS uniquement, comportement Windows à valider en S-0004.
- **`./sync.sh` continue de produire les 3 cibles sans erreur après ajout de l'include** : ✅ `./sync.sh --dist-only` exécuté, 7 agents syncés sans erreur. `git diff plugins/kp-agents/skills/` vide (aucun SKILL.md modifié, l'include n'étant référencé nulle part). Écart noté : auto-bump involontaire dû à dérive hash pré-existante, reverté.

## Review

**Date**: 2026-04-21
**Verdict**: GO
**Reviewer**: review-agent

### Résumé

Fondations propres et conformes à l'epic E-0004. Les 9 critères d'acceptation sont documentés avec preuves observables. L'include `sources-config.md` est concis (56 lignes / 3 227 caractères) et correctement scopé pour injection ultérieure dans 8 agents. Non-régression vérifiée (diff SKILL.md vide après `sync.sh --dist-only`), gitignore vérifié effectif via `git check-ignore -v`, H2 empiriquement validée. Une incohérence de classement `epics/readme.md` entre l'include et le readme d'epic mérite clarification avant S-0004 — signalée en P1.

### Points bloquants

Aucun.

### Recommandations d'amélioration

| # | Catégorie | Priorité | Description | Exemple |
|---|-----------|----------|-------------|---------|
| 1 | maintenabilité | P1 | Incohérence de périmètre : l'epic readme (L71-72) classe **tous** les fichiers de `docs/project/epics/` dans la dimension `tickets`. L'include (L38-41) classe `epics/E-XXXX-*/readme.md` dans `product` et seulement les `S-XXXX-*.md` dans `tickets`. L'include adopte une position plus fine (readme d'epic = doc produit, stories = tickets), défendable mais divergente. À trancher avant S-0004 pour éviter une ambiguïté à l'implémentation. | Aligner soit l'include sur le readme d'epic (tout epics/ = tickets), soit le readme d'epic sur l'include (split readme/stories). Ma recommandation : garder la position de l'include (plus sémantiquement juste) et corriger le readme d'epic L71-72. |
| 2 | maintenabilité | P1 | Dérive pré-existante `_contentHash` dans `plugins/kp-agents/.claude-plugin/plugin.json` (hash stocké ≠ hash recalculé sur des SKILL.md identiques). Reproductible à chaque `./sync.sh --dist-only` tant que la dérive n'est pas corrigée. **Non causée par S-0001** mais masque la vérification de non-régression pour les stories suivantes. À investiguer avant S-0003 (qui modifiera réellement les agents). | Option A : un `./sync.sh --dist-only` + commit du `plugin.json` pour resynchroniser le hash au contenu actuel avant S-0003. Option B : logger la cause (commit manuel sans re-sync) via `git log -- plugins/kp-agents/.claude-plugin/plugin.json`. |
| 3 | refacto | P2 | Le schéma `.kp-agents.local.yml` ne contient aujourd'hui qu'un seul champ (`product.path`). Anticiper la structure pour S-0006 (overrides locaux tickets) ou S-0007 (overrides Git machine) n'est pas nécessaire V1, mais le format actuel devrait explicitement documenter son extensibilité pour éviter des breaking changes de schéma. | Ajouter un commentaire inline dans l'include L19 : `# Schéma extensible : d'autres clés machine-spécifiques pourront être ajoutées (overrides MCP, chemins Git locaux…)`. |
| 4 | maintenabilité | P2 | H2 validée sur macOS uniquement. La compatibilité Windows est documentée comme « à vérifier en S-0004 » mais la section Périmètre de l'epic (L87) cite explicitement Windows comme inconnu. Prévoir un test équivalent (`mkdir` sur un chemin Windows avec espaces, type `C:\Users\<user>\OneDrive - Entity\`) et un cas de test CI si possible. | Intégrer dans S-0004 un checklist « H2-Windows validé » bloquant pour la clôture de l'epic. |
| 5 | optimisation | P3 | Mesure H3 reste théorique (addition de lignes, pas d'injection réelle dans un SKILL.md). Le chiffre 17% d'augmentation est calculé à partir de comptages bruts ; la mesure empirique en S-0003 pourrait révéler une variation liée au rendu des includes (blocs YAML avec indentation, etc.). | Refaire la mesure empirique (`wc -l plugins/kp-agents/skills/developer/SKILL.md`) après la première injection réelle en S-0003, et remonter si > 20%. |
| 6 | maintenabilité | P3 | L'include est **orphelin** (aucune référence dans `agents/*.md`) tant que S-0003 n'est pas faite. Risque faible de confusion pour un contributeur externe qui verrait `includes/sources-config.md` sans usage. | Acceptable tel quel (convention de l'epic, périmètre volontaire de S-0001). Alternativement, un commentaire en tête d'include : `<!-- Include consommé par les agents via {{include:sources-config}} — intégration en S-0003 -->`. |

### Tests exécutés

- [x] Vérification fichier include : `wc -l includes/sources-config.md` → 56 lignes (conforme à l'annonce story)
- [x] Vérification fichier include : `wc -c includes/sources-config.md` → 3 227 caractères (conforme)
- [x] Vérification gitignore effectif : `git check-ignore -v .kp-agents.local.yml` → `.gitignore:11:.kp-agents.local.yml` (match explicite)
- [x] Non-régression sync : `./sync.sh --dist-only` exécuté, 7 agents syncés sans erreur. `git diff plugins/kp-agents/skills/` vide après revert du bump.
- [x] Revert propre du bump involontaire : `git checkout -- plugins/kp-agents/.claude-plugin/plugin.json` + `git status --short` → seuls `.gitignore`, `S-0001-Schema-Config.md` (modifiés) et `includes/sources-config.md` (nouveau) apparaissent
- [x] Reproductibilité de la dérive hash : confirmée (auto-bump 1.0.0 → 1.0.1 réapparu sans diff SKILL.md)
- [x] Cohérence include ↔ epic : ✅ alignement sur fallback, redirection setup, dimensions découplées, schémas YAML. ⚠️ Divergence sur classement `epics/readme.md` (cf. recommandation P1 #1)
- [ ] H2 Windows : **non exécutable** (poste macOS, pas de VM disponible) — déferré à S-0004 conformément au périmètre
- [ ] H3 empirique : **non exécutable** (l'include n'est pas encore référencé) — déferré à S-0003 conformément au périmètre

