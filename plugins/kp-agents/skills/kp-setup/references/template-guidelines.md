# Conventions de documentation du projet

> **Note pour les agents IA** — Ce fichier décrit la convention `docs/` du projet. Tout agent (kp-agents, superpower, ou autre) doit le lire pour comprendre où trouver le contexte et où écrire.

## Fichiers structurants à la racine de `docs/`

| Fichier | Rôle | Commité ? | Maintenu par |
|---|---|---|---|
| `index.md` | Index navigable de toute la documentation | ✅ oui | agent `documentation` |
| `guidelines.md` | Ce fichier — convention de la documentation | ✅ oui | agent `setup` |
| `git.md` | Conventions git du projet (branches, commits, PR) | ✅ oui | agent `setup` |
| `git.local.md` | Préférences git du développeur (auto-commit, auto-push) | ❌ non (gitignored) | agent `setup` |
| `project.md` | Suivi projet (tickets, workflow, statuts, mapping MCP/JIRA) | ✅ oui | agent `setup` |
| `project.local.md` | Overrides locaux du suivi projet (ex: project_key personnel) | ❌ non (gitignored) | agent `setup` |
| `documentation.md` | Sources de documentation (produit externe, specs, tech, inputs PM) | ✅ oui | agent `setup` |
| `documentation.local.md` | Chemins machine-spécifiques des sources de doc | ❌ non (gitignored) | agent `setup` |

Les fichiers `.local.md` sont **toujours gitignored**. L'agent `setup` ajoute automatiquement `docs/*.local.md` au `.gitignore`.

## Structure `docs/` complète

```
docs/
├── index.md                            # Index (documentation)
├── guidelines.md                       # Ce fichier
├── git.md                              # Conventions git projet
├── git.local.md                        # Préférences git dev (gitignored)
├── project.md                          # Suivi projet (tickets, workflow)
├── project.local.md                    # Overrides locaux (gitignored)
├── documentation.md                    # Sources de doc (produit, specs, tech)
├── documentation.local.md              # Chemins locaux (gitignored)
├── product.md                          # Vision produit globale
├── architect.md                        # Architecture technique globale
├── ideas/                              # Idées brainstormées (un .md par thème)
├── features/<group>/
│   ├── product.md                      # Spec produit du groupe
│   └── architect.md                    # Design technique du groupe
└── project/
    ├── roadmap.md                      # Roadmap (phases, jalons)
    └── epics/
        ├── E-XXXX-Nom-Simple/
        │   ├── readme.md
        │   └── S-XXXX-Nom-Simple.md
        └── _archives/                  # Epics terminées
```

## Monorepo

Si le projet contient des apps (`apps/<name>/`, `packages/<name>/`), chaque app peut avoir son propre `docs/index.md`. Les fichiers transversaux (`guidelines.md`, `git.md`, `project.md`, `documentation.md`) **restent uniquement à la racine** du repo et s'appliquent à tout le monorepo. Le `docs/index.md` racine liste les apps avec un lien vers leur index.

## Configuration machine-lisible : frontmatter YAML

Les fichiers `git.md`, `git.local.md`, `project.md`, `project.local.md`, `documentation.md`, `documentation.local.md` portent une **configuration structurée en frontmatter YAML** (entre `---` en tête du fichier), sous la clé top-level `kp-agents:`. Le body markdown reste de la prose humaine.

Exemple `docs/git.md` :

```markdown
---
kp-agents:
  branch_pattern: "feat/{slug}"
---

# Conventions Git du projet

## Nommage des branches

Les branches feature suivent le pattern `feat/<slug>` où `<slug>` est…
```

Cette convention garantit que :
- N'importe quel agent IA peut **parser déterministiquement** le frontmatter pour récupérer la config
- Les humains lisent le body en prose
- Les changements machine-readables se font via le frontmatter sans toucher la prose

## Statuts des stories

Champ `status` dans le frontmatter YAML de chaque story : `TODO`, `IN PROGRESS`, `REVIEW`, `DONE`.

## Nommage epics et stories

- Epics : `E-XXXX-Nom-Simple/` (PascalCase séparé par tirets, numéro sur 4 chiffres, séquentiel global)
- Stories : `S-XXXX-Nom-Simple.md` (fichier dans le répertoire de l'epic, numérotation locale à l'epic — repart de S-0001 pour chaque nouvelle epic)

## Archivage

Quand toutes les stories d'une epic sont `DONE` (ou epic abandonnée), le répertoire est déplacé dans `docs/project/epics/_archives/`. Les agents ne créent **jamais** de nouvelle story dans `_archives/` mais peuvent y lire pour du contexte historique.

## Sections gérées dans `CLAUDE.md`

L'agent `setup` maintient 4 sections dans le `CLAUDE.md` du projet, repérées par titre `##` exact :

- `## Documentation` — pointe vers `docs/index.md`, `docs/guidelines.md`, `docs/documentation.md`
- `## Projet & Tickets` — pointe vers `docs/project.md`
- `## Git` — pointe vers `docs/git.md`
- `## Apps` — liste des apps du monorepo (uniquement si workspaces détectés)

**Ne renomme jamais ces titres `##`** sous peine de friction au prochain `/kp-agents:kp-setup` (matching fuzzy avec demande de confirmation).
