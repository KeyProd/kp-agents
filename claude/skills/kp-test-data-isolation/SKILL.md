---
name: "kp-test-data-isolation"
description: "Isolation des données de test E2E : seeders dédiés test, setup/teardown idempotents, scopes multi-tenant, seeder FK-safe. Critère 4 de la DoD."
---

## Mode `data-isolation` — stratégie seed + clean (critère 4)

Garantit le **critère 4** : isolation stricte par la donnée, sur des seeds **dédiés test**. C'est le maillon le plus souvent en cause (un test « rédigé-bloqué » l'est presque toujours faute de précondition de données). Priorité forte de l'agent.

### Invariant dur — seeders dédiés test (écrits par toi), jamais les seeds métier

La donnée d'un test provient **exclusivement** de seeders dédiés test, sous `isolation.test_seed_namespace` (ex. keyprod : `Database\Seeders\cypress\<domaine>`, baseline `BrowserTestSeeder`). **Jamais** des seeds métier / production.

- **Tu écris/édites toi-même** ces seeders dédiés test (création + rollback). C'est dans ton périmètre.
- Si un test exige une donnée **hors** `test_seed_namespace` — un modèle/colonne applicative absent, un flag tenant, une migration — → **handoff `kp-developer`** (tu ne touches pas au code applicatif ni aux seeds métier).

### Seeder FK-safe (obligatoire)

Un seeder test ne doit **jamais coder en dur** un ID de référentiel (ils varient selon l'environnement de test). Résous-les **dynamiquement** : par code métier (`->where('access_code','administrator')`), par `min()` sur la table de référence, ou par lookup `pluck('id','code')`. Un ID en dur = échec FK silencieux selon l'env.

### Visibilité / scopes (précondition la plus fréquente)

Si l'app filtre les données par un **scope multi-tenant** (utilisateur ↔ usine/machine/groupe), une donnée seedée mais **non rattachée à l'utilisateur de test reste invisible** → le test tombe en faux-vert sur une liste vide. Le seeder doit donc **rattacher** la donnée à l'utilisateur courant selon le scope visé (ex. keyprod : insérer dans `user_assignments` ; la navigation lit l'assignation **directe machine**, pas seulement l'usine ; vider le cache de navigation après insert). Identifie le scope (`*Scope`) avant d'écrire le seeder.

### Modèle d'indépendance (browser = client HTTP distinct)

Le rollback transactionnel ne marche pas (le navigateur tape la même base que le backend). Deux stratégies admises selon la config :
- **Par cas** : `beforeEach` seed in-process + **`ref` unique** par entité (`isolation.unique_ref_strategy`, ex. `ref = 'e2e-' . uniqid()`) + `afterEach` cleanup idempotent.
- **Par seeder nommé + fixture** (ex. keyprod) : une fixture `seed(SeederClass, folder)` joue **Rollback → Seeder** au setup et **Rollback** au teardown ; les seeders portent des libellés stables et un rollback dédié. Asserter `success === true` côté fixture (échec silencieux si le seeder est absent).

### Règle « ne jamais muter un persona partagé »

Un test qui **mute un état partagé** (ex. changer le mot de passe d'un compte seedé par la baseline, modifier un flag tenant global) casserait les autres tests. → il lui faut une **entité dédiée et restaurable** (compte/flag provisionné en `beforeEach`, restauré en `afterEach`), pas le persona baseline. Si cette précondition n'existe pas → **handoff `kp-developer`**.

### Handoff `kp-developer` (format) — uniquement pour une donnée APPLICATIVE

Le seeder test, tu l'écris toi-même. Le handoff ne concerne que ce qui **dépasse** `test_seed_namespace` : modèle/colonne/migration absent, flag tenant à exposer côté app.

> **Handoff → @agent-kp-agents:kp-developer**
> **Contexte** : précondition APPLICATIVE manquante pour `<case_id>` (`<parcours>`)
> **À traiter** : `<modèle/colonne/migration/flag>` absent côté app — non seedable en l'état.
> **Pourquoi** : le test `<fichier>` ne peut être seedé sans cette structure applicative.

### Sortie

Critère 4 satisfait quand : seeder dédié test présent (namespace correct, **FK-safe**, **visibilité rattachée** à l'utilisateur si scope), setup/teardown idempotents, aucune mutation d'état partagé. Sinon → écris/corrige le seeder toi-même, ou handoff `kp-developer` si c'est une structure applicative.
