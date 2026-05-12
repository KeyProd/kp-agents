---
kp-agents:
  auto_commit: ask
  auto_push: no
---

# Préférences Git locales (développeur)

> **Fichier non commité** (gitignored). Préférences personnelles du développeur qui ne doivent pas affecter l'équipe.

## Configuration machine-lisible

| Clé | Valeurs | Défaut | Effet |
|---|---|---|---|
| `auto_commit` | `yes`, `no`, `ask` | `ask` | `yes` : commit sans demander. `no` : stage + annonce, jamais de commit. `ask` : confirmation avant chaque commit. |
| `auto_push` | `yes`, `no`, `ask` | `no` | Même sémantique. Défaut `no` : push reste une décision explicite. |

## Règles d'application

- `auto_commit: yes` ou `auto_push: yes` **n'autorise jamais** le skip de hooks (`--no-verify`), GPG, ou bypasses documentés dans `CLAUDE.md`. C'est un raccourci de confirmation, pas une désactivation des règles de sécurité.
- Échec silencieux interdit : si un commit auto échoue (hook, conflit…), l'agent annonce l'erreur et rend la main.
- Préférences indépendantes des conventions projet (`git.md`).
