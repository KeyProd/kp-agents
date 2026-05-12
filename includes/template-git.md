---
kp-agents:
  branch_pattern: ""
---

# Conventions Git du projet

> Fichier commité — règles partagées par l'équipe. Les préférences personnelles (commit auto, push auto) sont dans `git.local.md` (non commité).

## Configuration machine-lisible

Le frontmatter en tête contient les clés lues par les agents :

| Clé | Valeurs | Effet |
|---|---|---|
| `branch_pattern` | string avec placeholders ou `""` | Template de nommage des branches feature. Placeholders : `{slug}` (kebab-case), `{ticket}` (clé JIRA ou `S-XXXX`), `{epic}`. Exemples : `feat/{slug}`, `feature/KP-{ticket}-{slug}`. Vide ou absent = l'agent demande le nom à chaque création. |

## Conventions de nommage des branches

<!-- Décrire ici les conventions humaines (préfixes autorisés, longueur max, casse, etc.). Exemple : -->

- Préfixes autorisés : `feat/`, `fix/`, `chore/`, `docs/`, `refactor/`
- Slug en kebab-case, ≤ 50 caractères
- Référence au ticket si applicable

## Conventions de commits

<!-- Décrire ici la convention de commits du projet. Exemple : Conventional Commits -->

Format `<type>(<scope>): <sujet>` — types : `feat`, `fix`, `chore`, `docs`, `refactor`, `test`.

## Pull requests

<!-- Décrire ici les règles de PR : reviewers, squash/merge, label, template, etc. -->

- 1 PR par story ou par epic complète selon le projet
- Review obligatoire avant merge
- Squash and merge par défaut
