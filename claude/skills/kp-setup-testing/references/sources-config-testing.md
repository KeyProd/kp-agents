### Dimension `testing` (agent `kp-test`)

Configuration lue dans le frontmatter `kp-agents:` de `docs/testing.md` (commité — politique partagée) avec overrides dans `docs/testing.local.md` (gitignored — machine-spécifique). Absente = `kp-test` bascule en mode dégradé (demande les infos minimales en conversation, propose `@agent-kp-agents:kp-setup`).

#### Schéma `testing`

`docs/testing.md` (commité) :

```markdown
---
kp-agents:
  testing:
    framework: playwright              # framework livré ; pest-browser = autre exemple (config-driven)
    tests_dir: apps/kpweb/tests/e2e
    test_file_pattern: "*.spec.ts"
    run_commands:
      headless:  "make test-browser"
      with_sync: "make test-browser-xray"
      up:        "make test-browser-up"
      down:      "make test-browser-down"
    case_repository:
      type: xray
      mcp_server: ""                   # vide → hérite de tickets.mcp_server
      project_key: KP
      root_folder: "/Tests PlayWright"
      test_link_pattern: "\\[KP-\\d+\\]"   # regex de liaison (machine)
      test_link_format: "[KP-{id}]"        # gabarit de préfixe injecté dans le test
      case_label: playwright
      graphql_endpoint: "https://xray.cloud.getxray.app/api/v2"
    isolation:
      test_seed_namespace: "Database\\Seeders\\Browser"
      baseline_seeder: BrowserTestSeeder
      unique_ref_strategy: "ref = 'e2e-' . uniqid()"
    conventions_doc: apps/kpweb/docs/e2e/conventions.md
---
```

`docs/testing.local.md` (gitignored) :

```markdown
---
kp-agents:
  testing:
    discovery:
      mcp: playwright
      base_url_local: "http://localhost:8081"
    case_repository:
      credentials_env: apps/kpweb/.env.testing   # XRAY_CLIENT_ID / XRAY_CLIENT_SECRET
---
```

#### Règles de lecture

1. **Deep merge** `docs/testing.local.md` ⊃ `docs/testing.md` (champ par champ). Le local porte ce qui dépend de la machine (URL de découverte, chemin des credentials).
2. **Héritage** : `case_repository.mcp_server` vide → utiliser `tickets.mcp_server` (`docs/project.md`). Idem `project_key` peut s'aligner sur `tickets.project_key`.
3. **Secrets** : `credentials_env` pointe un fichier `.env` gitignored (jamais commité, jamais affiché). `kp-test` lit `XRAY_CLIENT_ID`/`SECRET` pour l'auth GraphQL du référentiel de cas.
4. **Rangement bloquant** : si `credentials_env` absent ou auth GraphQL KO, le critère 1 (cas rangé) est non satisfiable → `kp-test` signale le prérequis, ne déclare jamais un cas DONE sans rangement vérifié.
5. **Agnosticité** : `framework: playwright` est le framework livré. Pour un autre framework (ex. `pest-browser`), remplir les mêmes clés différemment — `kp-test` applique la config, sans hardcode.
6. Config absente / incomplète → warn + `@agent-kp-agents:kp-setup` + mode local dégradé. Jamais bloquant en dehors du critère 1 (rangement).
