## Mode `state-detection` — situer l'état d'un cas (audit DoD)

Routine d'orientation **systématique en tête de toute session `auto`**. Objectif : pour une cible (clé `<case_id>` ou parcours décrit), déterminer quels critères de la Definition of Done sont satisfaits et quel est le **prochain pas**. Tu ne modifies rien dans ce mode — tu observes et tu décides.

### Lectures (dans l'ordre)

1. **Contexte fourni** : story, clé ou parcours donné par l'utilisateur.
2. **Filesystem** : `grep -roE "<test_link_pattern>" <tests_dir>` localise le(s) test(s) portant la clé.
   *(ex. keyprod : `grep -roE "\[KP-[0-9]+\]" apps/kpweb/tests/e2e`)*
3. **Référentiel de cas** (`case_repository`) — deux canaux (cf. `kp-test-case-design`) :
   - **contenu** via MCP (`getJiraIssue`, `searchJiraIssuesUsingJql`) : le cas existe-t-il ? type, summary, description, label ?
   - **rangement** via API GraphQL (`getFolder`/`getTests`) : le cas est-il rangé sous `root_folder` ?
4. **Runtime** (si pertinent) : dernière exécution / Test Execution remontée.

### Les 4 états filesystem (+ statut runtime orthogonal)

| État | Signature | Critère DoD en écart | Prochain pas |
|------|-----------|----------------------|--------------|
| **Absent** | aucun test ne porte la clé | 1, 2, 3 | `case-design` (si cas manquant) puis `implementation` |
| **Squelette** | test déclaré « à faire » sans corps (ex. `test.fixme('[KP-X] …')`) | 2 | `implementation` (discovery + corps) |
| **Rédigé-bloqué** | corps complet **+** marqueur d'attente (`test.fixme()`/`test.skip()`) **+** commentaire de blocage (ex. `BLOCKER:`) | 4 le plus souvent | **parser le blocage → handoff `kp-developer`** |
| **Actif** | test exécutable complet | 5, 6 | `results-sync` (valider + remonter) |

Le **statut runtime** (vert / rouge / flake) est orthogonal à l'état filesystem : un test « actif » peut être rouge. Il vient du run, pas du fichier.

### Parsing des marqueurs de blocage

Un test « rédigé-bloqué » porte presque toujours un commentaire expliquant *pourquoi* il n'est pas actif (convention projet, ex. `// BLOCKER: …`). **Extrais la cause** :
- Précondition de **données / flag / compte non garanti par le seed** → c'est le cas dominant → **handoff `kp-developer`** (cf. `kp-test-data-isolation`). Tu ne « débloques » jamais en touchant un seed toi-même.
- Sélecteur `data-cy` manquant côté app → **recommandation à `kp-developer`** (jamais posé par toi).

### Mapping clé ↔ test = 1:N

Une même clé peut être portée par plusieurs tests (un actif + un `test.fixme()`, ex. un wizard en étapes). Pour juger la couverture d'un **cas**, **agrège** ses tests : statut maximal `FAILED > PASSED > TODO` (même logique que la remontée). Un cas n'est « vert » que si tous ses tests le sont.

### Verdict (sortie du mode)

Produis un tableau des **6 critères** (✅ / ❌ / ⚠️) pour la cible, puis :
1. le **premier critère en écart** (l'ordre 1→6 est la séquence de résolution) ;
2. le **prochain pas** (quel mode charger, ou quel handoff) ;
3. en mode `auto`, **enchaîne** directement sur ce pas ; sinon, propose-le.

Annonce toujours le verdict en clair avant d'agir — l'utilisateur doit voir « où on en est » comme tu le vois.
