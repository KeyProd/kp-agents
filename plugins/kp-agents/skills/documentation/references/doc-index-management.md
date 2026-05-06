## Gestion de `docs/INDEX.md`

L'index est un fichier central qui cartographie l'ensemble de la documentation du projet. Il est **lisible par un humain** et **optimisé pour la navigation des agents**. C'est le premier fichier à consulter pour comprendre l'état de la documentation.

### Responsabilité

Tu es le **seul responsable** de la création et de la maintenance de `docs/INDEX.md`. Les autres agents le consultent mais ne le modifient pas.

### Quand créer l'index

- Si `docs/INDEX.md` n'existe pas et que `docs/` contient au moins un document → **crée-le**.
- Si l'index existe déjà → **mets-le à jour** à chaque modification de la documentation.

### Quand mettre à jour l'index

- Après toute création, modification, suppression ou déplacement de document dans `docs/`.
- Après un audit qui révèle des écarts entre l'index et la réalité.
- Après l'archivage d'une epic.

### Template

Voir `references/index-template.md` (à lire à la demande lors de la création/mise à jour).

### Principes de rédaction

- **Exhaustif** : tout document présent dans `docs/` doit apparaître dans l'index.
- **Documents racine obligatoires** : `README.md` et `CLAUDE.md` (racine du projet) figurent **toujours** dans la section "Documents racine du projet" s'ils existent — règle systématique, non conditionnelle.
- **Factuel** : ne liste que ce qui existe réellement, pas ce qui devrait exister.
- **À jour** : dates et statuts reflètent l'état réel des fichiers.
- **Navigable** : chemins en backtick pour les agents, liens relatifs pour les humains si pertinent.
- **Concis** : une ligne par document, descriptions courtes — l'index n'est pas un résumé de contenu.

### Utilisation pour la navigation

- Avant un audit ou une analyse, **lis `docs/INDEX.md` en premier** pour avoir une vue d'ensemble instantanée.
- Utilise l'index pour identifier rapidement les lacunes (documents manquants, statuts obsolètes, features non documentées).
- En cas de doute sur l'existence d'un document, vérifie via l'index avant de parcourir l'arborescence manuellement.
