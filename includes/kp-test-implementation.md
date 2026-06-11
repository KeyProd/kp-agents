## Mode `implementation` — implémenter le test et la liaison (critères 2 + 3)

Garantit le **critère 2** (test code conforme) et le **critère 3** (liaison bidirectionnelle). Hérité de l'ancien agent E2E, paramétré par la config `testing`.

### Découverte (discovery) — locale uniquement

Pilote le navigateur via le MCP de découverte (`discovery.mcp`, ex. `playwright`) sur `discovery.base_url_local` — **jamais sur un remote**. Raison terrain : l'app peut rendre dans une langue différente en local vs distant (ex. keyprod : EN local, FR sur dev.inno) ; les sélecteurs/assertions doivent être relevés là où le test s'exécutera.

1. Naviguer vers l'écran cible, prendre le **snapshot d'accessibilité** (préféré au screenshot pour identifier les sélecteurs).
2. Jouer le parcours complet **avant** d'écrire le code, pour confirmer qu'il fonctionne.
3. Relever les ancres : `data-cy` en priorité, sinon rôle/label/texte exact.

**Mode dégradé** : si le MCP de découverte est indisponible (non chargé, app locale non démarrée) → rédige une **ébauche** sur la base de la story + `conventions_doc`, marque le test « à faire » (`test.fixme()`), consigne les ancres non confirmées (commentaire `DISCOVERY:`), et demande à l'utilisateur de démarrer la découverte pour finaliser. Ne jamais écrire un test « à l'aveugle » présenté comme validé.

### Conventions (lues depuis `conventions_doc`)

Lis `conventions_doc` au démarrage — c'est la source opposable. Règles dures usuelles (hérite de l'ancien E2E) :
- **Sélecteurs** : `data-cy` (ou équivalent stable) prioritaire. Bannis : `nth`, classes générées (Vuetify/MUI), chemins CSS profonds.
- **Strict mode** : un sélecteur ne matche qu'un élément. Pas de `.first()` de contournement.
- **Attentes** : web-first assertions auto-attendues (`await expect(locator).toBeVisible()`, `waitFor`). **Zéro `waitForTimeout()`/`sleep`** (cause n°1 de flakiness). Pas de `{ force: true }`.
- **Robustesse** : terminer un parcours sensible par une assertion d'absence d'erreur JS.
- **i18n** : forcer la locale au niveau du test si le framework le permet (ex. `test.use({ locale: 'fr-FR' })`) ; factoriser si bilingue.
- **Description** en langage métier (la langue du projet).

### Liaison bidirectionnelle (critère 3)

Deux canaux à maintenir **cohérents** :
1. **Côté test** : préfixe `<test_link_format>` dans la description du test (ex. `test('[KP-18190] le bouton…')`). C'est ce que la remontée regex (`<test_link_pattern>`).
2. **Côté cas** : la ligne `Automatisation : … <fichier>` de la description Xray pointe le bon fichier (cf. `kp-test-case-design`).

Vérifie les **deux sens** : un test sans préfixe = orphelin ; une description Xray pointant un mauvais fichier = liaison cassée silencieuse.

### Anti-faux-vert (garde de visibilité + juge LLM)

Deux contrôles obligatoires avant de déclarer le test conforme :
1. **Garde de visibilité** : avant d'asserter un comportement sur des données seedées (tri, filtre, présence), **assert d'abord que ces données sont réellement visibles** (ex. les N lignes seedées présentes dans le tableau). Sans cette garde, un scope/visibilité non satisfait rend la liste vide et l'assertion passe à tort (`[] === []`) — c'est le faux-vert n°1 (cf. `kp-test-data-isolation`, section visibilité).
2. **Juge LLM** : relis le test contre le cas — **« échoue-t-il réellement si le résultat attendu n'est pas atteint ? »**. Si non, il ne teste rien d'utile → recommence.

Note tri/ordre : sur une table contenant des données préexistantes non contrôlées, **restreins l'assertion d'ordre aux seules lignes seedées** (le collation backend diffère du tri JS sur des libellés arbitraires) ; et utilise une attente active (re-poll) car le DOM se réordonne en asynchrone.

**Pièges de faux-vert récurrents** (chacun a produit un test vert qui ne testait rien) :
1. **Message d'erreur** : n'assert JAMAIS un conteneur d'erreur générique « non vide » (classe de messages/erreur partagée). Elle matche aussi les **hints** et est évaluée **avant** la réponse backend → passe à tort. Assert le **texte exact** du message attendu (l'attente web-first synchronise sur la réponse serveur).
2. **Recherche puis présence** : après une recherche, assert que la liste est **filtrée à la seule ligne cible** (compte total == 1 **et** contenu attendu), pas qu'« une ligne correspondante existe » dans une liste non filtrée — sinon on ne prouve ni que la recherche marche ni que le résultat est visible.
3. **Recherche = sous-chaîne** : un libellé préfixe d'un autre fait matcher plusieurs lignes → garde de comptage par **regex ancré** (`^…$`).
4. **Précondition** : avant un test de création/restauration, assert que l'entité **n'existe pas** au départ — sinon on ne distingue pas « produit par l'action » de « déjà présent ».
5. **Effet persistant** : pour une action dont l'effet doit survivre (interrupteur, paramètre), **recharge la page** et ré-assert l'état — sinon on ne teste que l'optimistic UI, pas l'écriture réelle.
6. **UI asynchrone** (autocomplete/listbox/option téléportée) : attendre que l'option filtrée soit **stable et visible** avant le clic, et la fermeture de l'overlay avant l'action suivante (flake intermittent sinon).

Frontière de mock : un cas dont la mutation dépend d'un **service externe non mocké** (ex. provisioning d'identité type Cognito) n'est pas automatisable dans un harness mocké → `test.fixme` + commentaire `BLOCKER:`, plutôt qu'un test fragile ou faux-vert.

### Frontière

Tu écris **uniquement** dans `tests_dir`. Si un `data-cy` manque côté app, **recommande-le à `kp-developer`** (jamais posé par toi). L'isolation (seed/clean) relève du mode `data-isolation`.
