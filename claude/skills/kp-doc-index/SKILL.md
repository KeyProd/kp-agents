---
name: "kp-doc-index"
description: "Maintenance de l'index de documentation (docs/index.md) : structure, génération et mise à jour de l'index navigable. Réservé à l'agent documentation."
---

## Gestion de `docs/index.md`

L'index est un fichier central qui cartographie l'ensemble de la documentation du projet. Il est **lisible par un humain** et **optimisé pour la navigation des agents**. C'est le premier fichier à consulter pour comprendre l'état de la documentation.

### Responsabilité

Tu es le **seul responsable** de la création et de la maintenance de `docs/index.md`. Les autres agents le consultent mais ne le modifient pas.

### Quand créer l'index

- Si `docs/index.md` n'existe pas et que `docs/` contient au moins un document → **crée-le**.
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
- **Section "Documents structurants `docs/`"** : lister `guidelines.md`, `git.md`, `git.local.md` (si présent), `project.md`, `project.local.md` (si présent), `documentation.md`, `documentation.local.md` (si présent). Indiquer pour chacun s'il est commité ou gitignored.
- **Section "Apps" (monorepo uniquement)** : si le repo contient des workspaces (détectés via `apps/`, `packages/`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `Cargo.toml [workspace]`), lister chaque app avec un lien vers son `apps/<name>/docs/index.md` et une description courte (1 ligne).
- **Factuel** : ne liste que ce qui existe réellement, pas ce qui devrait exister.
- **À jour** : dates et statuts reflètent l'état réel des fichiers.
- **Navigable** : chemins en backtick pour les agents, liens relatifs pour les humains si pertinent.
- **Concis** : une ligne par document, descriptions courtes — l'index n'est pas un résumé de contenu.

### Cas particulier — fichiers `.local.md`

Les fichiers `git.local.md`, `project.local.md`, `documentation.local.md` sont gitignored et machine-spécifiques. Ils peuvent ou non exister selon le poste. Tu peux les lister dans l'index s'ils sont présents, en signalant qu'ils sont gitignored (pour éviter qu'un humain croie qu'ils manquent du repo).

### Utilisation pour la navigation

- Avant un audit ou une analyse, **lis `docs/index.md` en premier** pour avoir une vue d'ensemble instantanée.
- Utilise l'index pour identifier rapidement les lacunes (documents manquants, statuts obsolètes, features non documentées).
- En cas de doute sur l'existence d'un document, vérifie via l'index avant de parcourir l'arborescence manuellement.
