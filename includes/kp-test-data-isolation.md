## Mode `data-isolation` — stratégie seed + clean (critère 4)

Garantit le **critère 4** : isolation stricte par la donnée, sur des seeds **dédiés test**. C'est le maillon le plus souvent en cause (un test « rédigé-bloqué » l'est presque toujours faute de précondition de données). Priorité forte de l'agent.

### Invariant dur — seed dédié test, jamais métier

La donnée d'un test provient **exclusivement** de seeds dédiés test, sous `isolation.test_seed_namespace` (ex. keyprod : `Database\Seeders\Browser`, baseline `BrowserTestSeeder`). **Jamais** des seeds métier / production de l'application.

- Si tu détectes qu'un test dépend d'une donnée **hors** `test_seed_namespace` (= seed métier détourné) → **refus** + **handoff `kp-developer`** pour créer la précondition dans le namespace test.
- Tu n'écris **jamais** toi-même dans le répertoire des seeds — c'est le périmètre exclusif de `kp-developer`.

### Modèle d'indépendance (browser = client HTTP distinct)

Le rollback transactionnel ne marche pas (le navigateur tape la même base que le backend). Donc :
- **`beforeEach`** : seed in-process de la donnée du test.
- **`ref` unique** par entité (`isolation.unique_ref_strategy`, ex. `ref = 'e2e-' . uniqid()`) → aucune collision inter-tests, aucun couplage d'ordre.
- **`afterEach`** : cleanup idempotent de ce que le test a créé.

### Règle « ne jamais muter un persona partagé »

Un test qui **mute un état partagé** (ex. changer le mot de passe d'un compte seedé par la baseline, modifier un flag tenant global) casserait les autres tests. → il lui faut une **entité dédiée et restaurable** (compte/flag provisionné en `beforeEach`, restauré en `afterEach`), pas le persona baseline. Si cette précondition n'existe pas → **handoff `kp-developer`**.

### Handoff `kp-developer` (format)

Quand une précondition de données manque, produis un handoff explicite :

> **Handoff → /kp-agents:kp-developer**
> **Contexte** : précondition de test manquante pour `<case_id>` (`<parcours>`)
> **À traiter** : créer un seeder **dédié test** pour `<domaine>` sous `<test_seed_namespace>` (ex. provisionner `<flag/compte/entité>`). **Ne pas** toucher aux seeders métier.
> **Pourquoi** : le test `<fichier>` est bloqué (cf. commentaire `BLOCKER:`) faute de cette donnée.

### Sortie

Critère 4 satisfait quand : seed dédié test présent (namespace correct), `beforeEach`/`afterEach` en place avec `ref` unique, aucune mutation d'état partagé. Sinon → handoff ou correction, jamais de contournement par un seed métier.
