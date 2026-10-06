## Mode `case-design` — concevoir, créer et ranger le cas (critère 1)

Garantit le **critère 1** : un cas existe dans le référentiel (`case_repository`), **rangé sous `root_folder`**, au gabarit, labellisé. Hérité de l'ancien agent Xray, paramétré par la config `testing`.

### Double canal (cf. ADR-008)

| Besoin | Canal | Outils |
|--------|-------|--------|
| Lire / auditer / chercher un cas | **MCP** (`case_repository.mcp_server`, hérite de `tickets.mcp_server` si absent) | `getJiraIssue`, `searchJiraIssuesUsingJql` |
| Vérifier le rangement sous `root_folder` | **API GraphQL** (`graphql_endpoint`) | `getFolder` / `getTests` |
| Créer + ranger (atomique) | **API GraphQL** | `authenticate` → `createTest(testType, folderPath, jira)` |

**Pilotage GraphQL** : pas de helper pérenne dans le socle → tu pilotes l'API en direct via un script Node ad-hoc. Auth : `POST <graphql_endpoint>/authenticate` avec `client_id`/`client_secret` lus depuis `case_repository.credentials_env` (ex. keyprod : `XRAY_CLIENT_ID`/`XRAY_CLIENT_SECRET` dans `apps/kpweb/.env.testing`). **Jamais** de secret en clair dans le chat, un fichier versionné ou un commit.

### Prérequis (bloque si absent)

Le rangement étant **bloquant**, vérifie au démarrage : `credentials_env` présent + auth GraphQL OK. Si KO → signale le prérequis, propose `/kp-agents:kp-setup`, et **ne déclare jamais le critère 1 satisfait sans rangement vérifié**.

### Gabarit de description (au format projet)

Le summary suit `Module > comportement` (ex. « Auth > Connexion réussie », « Événements > Bouton Enregistrer désactivé sans cause »). La description suit un gabarit régulier — sur keyprod :

```
**Persona** : <persona>
**Écran(s)** : <route(s)>
**Préconditions**
* <préconditions>
**Étapes**
1. <action>
2. …
**Résultat attendu**
* <résultat observable>
**Automatisation** : <framework> — <chemin du fichier de test>
**Cadre** : voir <conventions_doc>
```

Les étapes vivent **en prose dans la description** (pas en steps natifs Xray). **Gotcha** : le champ `data` des steps natifs est désactivé côté projet → ne jamais l'envoyer.

### Procédure

1. **Cadrer** le cas (parcours, préconditions, résultat observable, story d'origine si fournie).
2. **Vérifier l'existant** (`searchJiraIssuesUsingJql` sur summary proche) — le référentiel **ne déduplique pas**, ne crée jamais de doublon ; enrichis l'existant le cas échéant.
3. **Choisir le dossier** sous `root_folder` (jamais ailleurs) ; le créer si absent (idempotent).
4. **Proposer** summary + description (gabarit) + folder cible, **et attendre la confirmation explicite** (création = effet de bord externe — décision Q3). Jamais de création silencieuse.
5. **Créer + ranger** via `createTest(testType: Manual, folderPath, jira: { fields: { project, summary, description, labels: [<case_label>] } })`.
6. **Vérifier** le rangement (`getFolder`) et récupérer la clé.
7. **Sous-critère non bloquant** : lier à la story (lien JIRA natif) si une story d'origine existe — sinon **warn**, jamais bloquant (le référentiel actuel a souvent `issuelinks: []`).

### Périmètre dur

Écriture **uniquement** sous `root_folder` (lecture des autres racines tolérée pour s'inspirer). Tu n'écris jamais dans le code applicatif ni dans `tests_dir` ici — c'est le mode `implementation`.
