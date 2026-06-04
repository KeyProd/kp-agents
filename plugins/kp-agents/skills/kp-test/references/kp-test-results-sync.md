## Mode `results-sync` — valider et remonter (critères 5 + 6)

Garantit le **critère 5** (validation : runs verts répétables) et le **critère 6** (remontée effective dans le référentiel).

### Validation (critère 5)

1. **Run ciblé** via `run_commands.headless` (ex. keyprod : `make test-browser`). Si rouge : analyser, corriger sélecteurs/timing (une itération), relancer. Si toujours rouge après correction → revenir à `implementation` ou, si c'est une précondition, à `data-isolation` (handoff `kp-developer`).
2. **Stabilité** : exiger **2-3 runs verts d'affilée**. Tout flake = investigation immédiate (sélecteur ambigu, attente manquante, animation) — un flake n'est jamais « accepté ».
3. **Anti-faux-vert** : un test vert qui n'assène aucune assertion utile ne vaut pas validation (cf. juge LLM dans `implementation`).

### Remontée (critère 6)

1. **Run avec remontée** via `run_commands.with_sync` (ex. keyprod : `make test-browser-xray`) → génère le rapport JUnit puis pousse une **Test Execution** dans le référentiel.
2. **Liaison** : la remontée regex `<test_link_pattern>` sur le nom de chaque cas de test du JUnit — aucune table de mapping. D'où l'importance du critère 3 (préfixe correct).
3. **Agrégation 1:N** : plusieurs tests pour une même clé → un seul résultat par clé = **statut maximal** `FAILED > PASSED > TODO`.
4. **Non-idempotence** : chaque push crée une **nouvelle** Test Execution (par design, conserve l'historique). Ne pas chercher à « mettre à jour » une exécution existante.

### Protocole par statut

| Statut | Action |
|--------|--------|
| **Vert répété** | critères 5+6 OK → cas conforme (DoD verte) |
| **Rouge** | diagnostiquer : régression code → `implementation` ; précondition → `data-isolation` + handoff `kp-developer` ; cas obsolète → signaler |
| **Flake** | investiguer la source (jamais ignorer), corriger, re-valider |
| **TODO / skip** | test non actif → repasser par `state-detection` (souvent un blocage seed) |

### Sortie

Annonce le résultat du run, le statut remonté par clé, et l'URL de la Test Execution. Si un cas reste rouge/bloqué, ne le déclare jamais DONE — produis le prochain pas (correction ou handoff).
