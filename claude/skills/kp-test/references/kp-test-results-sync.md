## Mode `results-sync` — valider (critère 5) et remonter (critère 6, phase CI)

Garantit le **critère 5** (validation : runs verts répétables **+ validation visuelle humaine**) — bloquant pour clore localement. La **remontée (critère 6)** est **phasée CI/P3** : utile mais **non bloquante** pour déclarer un cas validé localement.

### Validation (critère 5) — bloquant

1. **Run ciblé** via `run_commands.headless`. Si rouge : analyser, corriger sélecteurs/timing (une itération), relancer. Si toujours rouge après correction → revenir à `implementation` ou, si c'est une précondition, à `data-isolation`.
2. **Stabilité** : exiger **2-3 runs verts d'affilée**. Tout flake = investigation immédiate (sélecteur ambigu, attente manquante, animation) — jamais « accepté ».
3. **Anti-faux-vert** : un test vert qui n'assène aucune assertion utile, ou qui passe sur des données absentes/invisibles, ne vaut pas validation (cf. garde de visibilité + juge LLM dans `implementation`).
4. **Validation visuelle humaine (verrou)** : une fois la spec verte et stable, **lance le run en mode UI** (`run_commands.ui` / `--ui -g "<clé>"`) et **demande explicitement à l'utilisateur** s'il valide le parcours observé. Le passage en « validé / Terminé » (et le `validated --confirm` du `progress_tracker`) n'a lieu **qu'après un « oui » humain** dans le tour courant. Jamais d'auto-validation.

### Remontée (critère 6) — phase CI/P3, non bloquant

> N'exécute la remontée que si la config l'active (`run_commands.with_sync` présent) **et** que l'utilisateur ou la CI le demande. Sinon, considère le cas **validé localement** sans remontée et passe à la suite.

1. **Run avec remontée** via `run_commands.with_sync` → génère le rapport JUnit puis pousse une **Test Execution** dans le référentiel.
2. **Liaison** : la remontée regex `<test_link_pattern>` sur le nom de chaque cas du JUnit — aucune table de mapping. D'où l'importance du critère 3 (préfixe correct).
3. **Agrégation 1:N** : plusieurs tests pour une même clé → un seul résultat par clé = **statut maximal** `FAILED > PASSED > TODO`.
4. **Non-idempotence** : chaque push crée une **nouvelle** Test Execution (par design). Ne pas chercher à « mettre à jour » une exécution existante.

### Protocole par statut

| Statut | Action |
|--------|--------|
| **Vert répété + validé humain** | critère 5 OK → cas **validé localement** (remontée 6 = phase CI) |
| **Vert mais non validé** | lance le run UI et **demande la validation** avant de clore |
| **Rouge** | diagnostiquer : régression code → `implementation` ; précondition → `data-isolation` (écris le seeder test) ou handoff `kp-developer` si structure applicative ; cas obsolète → signaler |
| **Flake** | investiguer la source (jamais ignorer), corriger, re-valider |
| **TODO / skip** | test non actif → repasser par `state-detection` |

### Sortie

Annonce le résultat du run et l'état mis à jour dans le `progress_tracker`. Un cas n'est « validé localement » qu'après 2-3 runs verts **et** le « oui » humain (run UI). Si un cas reste rouge/bloqué/non validé, ne le déclare jamais clos — produis le prochain pas (correction, validation UI, ou handoff).
