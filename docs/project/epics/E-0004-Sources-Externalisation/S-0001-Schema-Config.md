---
title: Schéma de config et include sources-config
date: 2026-04-21
status: TODO
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

- Fichiers créés / modifiés : `includes/sources-config.md` (nouveau), `.gitignore` (ajout entrée)
- Commandes de test : `./sync.sh` puis vérifier `plugins/kp-agents/skills/developer/SKILL.md` contient bien le contenu inliné
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
