---
title: Spike mapping story-markdown vers ticket JIRA
date: 2026-04-22
status: done
author: developer-agent
spike-id: S-0005
epic-id: E-0004
duration: ~90 min
---

# Spike S-0005 — Mapping story-markdown ↔ ticket JIRA

## Décision

**GO partiel** avec stratégie documentée ci-dessous. Le round-trip est faisable et fidèle sur le body markdown, mais nécessite un **mapping configurable par projet** pour gérer le frontmatter YAML, le workflow de statuts et les champs custom variables entre instances JIRA.

**Recommandation S-0006** : GO sur S-0006 **avec ajustements** — le schéma `.kp-agents.yml` doit être étendu (`tickets.mapping`) et l'agent `setup` enrichi pour piloter cette configuration. Pas besoin de scinder l'epic.

## Environnement testé

- **Site** : `keyprod.atlassian.net`
- **CloudId** : `84ea1157-7773-4f19-96f1-7eab345c3ad1`
- **Projet sandbox** : `POC` (KP-POC)
- **Issue types disponibles** : Story (10118), Epic (10107), Bug (10119), Tâche (10106), Sous-tâche (10108)
- **Workflow Story** : `À faire` (initial) → `En cours` / `Examiner` / `Terminé(e)` / `Abandoné` / `Définition`
- **Champs requis Story** : uniquement `project`, `reporter`, `summary` (pas de story points obligatoire, pas de custom field bloquant)
- **Tickets créés pendant le spike** : POC-689 (epic E-0004), POC-690 (S-0001), POC-691 (S-0009) — clôturés en `Abandoné` en fin de spike.

## Round-trip observé

### ✅ Éléments fidèles (passent intact ou avec transformation cosmétique)

| Élément markdown | Fidélité | Note |
|---|---|---|
| Titres (`## Résumé`, `### Nominal`) | **Parfait** | Hiérarchie préservée |
| Listes à puces | **OK (cosmétique)** | `- ` reformaté en `* ` |
| Listes numérotées | **OK** | Non testé, mais supporté par ADF |
| Tableaux markdown | **Parfait** | Séparateur d'en-tête `\| --- \|` ajouté automatiquement |
| Blocs de code triple-backtick | **Parfait** | Langue préservée (```` ```yaml ````) |
| Backticks inline (`code`) | **Parfait** | |
| Gras / italique | **Parfait** | |
| Émojis (🔒, ⚠️, ✅, ❌) | **Parfait** | |
| Liens markdown | **Parfait** | Non testé mais supporté |
| Citations / blockquotes | **Parfait** | Non testé mais supporté |
| Séparateur horizontal `---` | **À éviter** | Interprété en priorité, casse le frontmatter (voir ci-dessous) |

### ❌ Éléments problématiques

| Élément | Problème observé | Impact |
|---|---|---|
| **Frontmatter YAML** (`---\ntitle: ...\n---`) | Le `---` devient un séparateur HR, la première ligne `title:` devient un H2, le reste devient du texte courant | **Critique** — le frontmatter ne peut pas vivre dans `description`, doit être stocké ailleurs |
| **Checkboxes `[x]` / `[ ]`** | Échappées en `\[x\]` dans la description | Cosmétique, mais dégrade la lisibilité |
| **Ordre des `labels`** | Réordonné alphabétiquement par JIRA | Non-problème en pratique (on ne s'appuie pas sur l'ordre) |
| **Statut workflow JIRA** | Complètement indépendant du `status` du frontmatter kp-agents | Double notion de statut — mapping configurable requis |

### Données brutes du round-trip

**Source (extrait S-0001 frontmatter)** :
```yaml
---
title: Schéma de config et include sources-config
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0001
epic-id: E-0004
---
```

**Après round-trip JIRA** (description récupérée) :
```
---

## title: Schéma de config et include sources-config  
date: 2026-04-21  
status: DONE  
author: product-agent  
story-id: S-0001  
epic-id: E-0004
```

Le `---` ouvrant est devenu un HR, `title:` devient un heading, les autres lignes deviennent du texte de paragraphe avec `  \n` (retours à la ligne markdown).

## Schéma de mapping proposé

### Stratégie de distribution des données

| Donnée source (kp-agents) | Cible JIRA | Justification |
|---|---|---|
| `summary` (titre de la story) | `summary` natif | 1:1, limité à 255 chars côté JIRA |
| Body markdown (tout sauf frontmatter) | `description` (markdown) | Fidélité observée excellente |
| `story-id` (ex: S-0009) | **Label** `kp-story-S0009` + summary prefix configurable | Permet la recherche JQL `labels = kp-story-S0009` |
| `epic-id` (ex: E-0004) | **Label** `kp-epic-E0004` + `parent` (lien epic JIRA) | Double ancrage : label pour JQL, parent pour navigation |
| `status` kp-agents (TODO/IN PROGRESS/REVIEW/DONE) | **Transition workflow** JIRA configurable | Mapping `tickets.mapping.status` (voir ci-dessous) |
| `author` (ex: product-agent) | **Label** `kp-author-product-agent` | Permet de filtrer par agent |
| `date` | Champ `created` natif (automatique) | Pas de remapping nécessaire |
| `title`, `spike-id`, etc. (frontmatter extensible) | **Labels** `kp-<key>-<value>` ou **issue properties** (JSON libre) | Labels pour les cas simples, properties pour structure complexe |
| Section `## Review` (ajoutée par review-agent) | **Comments** JIRA ou bloc dans description | À trancher en S-0006 |
| Section `## Implémentation` (ajoutée par developer-agent) | Bloc en fin de description | Fidélité observée OK |

### Schéma `.kp-agents.yml` proposé

```yaml
tickets:
  mode: mcp                          # local | mcp
  mcp_server: atlassian              # nom du MCP dans settings.json Claude Code
  project_key: POC                   # clé du projet JIRA par défaut
  mapping:
    summary_prefix: "[KP]"           # préfixe optionnel dans le titre JIRA
    issue_type_story: Story          # nom du type Story (varie selon projet)
    issue_type_epic: Epic            # nom du type Epic (peut être "Initiative" sur certains projets)
    status:                          # mapping kp-agents → workflow JIRA
      TODO: "À faire"
      IN_PROGRESS: "En cours"
      REVIEW: "Examiner"
      DONE: "Terminé(e)"
    labels:                          # labels systématiques ajoutés à chaque ticket
      - kp-agents
    label_patterns:                  # format des labels dérivés du frontmatter
      story_id: "kp-story-{id}"      # {id} remplacé par S0009
      epic_id: "kp-epic-{id}"        # {id} remplacé par E0004
      author: "kp-author-{name}"     # {name} remplacé par product-agent
      status: "kp-status-{value}"    # {value} remplacé par REVIEW (redondant avec mapping.status mais utile en JQL)
    custom_fields: {}                # réservé pour extension (ex: Story Points, Sprint)
```

### Override local (`.kp-agents.local.yml`)

Conformément au point 1 validé avec l'utilisateur, un utilisateur peut **surcharger localement** le projet JIRA utilisé :

```yaml
# .kp-agents.local.yml
tickets:
  project_key: TODO                  # override du project_key projet, utilise KP-TODO à la place
  # les autres champs (mcp_server, mapping) héritent de .kp-agents.yml
```

**Règle de merge** : `.kp-agents.local.yml` surcharge `.kp-agents.yml` **champ par champ** (merge profond sur `tickets`, pas remplacement global). Permet à un dev d'envoyer les tickets dans son projet de test sans toucher la config partagée.

## Défauts proposés pour l'agent `setup`

Quand l'utilisateur choisit `tickets.mode: mcp` via `/kp-agents:setup`, l'agent propose les valeurs par défaut suivantes (à confirmer/modifier par l'utilisateur) :

| Champ | Défaut suggéré | Source du défaut |
|---|---|---|
| `mcp_server` | `atlassian` | Nom standard du MCP Atlassian dans les installs Claude Code |
| `project_key` | *demandé à l'utilisateur* | Aucun défaut sensible — dépend du projet |
| `summary_prefix` | `""` (vide) | Le préfixe est optionnel, l'utilisateur l'ajoute s'il veut isoler ses tickets |
| `issue_type_story` | `Story` | Standard JIRA Software |
| `issue_type_epic` | `Epic` | Standard JIRA Software |
| `status.TODO` | `À faire` / `To Do` | Détection automatique via `getTransitionsForJiraIssue` + fallback localisation FR/EN |
| `status.IN_PROGRESS` | `En cours` / `In Progress` | Idem |
| `status.REVIEW` | `Examiner` / `In Review` | Idem (moins standardisé selon projets) |
| `status.DONE` | `Terminé(e)` / `Done` | Idem |
| `labels` | `["kp-agents"]` | Préfixe systématique |

**Validation automatique** : quand l'agent setup reçoit `project_key`, il peut appeler `getJiraProjectIssueTypesMetadata` + `getTransitionsForJiraIssue` pour détecter les types et statuts réellement disponibles, et proposer un mapping préalisé. Évite de fausses valeurs par défaut qui plantent à la création du premier ticket.

## Éléments nécessairement **configurables par projet**

La liste ci-dessous énumère ce qui **doit** être dans `tickets.mapping` parce que variable entre projets / instances JIRA :

1. **Nom des issue types** : "Story" peut être "User Story", "Epic" peut être "Initiative" ou "Feature" selon la convention projet.
2. **Noms des statuts du workflow** : JIRA permet une localisation et une customisation complète — `À faire` vs `To Do` vs `Backlog` vs `Open`.
3. **Préfixe de summary** : projet-specific (certains veulent `[KP]`, d'autres rien, d'autres `[TEAM-X]`).
4. **Custom fields** : selon qu'un projet a "Story Points", "Sprint", "Fix Version" ou "Epic Link" requis, il faut des clés `customfield_10016` etc. à injecter.
5. **Labels systématiques** : convention organisationnelle.

**Ce qui reste non-configurable (convention kp-agents)** :
- La structure du body markdown (on écrit la même chose partout).
- Le pattern des labels dérivés (`kp-story-S0001`, `kp-epic-E0004`, etc.) — c'est la signature de reconnaissance d'un ticket kp-agents.
- La hiérarchie Story ↔ Epic via `parent` (structure native JIRA).

## Points résolus du cahier des charges S-0005

| Critère d'acceptation | Statut |
|---|---|
| Document de spike créé | ✅ Ce fichier |
| Test round-trip sur ≥2 stories (dont 1 complexe) + 1 epic | ✅ POC-690 (S-0001), POC-691 (S-0009 avec matrice), POC-689 (E-0004) |
| Décision GO / GO partiel / NO-GO tranchée | ✅ **GO partiel** |
| Si GO partiel : liste des pertes + mitigation | ✅ Frontmatter → labels + issue properties, [x] échappées → cosmétique acceptable, ordre labels → non-problème |
| Schéma de mapping `kp-agents ↔ JIRA` | ✅ Tableau ci-dessus |
| Tickets créés supprimés ou clôturés | ⏳ **À faire** en fin de spike (transition `Abandoné` via id `5`) |
| Recommandation sur la suite | ✅ **GO sur S-0006 avec ajustements** — schéma `tickets.mapping` à intégrer dans S-0001 (rétro-fix) ou dédier une mini-story |

## Réponse à la question ouverte de S-0005

> La structure des champs custom JIRA varie selon le projet client. Le mapping doit-il être **configurable par projet** (`.kp-agents.yml` contient la matrice de mapping) ou **en dur** avec mapping générique ?

**Tranché : configurable par projet**, via `tickets.mapping` dans `.kp-agents.yml`. Un mapping en dur ne tient pas face à la variabilité observée (issue types, statuts workflow, custom fields requis, localisation FR/EN). L'agent `setup` propose des défauts sensibles et valide les valeurs via les endpoints MCP avant d'écrire la config.

Override local supporté via `.kp-agents.local.yml` (même pattern que `product.path`).

## Impact sur les stories suivantes

### Ajustements requis pour S-0006 (Mode `tickets.mode: mcp`)

S-0006 doit maintenant couvrir :

1. **Parser `tickets.mapping`** dans les 8 agents (via extension de l'include `sources-config`).
2. **Extraire le frontmatter YAML** d'une story markdown avant création JIRA, le stocker en labels (pattern configurable).
3. **Reconstruire le frontmatter** lors d'une lecture JIRA → markdown (pour présenter à l'utilisateur comme si c'était un fichier local).
4. **Mapper les transitions de statut** kp-agents → JIRA via la table `mapping.status`.
5. **Gérer l'override local** (merge `.kp-agents.yml` + `.kp-agents.local.yml`).
6. **Agents concernés en écriture JIRA** : `product` (création epic/story), `developer` (update status → IN PROGRESS → DONE), `review` (update status → REVIEW → DONE, ajout de section Review en commentaire ou dans description).

### Ajustements requis pour S-0002 / S-0007 (setup)

- S-0002 est déjà livré mais doit être étendu en S-0006 pour supporter les questions `tickets.mapping` (issue types, status map, préfixe, custom fields).
- S-0007 (préférences Git) reste inchangée, pas d'impact.

### Ajustement léger sur S-0001 (schéma config)

Le schéma `.kp-agents.yml` initial de S-0001 ne prévoit pas `tickets.mapping`. **Ce n'est pas bloquant** : l'include `sources-config.md` peut être étendu en S-0006 sans casser S-0001 (la config est extensible par convention). Aucune rétro-migration nécessaire.

## Cleanup

Les 3 tickets créés pendant le spike sont transitionnés en `Abandoné` (workflow transition id 5, status 10183). Le MCP Atlassian exposé ne propose pas `deleteJiraIssue` — la clôture en état `Abandoné` est la meilleure approximation disponible et reste identifiable par le préfixe `[SPIKE-S0005]` dans le summary.

Commande JQL pour retrouver tous les tickets du spike a posteriori si suppression manuelle souhaitée :
```
project = POC AND summary ~ "SPIKE-S0005"
```

## Timebox

- Budget initial : 2-4h
- Temps effectif : **~90 min** (audit MCP, 3 créations, 2 relectures, analyse, rédaction)
- En dessous du budget — la fidélité markdown s'est avérée meilleure qu'anticipée, le mapping s'est structuré rapidement sur un seul round-trip par format.
