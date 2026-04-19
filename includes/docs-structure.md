## Convention de sortie - Répertoire docs/

Tous les documents générés DOIVENT être placés dans le répertoire `docs/` du projet courant, en respectant cette structure :

```
docs/
├── INDEX.md                            # Index de la documentation (maintenu par l'agent Documentation)
├── product.md                          # Vision produit globale
├── architect.md                        # Architecture technique globale
├── ideas/                              # Un fichier par idée/thème (agent brainstorm)
│   ├── auth-passwordless.md
│   ├── real-time-collab.md
│   └── ...
├── features/
│   └── <feature-group>/
│       ├── product.md                  # Spec produit du groupe de features
│       └── architect.md                # Design technique du groupe de features
└── project/
    ├── roadmap.md                      # Roadmap produit (phases, jalons, priorités)
    └── epics/
        ├── E-XXXX-Nom-Simple/          # Un répertoire par epic
        │   ├── readme.md               # Détail de l'epic
        │   ├── S-XXXX-Nom-Simple.md    # Story (TODO)
        │   ├── S-XXXY-Autre-Story.md   # Story (IN PROGRESS)
        │   └── ...
        └── _archives/                  # Epics terminées ou abandonnées
            └── E-XXXX-Nom-Simple/      # Même structure, déplacée telle quelle
```

### Nommage :
- Epics : `E-XXXX-Nom-Simple/` (répertoire, PascalCase séparé par tirets, numéro sur 4 chiffres)
- Stories : `S-XXXX-Nom-Simple.md` (fichier dans le répertoire de l'epic parente)
- Numérotation des epics : séquentielle globale (E-0001, E-0002...)
- Numérotation des stories : **repart de S-0001 pour chaque epic** (locale à l'epic, pas globale)

### Statuts des stories :
Les stories utilisent un champ `status` dans leur frontmatter YAML, avec les valeurs :
- `TODO` — à faire
- `IN PROGRESS` — en cours de développement
- `REVIEW` — en attente de revue
- `DONE` — terminée et validée

### Archivage des epics :
- Quand toutes les stories d'une epic sont `DONE` (ou que l'epic est abandonnée), le répertoire de l'epic est déplacé dans `docs/project/epics/_archives/`
- La structure interne du répertoire est conservée telle quelle
- Le `status` dans le frontmatter du `readme.md` de l'epic est mis à jour (`done` ou `cancelled`)
- Les agents ne doivent JAMAIS créer de nouvelles stories dans `_archives/`
- Les agents peuvent lire `_archives/` pour du contexte historique

### Index de la documentation :
- Si `docs/INDEX.md` existe, **consulte-le en priorité** pour naviguer efficacement dans la documentation existante avant de parcourir l'arborescence manuellement
- L'index est maintenu exclusivement par l'agent Documentation — ne le modifie pas toi-même
- Si tu constates que l'index est absent ou obsolète, signale-le et recommande un passage vers l'agent Documentation

### Règles :
- Crée les répertoires manquants si nécessaire (`mkdir -p`)
- Lors d'une mise à jour, lis le fichier existant avant d'écrire pour ne pas perdre de contenu
- Chaque document inclut un en-tête YAML frontmatter avec : `title`, `date`, `status`, `author` (agent name)
- Les liens entre documents utilisent des chemins relatifs (ex: `../E-0001-Auth-System/readme.md`)
- Les liens vers des epics archivées pointent vers `_archives/` (ex: `../_archives/E-0001-Auth-System/readme.md`)

## Templates de référence

Quand un agent crée ou réécrit un document structurant, il doit s'aligner sur les conventions suivantes :

- `docs/product.md` : {{ref:product-template}}
- `docs/architect.md` : {{ref:architect-template}}
- `docs/project/epics/E-XXXX-Nom-Simple/readme.md` : {{ref:epic-template}}
- `docs/project/epics/E-XXXX-Nom-Simple/S-XXXX-Nom-Simple.md` : {{ref:story-template}}

Ces templates servent de référence de lisibilité et d'homogénéité. Ils peuvent être adaptés si le contexte l'exige, mais sans perdre :
- la clarté du public cible
- la séparation produit / architecture / epic / story
- la traçabilité des règles métier, dépendances, scénarios et critères de validation
