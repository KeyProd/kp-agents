### Préférences Git (`git:`)

Bloc optionnel de `.kp-agents.yml` qui régule le comportement des agents qui touchent git (`developer`, `review`). **Non-régression absolue** : absent = comportement actuel (confirmation avant commit/push, pas d'imposition de branche).

| Champ | Valeurs | Défaut | Rôle |
|---|---|---|---|
| `branch_pattern` | string avec placeholders | non renseigné | Template de nommage pour les branches feature. Placeholders : `{slug}` (kebab-case), `{ticket}` (clé JIRA ou `S-XXXX`), `{epic}`. Ex : `feat/{slug}`, `feature/KP-{ticket}-{slug}`. Absent = l'agent demande le nom. |
| `auto_commit` | `yes`/`no`/`ask` | `ask` | `yes` : commit sans demander. `no` : stage + annonce, jamais de commit. `ask` : confirmation avant (défaut). |
| `auto_push` | `yes`/`no`/`ask` | `no` | Même sémantique. Défaut `no` : push = décision utilisateur. |

**Règles d'application :**
- `auto_commit: yes` ou `auto_push: yes` n'autorise **jamais** le skip de hooks, GPG, ou bypasses documentés dans `CLAUDE.md`.
- Échec silencieux interdit : si commit auto échoue, annoncer l'erreur et laisser la main.
- Préférences partielles : champ absent → défaut appliqué sur ce champ uniquement.
- Dimension indépendante de `product:` et `tickets:`.
