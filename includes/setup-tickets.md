## Configuration de la dimension `tickets`

Cette dimension définit où vivent les epics et stories (local en `docs/project/epics/` ou JIRA via MCP).

### Questions à poser

1. **Mode** ? `local` (défaut) ou `mcp` (JIRA via serveur MCP).
2. Si `mcp` → **nom du serveur MCP** (tel que déclaré dans `settings.json` Claude Code) + **clé projet** (ex: `KP`).
3. Si `mcp` → **mapping projet-spécifique** (voir flow ci-dessous).

### Flow `tickets.mapping` (mode mcp uniquement)

Plutôt que de poser toutes les questions d'un bloc :

1. **Annoncer les défauts** (voir tableau ci-dessous) : préfixe vide, issue types `Story` + `Epic`, statuts `À faire / En cours / Examiner / Terminé(e)`, labels `[kp-agents]`.

2. **Valider automatiquement les défauts contre le projet réel** :
   - Appeler `getJiraProjectIssueTypesMetadata` pour vérifier que les issue types existent.
   - Appeler `getTransitionsForJiraIssue` sur un ticket factice (ou via `searchJiraIssuesUsingJql` pour en trouver un) pour lister les statuts.
   - Si un statut par défaut n'existe pas → proposer le plus proche détecté.

3. **Détecter les sous-tâches** : si `getJiraProjectIssueTypesMetadata` retourne des issue types avec `hierarchyLevel: -1` (sous-tâches), poser :
   > Votre projet utilise des sous-tâches (ex: Dev subtask, Code review). Les agents doivent-ils piloter les sous-tâches individuellement, ou uniquement le ticket parent Story ?
   - **Sous-tâches** → lancer le flow `subtask_workflow` (ci-dessous).
   - **Ticket parent uniquement** → continuer sans `subtask_workflow`.

4. **Customisations optionnelles** : demander si l'utilisateur veut un préfixe summary, des labels additionnels, des custom fields. Ne creuser que si oui.

5. **Si pas de mapping écrit** → les agents utilisent les défauts documentés dans `references/sources-config.md`. Pas d'erreur bloquante.

### Flow `subtask_workflow`

Présenter les sous-tâches détectées et demander le mapping agent par agent.

**Agent `developer`** :
- Quelle sous-tâche pilote-t-il ? (ex: `Dev subtask`) → `subtask_workflow.developer.issue_type`
- Statut au démarrage ? → `on_start`
- Statut à la fin d'implémentation ? → `on_done`
- Déclenche-t-il la review automatiquement ? (`true` / `false`) → `triggers_review`
- Si `triggers_review: true` → quelle sous-tâche de review ? → `review_issue_type` ; quel statut ? → `review_ready_status`

**Agent `review`** :
- Quelle sous-tâche pilote-t-il ? (ex: `Code review`) → `subtask_workflow.review.issue_type`
- Statut au démarrage ? → `on_start`
- Statut en cas de GO ? → `on_go`
- Statut en cas de NO-GO ? → `on_nogo`

**Ticket parent** :
- Le ticket Story parent est-il géré automatiquement par JIRA (rollup des sous-tâches) ? (`true` / `false`) → `parent_managed_by_jira`
- Si `true`, rappeler : les agents ne transitionnent **jamais** le ticket parent directement.

Questions groupées en 2-3 messages selon les réponses. Utiliser les statuts listés lors de la validation MCP comme propositions concrètes.

### Défauts suggérés pour `tickets.mapping`

| Champ | Défaut | Rôle |
|---|---|---|
| `summary_prefix` | `""` | Préfixe dans les titres JIRA |
| `issue_type_story` | `Story` | Nom JIRA du type Story |
| `issue_type_epic` | `Epic` | Nom JIRA du type Epic |
| `status.TODO` | `À faire` ou `To Do` selon locale | Statut initial workflow |
| `status.IN_PROGRESS` | `En cours` ou `In Progress` | Statut dev en cours |
| `status.REVIEW` | `Examiner` ou `In Review` | Statut review en cours |
| `status.DONE` | `Terminé(e)` ou `Done` | Statut final |
| `labels` | `[kp-agents]` | Labels systématiques |
| `label_patterns` | `{story_id: "kp-story-{id}", epic_id: "kp-epic-{id}", author: "kp-author-{name}", status: "kp-status-{value}"}` | Encodage frontmatter en labels |
| `custom_fields` | `{}` | À renseigner si Story Points / Sprint requis |
| `subtask_workflow` | absent | Présent uniquement si sous-tâches pilotées |
| `parent_managed_by_jira` | absent (≡ `false`) | `true` si JIRA gère le statut parent via rollup |

### Schéma `subtask_workflow` (dans `tickets.mapping`)

```yaml
subtask_workflow:
  developer:
    issue_type: "<nom>"
    on_start: "<statut>"
    on_done: "<statut>"
    triggers_review: true|false
    review_issue_type: "<nom>"          # si triggers_review: true
    review_ready_status: "<statut>"     # si triggers_review: true
  review:
    issue_type: "<nom>"
    on_start: "<statut>"
    on_go: "<statut>"
    on_nogo: "<statut>"
parent_managed_by_jira: true|false      # même niveau que subtask_workflow
```

### Cas limites

- **`tickets.mapping` partiel** → écrire uniquement les clés customisées (YAML clairsemé). Les clés absentes héritent des défauts. Éviter de re-écrire les défauts verbatim — bruit visuel dans un fichier partagé en équipe.
- **Override local de `tickets.project_key`** → si l'utilisateur veut utiliser un projet JIRA personnel pour ses tests, écrire uniquement `tickets.project_key: <autre>` dans `.kp-agents.local.yml`. Les autres champs (`mcp_server`, `mapping`) héritent du partagé. Ne jamais dupliquer tout le bloc `tickets` en local.
- **`subtask_workflow` sans `parent_managed_by_jira`** → si pas de réponse, ne pas écrire le champ (≡ `false`). Prévenir que ce comportement peut conflicte avec un rollup JIRA automatique.
- **`subtask_workflow` partiel** → écrire uniquement les clés fournies. Si seul `developer` configuré sans `review`, les agents `review` opèrent en mode dégradé (ticket parent uniquement).
- **Sous-tâches détectées mais pilotage parent choisi** → ne pas écrire `subtask_workflow`. Consigner dans `docs/kp-agents-config.md` que le projet a des sous-tâches mais que les agents pilotent uniquement le ticket parent.
- **Validation MCP impossible** (MCP server non chargé au moment du setup) → consigner les défauts tels quels, warner que la validation effective aura lieu à la première opération ticket.
