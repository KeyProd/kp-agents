## Configuration des sources

La configuration des sources externes vit dans des **fichiers markdown** dans `docs/` à la racine du projet. Chaque fichier porte un **frontmatter YAML** sous la clé top-level `kp-agents:` qui contient la config machine-lisible. Absent ou clé absente = comportement par défaut (mode 100% local).

### Fichiers de configuration

| Fichier | Commit | Clés `kp-agents:` portées |
|---|---|---|
| `docs/git.md` | ✅ | `branch_pattern` |
| `docs/git.local.md` | ❌ gitignored | `auto_commit`, `auto_push` |
| `docs/project.md` | ✅ | `tickets.mode`, `tickets.mcp_server`, `tickets.project_key`, `tickets.mapping.*` |
| `docs/project.local.md` | ❌ gitignored | overrides `tickets.*` |
| `docs/documentation.md` | ✅ | `product.mode`, `product.access` |
| `docs/documentation.local.md` | ❌ gitignored | `product.path`, `global_doc.specs`, `global_doc.tech`, `global_doc.product_inputs` |

### Comportement au démarrage

1. Lire le frontmatter `kp-agents:` des fichiers `docs/*.md` listés ci-dessus si ils existent.
2. Pour chaque dimension activée en externe, vérifier les prérequis :
   - `product.mode: external` (dans `documentation.md`) → `product.path` (dans `documentation.local.md`) renseigné et accessible.
   - `global_doc.specs` ou `global_doc.tech` (dans `documentation.local.md`) → chemin accessible.
   - `tickets.mode: mcp` (dans `project.md`) → `mcp_server` et `project_key` renseignés.
3. Config incomplète ou chemin inaccessible → warn + proposer `/kp-agents:kp-setup` + continuer en mode local dégradé.

### Comment parser le frontmatter

Le frontmatter YAML est entre deux lignes `---` en tête de fichier. Exemple `docs/git.md` :

```markdown
---
kp-agents:
  branch_pattern: "feat/{slug}"
---

# Conventions Git du projet
...
```

Pour lire `branch_pattern`, lis le fichier `docs/git.md` et extrais la clé `kp-agents.branch_pattern` du frontmatter. **Ne jamais parser la prose du body** pour récupérer une config machine.

### Migration depuis `.kp-agents.yml` (v1.x)

Les anciens fichiers `.kp-agents.yml` et `.kp-agents.local.yml` ne sont **plus lus** depuis la v2.0.0. Si tu détectes leur présence à la racine du projet, signale-le à l'utilisateur et propose `/kp-agents:kp-setup` pour migrer automatiquement le contenu vers les nouveaux MD canoniques.

### Résolution de chemin pour la dimension `product`

Quand `product.mode: external` (dans `docs/documentation.md`) **et** `product.path` (dans `docs/documentation.local.md`) valide, les outputs suivants sont **redirigés vers `<product.path>/`** :

- `ideas/<theme>.md`
- `product.md`
- `features/<group>/product.md`
- `project/roadmap.md`

**Toujours écrits en local** : `docs/architect.md`, `docs/features/<group>/architect.md`, `docs/index.md`, toute doc technique. Les epics/stories suivent la dimension `tickets`.

Au premier write dans un sous-dossier externe, créer le sous-dossier à la volée (`mkdir -p`). Ne jamais demander confirmation pour ça.

Si un fichier existe à la fois localement et sur `<product.path>/<path>` : lire l'externe (source de vérité), écrire sur l'externe, warn une seule fois par session.

### Mode `product.access: read-only`

Quand `product.mode: external` **et** `product.access: read-only` : lire uniquement, ne jamais écrire — ni externe, ni fallback local. Rendre le contenu en chat :

> 🔒 **Mode produit read-only** — `<product.path>` en lecture seule. Je n'écris pas `<chemin relatif>`. Contenu ci-dessous pour copie manuelle. Pour autoriser l'écriture : `/kp-agents:kp-setup` → `product.access: read-write`.
>
> ```markdown
> <contenu rédigé>
> ```

Règles : refus absolu (pas de contournement). `access: read-only` ignoré si `mode: local`. Défaut `read-write` si omis. `product.access` et `tickets.mode` restent découplés.

### Écriture avec fallback local

Toute écriture sur source externe suit ce protocole :

1. Tenter l'écriture sur le chemin externe.
2. Échec → basculer sur `docs/` local en reproduisant **l'arborescence relative exacte** + warner explicitement.

> ⚠️ **Fallback d'écriture local** — impossible d'écrire sur `<chemin externe>` (raison : `<raison>`). Fichier écrit dans `<chemin local>`. `<conseil>`

| Cause | Signal | Conseil |
|---|---|---|
| Path inaccessible | chemin inexistant | Vérifier que OneDrive est monté. Sinon `/kp-agents:kp-setup` pour corriger le chemin. |
| Permission refusée | EACCES | Vérifier droits auprès du propriétaire. Config valide, pas besoin de `/kp-agents:kp-setup`. |
| Erreur transitoire | ENOSPC, EIO, timeout | Réessayer après vérification espace disque et connexion. |

Warn à chaque fallback (pas de dédoublonnage). Au démarrage : si `product.path` inaccessible dès le début → warn global + mode local dégradé pour toute la session.

### Documentation globale partagée (`global_doc`)

Répertoires partagés complémentaires à `docs/` — clés dans le frontmatter de `docs/documentation.local.md`. Les fichiers locaux **restent toujours écrits** — le global est un complément, jamais une substitution.

| Clé | Propriétaire écriture | Lecture | Règle pour les autres agents |
|---|---|---|---|
| `global_doc.specs` | `documentation` | tous | Écriture interdite → suggérer : « Veux-tu passer le relais à `/kp-agents:kp-documentation` ? » |
| `global_doc.tech` | `architect` | tous | Écriture interdite → suggérer : « Veux-tu passer le relais à `/kp-agents:kp-architect` ? » |
| `global_doc.product_inputs` | **personne** | tous | Jamais modifiable par un agent. Maintenu par un humain (PM). |

`global_doc.product_inputs` ≠ `product.path` : `.path` = destination des outputs de `product` ; `product_inputs` = source d'inputs du PM humain. Peuvent coexister et pointer différents dossiers.

**Lecture** : ne pas lire `global_doc` automatiquement au démarrage. Uniquement sur demande explicite ou quand le contexte global apporte clairement de la valeur — **suggérer avant de lire** :
> « Cette question semble bénéficier d'un contexte global. Veux-tu que je consulte `<chemin>` avant de répondre ? »

**Écriture** : uniquement par l'agent propriétaire, sur demande explicite. Processus : lire le fichier cible → proposer le contenu → attendre confirmation → écrire.

Si chemin `global_doc` inaccessible : warn une seule fois, poursuivre normalement.
> ⚠️ **Documentation globale inaccessible** — `<chemin>` (`global_doc.<clé>`) introuvable. Documentation locale utilisée. Vérifier le chemin ou `/kp-agents:kp-setup`.

### Redirection vers `/kp-agents:kp-setup`

Si config requise absente, incomplète ou incohérente, proposer `/kp-agents:kp-setup`. Suggestion, jamais un blocage.

### Mode `tickets.mode: mcp`

Configuration lue dans le frontmatter `kp-agents:` de `docs/project.md` (commité) avec overrides éventuels dans `docs/project.local.md` (gitignored).

Quand `tickets.mode: mcp` est actif, les epics et stories sont créées / lues / mises à jour via les outils MCP du serveur `mcp_server` dans le projet `project_key`. Aucun fichier `E-XXXX-*/readme.md` ni `S-XXXX-*.md` n'est créé localement pour ces tickets. L'utilisateur doit avoir configuré le serveur MCP correspondant dans ses `settings.json` Claude Code — l'agent ne configure pas le MCP lui-même.

#### Override local via `docs/project.local.md`

Un développeur peut surcharger `tickets.project_key` (et uniquement ce champ en pratique) dans son `docs/project.local.md` pour envoyer les tickets dans **son** projet de test sans toucher la config partagée :

```markdown
---
kp-agents:
  tickets:
    project_key: "TODO"   # override du KP partagé
---
```

Règle de merge : `docs/project.local.md` surcharge `docs/project.md` **champ par champ** (deep merge par dimension). Les champs absents du local héritent du partagé. Ne jamais override `mode` ou `mapping` en local sauf cas très ciblé — ça casserait la cohérence d'équipe.

#### Schéma `tickets.mapping`

Le mapping gouverne **comment** une story markdown est transcodée en ticket JIRA (et inversement). Sémantique champ par champ :

| Champ | Type | Défaut | Rôle |
|---|---|---|---|
| `summary_prefix` | string | `""` | Préfixe ajouté au début de chaque `summary` JIRA (ex: `[KP]`). |
| `issue_type_story` | string | `"Story"` | Nom du issue type pour les stories. |
| `issue_type_epic` | string | `"Epic"` | Nom du issue type pour les epics. |
| `status.TODO/IN_PROGRESS/REVIEW/DONE` | string | voir template | Noms **exacts** des statuts workflow JIRA. Variable par projet. |
| `labels` | array | `["kp-agents"]` | Labels ajoutés à tout ticket créé. |
| `label_patterns.story_id` | string | `"kp-story-{id}"` | Encode l'ID story en label JIRA (`S-0009` → `kp-story-S0009`). `{id}` sans tiret. |
| `label_patterns.epic_id` | string | `"kp-epic-{id}"` | Idem pour l'ID epic. |
| `label_patterns.author` | string | `"kp-author-{name}"` | Idem pour l'auteur. |
| `label_patterns.status` | string | `"kp-status-{value}"` | Label redondant avec workflow, utile pour JQL. |
| `custom_fields` | object | `{}` | Clé-valeur `customfield_XXXXX` injectés à la création. |
| `review_placement` | `description`\|`comment` | `"description"` | Où `review` écrit `## Review` : dans la description (append) ou commentaire JIRA. |

#### Pipeline d'écriture (create epic ou story)

Suivi par `product`, `developer`, `review` :

1. **Extraire le frontmatter** du markdown source : `story-id`, `epic-id`, `status`, `author`, `title`.
2. **Composer le `summary`** : `<mapping.summary_prefix><space><titre abrégé>` — 255 chars max, tronquer avec `…`.
3. **Composer la `description`** : body markdown uniquement, sans frontmatter YAML. Inclure `contentFormat: markdown` si l'outil le supporte.
4. **Composer les `labels`** : union de `mapping.labels` + patterns dérivés. Convention : pas de `-` dans `{id}` (`S0009`, pas `S-0009`).
5. **Composer le `parent`** (story) : clé JIRA de l'epic parente (`KP-42`).
6. **Appeler `createJiraIssue`** avec `projectKey`, `issueTypeName`, `summary`, `description`, `parent`, `additional_fields: { labels, ...custom_fields }`.
7. **Transitionner** si statut ≠ `TODO` initial : `getTransitionsForJiraIssue` → `transitionJiraIssue`.
8. **Afficher** la clé JIRA + URL au format standardisé.

#### Pipeline de lecture

1. `getJiraIssue` avec `responseContentFormat: markdown`.
2. Reconstruire frontmatter : `title` ← summary, `status` ← reverse-lookup `mapping.status`, `story-id`/`epic-id`/`author` ← labels inversés.
3. Afficher en markdown standard — non persisté sur disque.

#### Mise à jour d'une story existante

- **Body** : `editJiraIssue` avec `fields: { description: <nouveau markdown sans frontmatter> }`. Relire d'abord pour ne pas écraser du contenu hors agent.
- **Statut** : `transitionJiraIssue` vers `mapping.status[<cible>]`. Warn si transition indisponible.
- **Labels** : sur changement de statut, mettre à jour le label `kp-status-*` via `editJiraIssue`.

#### Affichage standardisé des liens JIRA

> **JIRA** : [`KP-42`](https://<site>.atlassian.net/browse/KP-42) — `<summary sans prefix>` *(status: <Status>)*

URL construite depuis `getAccessibleAtlassianResources` (une fois par session).

#### Gestion d'erreur MCP

Sur échec (timeout, 401, 403, 500, outil non chargé), proposer **3 options** :

> ⚠️ **Échec MCP JIRA** — `<opération>` sur `<issue>` a échoué (raison : `<raison courte>`).
> 1. **Réessayer** — je retente immédiatement.
> 2. **Bascule locale pour cette opération** — je crée/modifie en local `docs/project/epics/...`. Config reste `mode: mcp`.
> 3. **Annuler** — aucune modification.

| Cause | Signal | Conseil |
|---|---|---|
| MCP non chargé | tool not found | Vérifier MCP JIRA activé dans la session, ou `/kp-agents:kp-setup`. |
| Auth expirée | 401/403 | Reconnexion OAuth Atlassian nécessaire. |
| Champ requis manquant | 400 + `errors.fieldName` | Ajouter dans `tickets.mapping.custom_fields` via `/kp-agents:kp-setup`. |

#### Non-régression mode local

Si `tickets.mode: local` (ou absent), tout ce pipeline est **désactivé**. Agents créent/lisent `docs/project/epics/E-XXXX-*/readme.md` et `S-XXXX-*.md` comme d'habitude.

#### Agents concernés

| Agent | Opérations en `tickets.mode: mcp` |
|---|---|
| `product` | Crée epics et stories (statut initial `TODO`). Lit une epic/story existante. |
| `developer` | Transitionne `TODO → IN_PROGRESS` au démarrage, `IN_PROGRESS → REVIEW/DONE` en fin. Met à jour description (sections `## Implémentation` + `## Validation par critère`). |
| `review` | Transitionne `REVIEW → DONE` (GO) ou `REVIEW → IN_PROGRESS` (NO-GO). Ajoute `## Review` en description ou commentaire. |
| `brainstorm`, `architect`, `documentation`, `ux-ui`, `setup` | Non concernés. `documentation` maintient `docs/index.md` local, indépendant de `tickets.mode`. |

### Préférences Git

Configuration lue dans le frontmatter `kp-agents:` des fichiers `docs/git.md` (commité, politique projet) et `docs/git.local.md` (gitignored, préférences dev). **Non-régression absolue** : absent ou clé absente = comportement par défaut (confirmation avant commit/push, pas d'imposition de branche).

#### Clés portées par `docs/git.md` (politique projet)

| Clé | Valeurs | Défaut | Rôle |
|---|---|---|---|
| `branch_pattern` | string avec placeholders ou `""` | non renseigné | Template de nommage pour les branches feature. Placeholders : `{slug}` (kebab-case), `{ticket}` (clé JIRA ou `S-XXXX`), `{epic}`. Ex : `feat/{slug}`, `feature/KP-{ticket}-{slug}`. Vide ou absent = l'agent demande le nom. |

#### Clés portées par `docs/git.local.md` (préférences dev)

| Clé | Valeurs | Défaut | Rôle |
|---|---|---|---|
| `auto_commit` | `yes`/`no`/`ask` | `ask` | `yes` : commit sans demander. `no` : stage + annonce, jamais de commit. `ask` : confirmation avant (défaut). |
| `auto_push` | `yes`/`no`/`ask` | `no` | Même sémantique. Défaut `no` : push = décision utilisateur. |

#### Règles d'application

- `auto_commit: yes` ou `auto_push: yes` n'autorise **jamais** le skip de hooks, GPG, ou bypasses documentés dans `CLAUDE.md`.
- Échec silencieux interdit : si commit auto échoue, annoncer l'erreur et laisser la main.
- Préférences partielles : champ absent → défaut appliqué sur ce champ uniquement.
- Dimension indépendante de `product:` et `tickets:`.
- Si `docs/git.local.md` est absent : appliquer les défauts (`auto_commit: ask`, `auto_push: no`).
