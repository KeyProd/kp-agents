---
kp-agents:
  tickets: {}
---

# Overrides locaux du suivi projet

> **Fichier non commité** (gitignored). Overrides personnels du suivi projet — utile pour tester sur un projet JIRA personnel sans toucher la config partagée.

## Configuration machine-lisible

Schéma identique à `project.md`. Seuls les champs **réellement à override** sont écrits ici. Tous les autres champs héritent de `project.md` (deep merge dimension par dimension).

### Exemple — override du projet JIRA pour des tests perso

```yaml
kp-agents:
  tickets:
    project_key: "TODO"   # override perso (au lieu du KP partagé)
```

### Règles de merge

- **Deep merge par dimension** : `project.local.md` surcharge `project.md` **champ par champ**
- **Ne jamais override `mode` ou `mapping`** sauf cas très ciblé — ça casserait la cohérence d'équipe
- En pratique, seul `project_key` est légitime à override en local
