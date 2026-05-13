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
