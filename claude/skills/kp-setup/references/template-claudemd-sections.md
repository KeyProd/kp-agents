# Sections injectées dans `CLAUDE.md`

L'agent `setup` maintient ces 4 sections dans le `CLAUDE.md` à la racine du projet, repérées par titre `##` exact. Le contenu ci-dessous est le **template injecté** quand setup bootstrappe ou refresh.

Setup respecte le contenu humain ajouté **entre** ces sections — il ne touche que le contenu de chaque section qu'il pilote.

---

## Documentation

Ce projet suit la convention de documentation décrite dans [`docs/guidelines.md`](docs/guidelines.md). Tout agent IA travaillant sur ce projet doit la consulter.

- **Index global** : [`docs/index.md`](docs/index.md) — première consultation pour naviguer dans la doc
- **Sources de doc** : [`docs/documentation.md`](docs/documentation.md) — politique (commitée) ; chemins absolus dans `docs/documentation.local.md` (gitignored)
- **Vision produit** : [`docs/product.md`](docs/product.md)
- **Architecture** : [`docs/architect.md`](docs/architect.md)

## Projet & Tickets

Suivi projet (epics, stories, workflow, mapping JIRA/MCP) décrit dans [`docs/project.md`](docs/project.md) (politique commitée) avec overrides personnels dans `docs/project.local.md` (gitignored).

- **Roadmap** : [`docs/project/roadmap.md`](docs/project/roadmap.md)
- **Epics actives** : [`docs/project/epics/`](docs/project/epics/)
- **Epics archivées** : `docs/project/epics/_archives/`

## Git

Conventions git du projet (branches, commits, PR) dans [`docs/git.md`](docs/git.md). Préférences personnelles du développeur (auto-commit, auto-push) dans `docs/git.local.md` (gitignored).

## Apps

<!-- Section présente uniquement en monorepo. Setup la maintient avec la liste des apps détectées. -->

Le repo est un monorepo. Chaque app a sa propre documentation locale référencée dans son `docs/index.md`. Les conventions transversales (guidelines, git, project, documentation) restent à la racine.

<!-- Liste générée automatiquement par setup : -->
<!-- - **<app-name>** : [`apps/<app-name>/docs/index.md`](apps/<app-name>/docs/index.md) — <description courte> -->

---

## Règles d'injection (pour `setup`)

1. **Matching strict** par titre `## Documentation`, `## Projet & Tickets`, `## Git`, `## Apps`.
2. **Frontière de section** : du titre `##` jusqu'au prochain `##` (ou EOF).
3. **Matching fuzzy** : si le titre exact n'est pas trouvé mais qu'un titre proche existe (similarité de prefix + contenu reconnaissable comme pointeur vers `docs/`), proposer à l'utilisateur :
   > J'ai détecté `## Docs` qui ressemble à la section canonique `## Documentation`. Tu veux que je la renomme `## Documentation` et la maintienne ? (Y/n)
4. **Section absente** : créer en fin de fichier après confirmation. Ne jamais insérer silencieusement.
5. **Section `## Apps`** : ne créer que si workspaces détectés (`apps/`, `packages/`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `Cargo.toml [workspace]`). Sinon, omettre.
6. **Préservation du contenu hors sections gérées** : tout texte entre/autour des 4 sections est conservé tel quel.
