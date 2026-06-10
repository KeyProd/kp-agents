## Suivi de progression (`progress_tracker`)

Quand la config `testing` déclare un `progress_tracker` (tableau de bord de migration/couverture E2E), c'est **lui** qui matérialise « où on en est » par cas. Reflète chaque transition d'état — jamais à la main.

> ⚠️ **Règle d'or** : on ne modifie **jamais** le store de statuts ni le HTML rendu à la main. Toute transition passe par le **CLI dédié** (ex. keyprod : `set-status.mjs`), qui écrit le store **et** régénère le rendu. Un hook peut appliquer une partie des transitions automatiquement.

### Pipeline d'états (5, séquentiels)

| État | Sens | Qui le pose |
|---|---|---|
| **À faire** | cas inexistant dans le référentiel | initial |
| **Définition** | cas créé + rangé (critère 1) | script de création du référentiel |
| **En cours** | spec écrite (critère 2), pas encore verte | **hook auto** à l'écriture de la spec |
| **À valider** | spec fonctionnelle : 2-3 runs verts (critère 5 partiel) | agent, après runs verts confirmés |
| **Terminé** | **validé visuellement par l'utilisateur** (critère 5 complet) | **utilisateur** — verrou explicite |

La **remontée (critère 6)** est orthogonale et phasée CI/P3 : elle ne fait pas avancer cet état.

### Référence d'implémentation (keyprod)

- Store de vérité : `docs/e2e/xray/dashboard-status.json` (muté **uniquement** via `scripts/xray/set-status.mjs`).
- Rendu : `dashboard.html`, régénéré par `set-status.mjs` (build inline pour compat `file://`). Jamais édité à la main pour les **statuts** (le template de rendu, lui, peut évoluer).
- Hook `PostToolUse` (Write|Edit) : passe auto `pw→wip` (« En cours ») dès qu'une spec taguée `@KP-XXXX` est écrite.

```bash
node scripts/xray/set-status.mjs <KP|INV> xray            # → Définition
node scripts/xray/set-status.mjs <KP|INV> pw done         # → À valider
node scripts/xray/set-status.mjs <KP|INV> validated --confirm   # → Terminé (verrou humain)
```

- `author` = le **nom de l'utilisateur** qui pilote l'agent (jamais « kp-test »/« Claude »).
- `validated --confirm` est **refusé sans le flag** : il ne se pose qu'après la validation visuelle humaine en mode UI (cf. `kp-test-results-sync`, critère 5).

### Chorégraphie obligatoire de l'agent

1. **Cas créé** → `set-status <KP> xray`.
2. **Spec écrite** → le hook passe `wip` (rien à faire manuellement).
3. **Spec verte (2-3 runs)** → `set-status <KP> pw done`.
4. **Validation humaine** : run UI + **« tu valides ? »**. Oui → `set-status <KP> validated --confirm`. Sinon → corrige, reste « À valider ».

### Workflow par lot (batch)

Pour un lot de N cas : écrire les N specs → tout vert en headless → présenter en UI et faire **valider pas à pas** par l'utilisateur → marquer les validés → **un commit pour le lot** (specs + seeders test + fichiers du tracker régénérés).

### Commit

Inclure le store de statuts **et** le rendu régénéré dans le même commit que les specs/seeders du lot. Message type : `feat(e2e): <domaine> — N specs (KP-XXXXX→KP-YYYYY)`.
