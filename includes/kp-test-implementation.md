## Mode `implementation` — implémenter le test et la liaison (critères 2 + 3)

Garantit le **critère 2** (test code conforme) et le **critère 3** (liaison bidirectionnelle). Hérité de l'ancien agent E2E, paramétré par la config `testing`.

### Découverte (discovery) — locale uniquement

Pilote le navigateur via le MCP de découverte (`discovery.mcp`, ex. `playwright`) sur `discovery.base_url_local` — **jamais sur un remote**. Raison terrain : l'app peut rendre dans une langue différente en local vs distant (ex. keyprod : EN local, FR sur dev.inno) ; les sélecteurs/assertions doivent être relevés là où le test s'exécutera.

1. Naviguer vers l'écran cible, prendre le **snapshot d'accessibilité** (préféré au screenshot pour identifier les sélecteurs).
2. Jouer le parcours complet **avant** d'écrire le code, pour confirmer qu'il fonctionne.
3. Relever les ancres : `data-cy` en priorité, sinon rôle/label/texte exact.

**Mode dégradé** : si le MCP de découverte est indisponible (non chargé, app locale non démarrée) → rédige une **ébauche** sur la base de la story + `conventions_doc`, marque le test « à faire » (`->todo()`), consigne les ancres non confirmées (commentaire `DISCOVERY:`), et demande à l'utilisateur de démarrer la découverte pour finaliser. Ne jamais écrire un test « à l'aveugle » présenté comme validé.

### Conventions (lues depuis `conventions_doc`)

Lis `conventions_doc` au démarrage — c'est la source opposable. Règles dures usuelles (hérite de l'ancien E2E) :
- **Sélecteurs** : `data-cy` (ou équivalent stable) prioritaire. Bannis : `nth`, classes générées (Vuetify/MUI), chemins CSS profonds.
- **Strict mode** : un sélecteur ne matche qu'un élément. Pas de `.first()` de contournement.
- **Attentes** : états auto-attendus (`assertSee`/`waitFor`). **Zéro `sleep()`** (cause n°1 de flakiness). Pas de `force:true`.
- **Robustesse** : terminer un parcours sensible par une assertion d'absence d'erreur JS.
- **i18n** : forcer la locale au niveau du test si le framework le permet (ex. `->withLocale('fr-FR')`) ; factoriser si bilingue.
- **Description** en langage métier (la langue du projet).

### Liaison bidirectionnelle (critère 3)

Deux canaux à maintenir **cohérents** :
1. **Côté test** : préfixe `<test_link_format>` dans la description du test (ex. `it("[KP-18190] le bouton…")`). C'est ce que la remontée regex (`<test_link_pattern>`).
2. **Côté cas** : la ligne `Automatisation : … <fichier>` de la description Xray pointe le bon fichier (cf. `kp-test-case-design`).

Vérifie les **deux sens** : un test sans préfixe = orphelin ; une description Xray pointant un mauvais fichier = liaison cassée silencieuse.

### Juge LLM (auto-contrôle, anti-faux-vert)

Avant de déclarer le test conforme, relis-le contre le cas : **« ce test échoue-t-il réellement si le résultat attendu du cas n'est pas atteint ? »**. Si la réponse est non (le test passe sans rien vérifier d'utile), il ne teste pas la bonne chose → recommence.

### Frontière

Tu écris **uniquement** dans `tests_dir`. Si un `data-cy` manque côté app, **recommande-le à `kp-developer`** (jamais posé par toi). L'isolation (seed/clean) relève du mode `data-isolation`.
