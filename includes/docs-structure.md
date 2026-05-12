## Convention de sortie - Répertoire `docs/`

Tous les documents générés DOIVENT être placés dans le répertoire `docs/` du projet courant. La convention complète (lisible par tout agent IA, y compris externes) est écrite dans `docs/guidelines.md` — **lis ce fichier en premier** s'il existe.

### Arborescence

```
docs/
├── index.md                            # Index navigable (maintenu par documentation)
├── guidelines.md                       # Convention complète pour tout agent
├── git.md                              # Conventions git projet (commité)
├── git.local.md                        # Préférences git dev (gitignored)
├── project.md                          # Suivi projet, tickets, workflow (commité)
├── project.local.md                    # Overrides locaux (gitignored)
├── documentation.md                    # Politique sources de doc (commité)
├── documentation.local.md              # Chemins locaux machine-spécifiques (gitignored)
├── product.md                          # Vision produit globale
├── architect.md                        # Architecture technique globale
├── ideas/                              # Un fichier par idée/thème (agent brainstorm)
├── features/<feature-group>/
│   ├── product.md                      # Spec produit du groupe
│   └── architect.md                    # Design technique du groupe
└── project/
    ├── roadmap.md                      # Roadmap (phases, jalons)
    └── epics/
        ├── E-XXXX-Nom-Simple/
        │   ├── readme.md               # Détail de l'epic
        │   ├── S-XXXX-Nom-Simple.md    # Story (TODO)
        │   └── ...
        └── _archives/                  # Epics terminées ou abandonnées
```

### Configuration machine-lisible (frontmatter YAML)

Les 6 fichiers `git.md`, `git.local.md`, `project.md`, `project.local.md`, `documentation.md`, `documentation.local.md` portent leur configuration dans un **frontmatter YAML** (entre `---` en tête), sous la clé top-level `kp-agents:`. Le body reste de la prose humaine.

**Lecture obligatoire au démarrage** : si un agent a besoin de la config, il lit le frontmatter du fichier concerné — pas du langage naturel dans la prose.

Schéma résumé :

| Fichier | Clés frontmatter `kp-agents:` |
|---|---|
| `git.md` | `branch_pattern` |
| `git.local.md` | `auto_commit`, `auto_push` |
| `project.md` | `tickets.mode`, `tickets.mcp_server`, `tickets.project_key`, `tickets.mapping.*` |
| `project.local.md` | overrides de `tickets.*` (deep merge) |
| `documentation.md` | `product.mode`, `product.access` |
| `documentation.local.md` | `product.path`, `global_doc.specs`, `global_doc.tech`, `global_doc.product_inputs` |

### Nommage

- Epics : `E-XXXX-Nom-Simple/` (répertoire, PascalCase séparé par tirets, numéro sur 4 chiffres)
- Stories : `S-XXXX-Nom-Simple.md` (fichier dans le répertoire de l'epic)
- Numérotation epics : séquentielle globale (E-0001, E-0002...)
- Numérotation stories : **repart de S-0001 pour chaque epic** (locale à l'epic)

### Statuts des stories

Frontmatter YAML de chaque story, champ `status` :
- `TODO`, `IN PROGRESS`, `REVIEW`, `DONE`

### Archivage

- Toutes les stories d'une epic en `DONE` (ou epic abandonnée) → déplacer le répertoire dans `docs/project/epics/_archives/`
- Mettre à jour `status` dans le frontmatter du `readme.md` de l'epic (`done` ou `cancelled`)
- Jamais de nouvelle story dans `_archives/`
- Lecture autorisée pour contexte historique

### Index

- Si `docs/index.md` existe → **consulte-le en priorité** pour naviguer
- Index maintenu **exclusivement** par l'agent `documentation` — ne le modifie pas toi-même
- Si index absent ou obsolète → signale-le et recommande `/kp-agents:documentation`

### Monorepo

Si le projet contient des apps (`apps/<name>/`, `packages/<name>/`) — détecté via `apps/`, `packages/`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `Cargo.toml [workspace]` —, chaque app peut avoir son propre `apps/<name>/docs/index.md`. Les fichiers transversaux (`guidelines.md`, `git.md`, `project.md`, `documentation.md`) **restent uniquement à la racine** du repo. Le `docs/index.md` racine liste les apps avec un lien vers leur index.

### Règles

- Crée les répertoires manquants si nécessaire (`mkdir -p`)
- Lors d'une mise à jour, lis le fichier existant avant d'écrire pour ne pas perdre de contenu
- Chaque document inclut un en-tête YAML frontmatter avec : `title`, `date`, `status`, `author` (agent name)
- Les liens entre documents utilisent des chemins relatifs (ex: `../E-0001-Auth-System/readme.md`)
- Les liens vers des epics archivées pointent vers `_archives/`

## Templates de référence

Quand un agent crée ou réécrit un document structurant, il doit s'aligner sur les conventions suivantes.

**Priorité** : vérifie d'abord `.kp-context.yml` → `context.templates.<nom>`. Si le chemin est défini (non `~`), lis ce fichier. Sinon, utilise le template bundled dans `references/`.

| Document | Clé `.kp-context.yml` | Template bundled |
|----------|-----------------------|------------------|
| `docs/product.md` | `context.templates.product` | {{ref:product-template}} |
| `docs/architect.md` | `context.templates.architect` | {{ref:architect-template}} |
| `docs/project/epics/E-XXXX-Nom-Simple/readme.md` | `context.templates.epic` | {{ref:epic-template}} |
| `docs/project/epics/E-XXXX-Nom-Simple/S-XXXX-Nom-Simple.md` | `context.templates.story` | {{ref:story-template}} |

Ces templates servent de référence de lisibilité et d'homogénéité. Ils peuvent être adaptés si le contexte l'exige, mais sans perdre :
- la clarté du public cible
- la séparation produit / architecture / epic / story
- la traçabilité des règles métier, dépendances, scénarios et critères de validation
