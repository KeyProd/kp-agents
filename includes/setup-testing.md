## Configuration de la dimension `testing`

Cette dimension définit la chaîne de test E2E pilotée par l'agent `kp-test` (framework, dossier de tests, commandes de run, référentiel de cas, isolation, découverte). Elle écrit dans **deux fichiers** :

- `docs/testing.md` (commité) — politique partagée équipe (framework, dirs, commandes, référentiel, isolation, conventions)
- `docs/testing.local.md` (gitignored) — machine-spécifique (URL de découverte, chemin du fichier de credentials)

### Heuristique de détection (avant de poser les questions)

Détecte le framework probable pour proposer des défauts :
- `vendor/bin/pest` + un dossier `tests/Browser/` → **`pest-browser`** (cas keyprod de référence).
- Sinon, demander le framework (seul `pest-browser` est pleinement supporté aujourd'hui ; `playwright` est un hook futur).

### Questions à poser (groupées)

1. **Framework et dossier de tests ?** (défaut détecté : `pest-browser`, `tests_dir` détecté).
2. **Commandes de run ?** `headless` (valider) et `with_sync` (remonter), + `up`/`down` si harness conteneurisé. (ex. keyprod : `make test-browser`, `make test-browser-xray`).
3. **Référentiel de cas ?** `type` (xray…), `project_key`, `root_folder` (dossier racine des cas), `case_label`. Le `mcp_server` peut hériter de `tickets.mcp_server` (laisser vide pour hériter).
4. **Liaison test ↔ cas ?** `test_link_format` (gabarit de préfixe, ex. `[KP-{id}]`) → `test_link_pattern` (regex dérivée) est calculée.
5. **Isolation ?** `test_seed_namespace` (namespace des seeds **dédiés test**), `baseline_seeder`, `unique_ref_strategy`.
6. **Découverte (local) ?** MCP utilisé + `base_url_local` → va dans `.local.md`.
7. **Credentials du référentiel ?** chemin du fichier `.env` contenant les secrets (ex. `apps/kpweb/.env.testing`) → va dans `.local.md`. Ne jamais saisir les secrets eux-mêmes.

### Validation

- `test_link_pattern` : vérifier que la regex est valide (échappements doublés en YAML).
- `case_repository` mode `xray` : si MCP non chargé au moment du setup, consigner et avertir que la validation effective aura lieu à la première opération.
- `credentials_env` : vérifier que le fichier figure (ou sera ajouté) au `.gitignore` ; ne jamais commiter de secret.

### Écriture dans `docs/testing.md` (frontmatter)

Voir le schéma complet dans `references/sources-config-testing.md`. YAML clairsemé : n'écrire que ce qui diverge des défauts. Si le fichier existe avec un body humain (stratégie de test rédigée) : **préserver le body**, ne modifier que le frontmatter. Sinon, bootstrap minimal (frontmatter + titre + une ligne de prose).

### Écriture dans `docs/testing.local.md` (frontmatter)

`discovery.base_url_local`, `discovery.mcp`, `case_repository.credentials_env`. Vérifier que `docs/testing.local.md` est couvert par le `.gitignore` (pattern `docs/*.local.md`).

### Cas limites

- **Framework non `pest-browser`** → écrire la clé `framework` quand même (ex. `playwright`) ; avertir que le support concret est aujourd'hui centré sur `pest-browser`, les autres sont des hooks.
- **Pas de référentiel de cas** (`case_repository` absent) → `kp-test` fonctionne en mode test-only (pas de critères 1/6), avertir que la traçabilité Xray est désactivée.
- **`mcp_server` vide** → hérite de `tickets.mcp_server` ; si `tickets` non configuré non plus, demander explicitement.
- **Fichier `docs/testing.md` édité manuellement** → diff frontmatter, confirmation, préserver le body.
