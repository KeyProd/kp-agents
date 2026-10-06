---
kp-agents:
  tickets:
    mode: local
---

# Suivi projet

> Fichier commité — politique de suivi projet partagée par l'équipe. Les overrides personnels (ex: projet JIRA de test) vont dans `project.local.md`.

## Configuration machine-lisible

Le frontmatter porte la politique tickets. Schéma complet :

```yaml
kp-agents:
  tickets:
    mode: local | mcp                    # défaut: local
    mcp_server: "<nom>"                  # si mode: mcp — nom serveur MCP dans settings.json
    project_key: "<KEY>"                 # si mode: mcp — clé projet JIRA (ex: "KP")
    mapping:                             # si mode: mcp — optionnel, défauts documentés
      summary_prefix: ""
      issue_type_story: "Story"
      issue_type_epic: "Epic"
      status:
        TODO: "À faire"
        IN_PROGRESS: "En cours"
        REVIEW: "Examiner"
        DONE: "Terminé(e)"
      labels: ["kp-agents"]
      label_patterns:
        story_id: "kp-story-{id}"
        epic_id: "kp-epic-{id}"
        author: "kp-author-{name}"
        status: "kp-status-{value}"
      custom_fields: {}
      review_placement: description | comment
      subtask_workflow:                  # si sous-tâches pilotées individuellement
        developer:
          issue_type: "<nom>"
          on_start: "<statut>"
          on_done: "<statut>"
          triggers_review: true | false
          review_issue_type: "<nom>"
          review_ready_status: "<statut>"
        review:
          issue_type: "<nom>"
          on_start: "<statut>"
          on_go: "<statut>"
          on_nogo: "<statut>"
      parent_managed_by_jira: true | false
```

### Modes

- **`local`** (défaut) — Epics et stories sont créées dans `docs/project/epics/E-XXXX-*/`. Aucun système externe.
- **`mcp`** — Epics et stories sont créées dans JIRA (ou autre PMS) via le serveur MCP `mcp_server`, projet `project_key`. Aucun fichier story local n'est créé pour ces tickets.

## Workflow de l'équipe

<!-- Décrire ici qui pilote le projet, à quelle cadence, où vit la roadmap, qui valide les stories, etc. -->

- **PM** : <à compléter>
- **Cadence** : <sprint hebdo / 2 semaines / autre>
- **Roadmap** : `docs/project/roadmap.md`
- **Workflow de validation** : <à compléter>

## États des stories

Les stories utilisent un champ `status` dans leur frontmatter YAML local :
- `TODO` — à faire
- `IN PROGRESS` — en cours
- `REVIEW` — en attente de revue
- `DONE` — terminée et validée

En mode `mcp`, ces statuts sont mappés vers les noms exacts du workflow JIRA via `mapping.status`.

## Sous-tâches (mode mcp)

Si le projet JIRA utilise des sous-tâches (Dev, Code review…), les agents peuvent les piloter individuellement via `subtask_workflow`. Sinon, ils ne pilotent que le ticket parent (Story).

Quand `parent_managed_by_jira: true`, les agents ne transitionnent **jamais** le ticket parent directement — JIRA fait le rollup automatique depuis les sous-tâches.
