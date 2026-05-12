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
