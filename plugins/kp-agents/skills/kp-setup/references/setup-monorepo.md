## Détection et bootstrap monorepo

Si le projet est un monorepo, chaque app peut avoir son propre `docs/index.md`. Les fichiers transversaux (`guidelines.md`, `git.md`, `project.md`, `documentation.md`) **restent à la racine** et s'appliquent à tout le repo.

### Détection des workspaces

Setup détecte un monorepo via l'**un** des signaux suivants (présence du fichier ou dossier à la racine) :

| Signal | Type | Méthode d'extraction des apps |
|---|---|---|
| `apps/` (dossier) | convention de naming | lister les sous-dossiers de `apps/` |
| `packages/` (dossier) | convention de naming | lister les sous-dossiers de `packages/` |
| `pnpm-workspace.yaml` | pnpm | parser `packages:` (globs) |
| `lerna.json` | Lerna | parser `packages:` |
| `nx.json` | Nx | détecter `apps/` et `libs/` via workspace |
| `turbo.json` | Turborepo | utiliser `package.json` `workspaces:` |
| `Cargo.toml` avec `[workspace]` | Cargo | parser `members:` |
| `package.json` avec `workspaces:` | npm/yarn | parser `workspaces:` (globs) |

Si plusieurs signaux coexistent (cas fréquent : `package.json workspaces` + `apps/`), prendre l'union dédoublonnée.

### Questions à poser

Si détection positive :

1. **Lister les apps détectées** et demander si l'utilisateur veut bootstrap un `docs/` local par app :
   > J'ai détecté un monorepo avec ces apps : `web`, `api`, `mobile`. Veux-tu que je crée un `docs/index.md` minimal dans chacune ? (Y / sélection / N)
   - **Y** → bootstrap tous
   - **Sélection** → liste à cocher
   - **N** → ne rien faire, juste maintenir la section `## Apps` dans CLAUDE.md avec la liste

2. **Pour chaque app sélectionnée**, demander une **description courte** (1 phrase) qui ira dans le `docs/index.md` racine.

### Bootstrap d'un `apps/<name>/docs/index.md`

Template minimal :

```markdown
---
title: Index documentation — <name>
date: <YYYY-MM-DD>
status: active
author: setup-agent
---

# Documentation — <name>

> Documentation locale de l'app `<name>`. Les conventions transversales sont définies au niveau du repo dans [`../../../docs/guidelines.md`](../../../docs/guidelines.md).

## Documents principaux

| Document | Chemin | Description |
|---|---|---|
| (à créer) | `apps/<name>/docs/product.md` | Vision produit de l'app |
| (à créer) | `apps/<name>/docs/architect.md` | Architecture technique de l'app |

> Ce fichier est maintenu par l'agent `documentation`. Pour l'index global du repo, voir [`../../../docs/index.md`](../../../docs/index.md).
```

Créer le dossier (`mkdir -p apps/<name>/docs`) si nécessaire.

### Bootstrap du `docs/index.md` racine (section Apps)

Le `docs/index.md` racine est maintenu par l'agent `documentation`, mais setup peut **pré-créer la section `## Apps`** au bootstrap initial avec la liste des apps détectées + leur description courte. Format :

```markdown
## Apps (monorepo)

| App | Chemin | Index local | Description |
|-----|--------|-------------|-------------|
| web | `apps/web/` | `apps/web/docs/index.md` | <description courte> |
| api | `apps/api/` | `apps/api/docs/index.md` | <description courte> |
```

Si `docs/index.md` n'existe pas encore, setup le crée a minima avec cette section. L'agent `documentation` enrichira ensuite (sections `Documents racine`, `Documents principaux`, etc.).

Si `docs/index.md` existe déjà avec une section `## Apps`, setup met à jour son contenu. Sinon, l'insère après la section `## Documents structurants docs/` ou en fin de fichier.

### Section `## Apps` dans `CLAUDE.md`

Voir ``references/setup-claudemd.md`` pour la maintenance dans `CLAUDE.md` — setup synchronise la liste des apps détectées dans la section `## Apps` du `CLAUDE.md` racine.

### Cas limites

- **Pas de monorepo détecté** → ne pas créer de section `## Apps` dans CLAUDE.md, ne pas demander à l'utilisateur.
- **Monorepo détecté mais aucune app peuplée** (ex: `apps/` vide) → signaler, ne pas bootstrap d'`apps/<name>/docs/`.
- **Apps avec naming hétérogène** (ex: certaines dans `apps/`, certaines dans `packages/`) → lister toutes ensemble dans la section `## Apps`, distinguer par chemin.
- **Workspace globs complexes** (ex: `apps/*/*` ou `packages/@scope/*`) → expand le glob, lister les matches.
- **App existante avec son propre `docs/`** déjà peuplé → ne pas écraser. Vérifier juste que `docs/index.md` existe et inclure dans la section racine.
- **L'utilisateur refuse le bootstrap par app** → maintenir uniquement la section `## Apps` dans CLAUDE.md (liste sans bootstrap). Pas de création de fichiers dans les apps.
