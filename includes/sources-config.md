## Configuration des sources

Ce projet peut pointer vers des sources externes (doc produit OneDrive, tickets externalisés via MCP) via deux fichiers optionnels à la racine du projet. En leur absence, **tous les outputs vont dans `docs/` local** (comportement par défaut, inchangé).

### Fichier `.kp-agents.yml` (commité) — politique de sources

```yaml
product:
  mode: local | external      # défaut: local
  access: read-write | read-only   # défaut: read-write, ignoré si mode: local
tickets:
  mode: local | mcp           # défaut: local
  mcp_server: <nom>           # requis si mode: mcp
  project_key: <clé>          # requis si mode: mcp
  mapping:                    # optionnel, pertinent si mode: mcp — voir section dédiée pour les défauts
    summary_prefix: <string>
    issue_type_story: Story
    issue_type_epic: Epic
    status:
      TODO: "À faire"
      IN_PROGRESS: "En cours"
      REVIEW: "Examiner"
      DONE: "Terminé(e)"
    labels: [kp-agents]
    label_patterns:
      story_id: "kp-story-{id}"
      epic_id: "kp-epic-{id}"
      author: "kp-author-{name}"
      status: "kp-status-{value}"
    custom_fields: {}
    review_placement: description   # ou "comment"
git:                            # optionnel, préférences projet pour opérations git
  branch_pattern: <string>      # défaut: non renseigné. Ex: "feat/{slug}" ou "feature/{ticket}-{slug}"
  auto_commit: yes | no | ask   # défaut: ask
  auto_push: yes | no | ask     # défaut: no
```

### Fichier `.kp-agents.local.yml` (gitignoré) — chemins machine-spécifiques

```yaml
product:
  path: <chemin absolu>       # requis si product.mode: external
```

### Comportement au démarrage

1. **Lire** `.kp-agents.yml` via Read. S'il est absent → mode 100% local, aucune vérification supplémentaire.
2. **Pour chaque dimension activée en externe**, vérifier les prérequis :
   - `product.mode: external` → `.kp-agents.local.yml` présent et `product.path` renseigné et accessible en lecture.
   - `tickets.mode: mcp` → `mcp_server` et `project_key` renseignés dans `.kp-agents.yml`.
3. **Si config incomplète ou chemin inaccessible** → warn l'utilisateur, proposer `/kp-agents:setup` pour corriger, et continuer en mode local dégradé pour la session.

### Résolution de chemin pour la dimension `product`

Quand `product.mode: external` est actif et le chemin est valide, les outputs suivants sont **redirigés vers `<product.path>/`** au lieu de `docs/` local :

- `ideas/<theme>.md`
- `product.md`
- `features/<group>/product.md`
- `project/roadmap.md`

**Toujours écrits en local** quelle que soit la config, car relevant du périmètre technique ou de l'index local du repo : `docs/architect.md`, `docs/features/<group>/architect.md`, `docs/INDEX.md`, toute doc technique. Les epics (`project/epics/E-XXXX-*/readme.md`) et stories (`S-XXXX-*.md`) suivent la dimension `tickets` (voir ci-dessous).

#### Création implicite de sous-dossiers

Au premier write dans un sous-dossier du chemin externe (`<product.path>/ideas/`, `<product.path>/features/<group>/`, `<product.path>/project/`), créer le sous-dossier à la volée si absent (équivalent `mkdir -p`). Ne jamais prompter l'utilisateur pour confirmer la création d'un sous-dossier attendu par la convention.

#### Résolution de conflit local + externe

Si un fichier existe **à la fois** localement (`./docs/<path>`) et sur `<product.path>/<path>` (cas typique : mode externe activé sur un projet qui avait une doc locale existante) :
- **Lecture** : privilégier le fichier externe (source de vérité en mode `product.mode: external`).
- **Écriture** : écrire sur l'externe ; ne pas toucher au fichier local.
- **Warn** une seule fois par session, à la première détection : « Fichier dupliqué détecté entre `./docs/<path>` et `<product.path>/<path>`. Le externe fait foi. Envisage de supprimer la copie locale pour éviter toute confusion future. »

### Mode `product.access: read-only` (doc produit externe figée)

Quand `product.mode: external` **et** `product.access: read-only`, la doc produit externe est consommée comme **source de vérité figée** : les agents la **lisent** mais n'y écrivent **jamais** — ni sur le chemin externe, ni en fallback local. Cas d'usage typique : OneDrive partagé maintenu par un PM humain, agents en consommation.

#### Matrice comportementale par output

| Output | `mode: local` | `external` + `read-write` | `external` + `read-only` |
|---|---|---|---|
| `product.md` | écrit local | écrit externe | **refus, contenu rendu en chat** |
| `ideas/*.md` | écrit local | écrit externe | **refus, contenu rendu en chat** |
| `features/<g>/product.md` | écrit local | écrit externe | **refus, contenu rendu en chat** |
| `project/roadmap.md` | écrit local | écrit externe | **refus, contenu rendu en chat** |
| Epics / stories | suit `tickets.mode` | suit `tickets.mode` | suit `tickets.mode` (indépendant) |
| Lecture de tous les outputs ci-dessus | local | externe | **externe (lecture autorisée)** |

Agents concernés par le refus d'écriture en read-only : `product` et `brainstorm`. Les autres agents (`architect`, `developer`, `review`, `documentation`, `ux-ui`) n'écrivent pas sur la dimension produit et ne sont donc pas affectés.

#### Format standardisé du refus read-only

Utiliser ce format exact (avec l'emoji cadenas pour distinguer du warn de fallback technique) :

> 🔒 **Mode produit read-only** — la doc produit externe (`<product.path>`) est configurée en lecture seule. Je n'écris pas `<chemin relatif>`. Contenu proposé conservé ci-dessous pour copie manuelle. Pour autoriser l'écriture : `/kp-agents:setup` puis bascule `product.access: read-write`.
>
> ```markdown
> <contenu complet rédigé par l'agent>
> ```

Le contenu rédigé est **toujours rendu en chat** en bloc markdown — l'utilisateur ne perd jamais le travail de l'agent, il décide lui-même où le coller.

#### Règles spécifiques

- Le refus d'écriture est **absolu** en read-only : pas de fallback local, pas de contournement « écris quand même ». Si l'utilisateur insiste, redirige vers `/kp-agents:setup`.
- `access: read-only` est **ignoré** si `mode: local` (warn au démarrage, pas de blocage).
- `access` par défaut à `read-write` si omis (rétro-compatibilité).
- Les dimensions `product.access` et `tickets.mode` restent **découplées** : un projet peut très bien avoir `product.access: read-only` + `tickets.mode: local` (ou `mcp`) — les epics et stories sont créées normalement.

### Mode `tickets.mode: mcp`

Quand `tickets.mode: mcp` est actif, les epics et stories sont créées / lues / mises à jour via les outils MCP du serveur `mcp_server` dans le projet `project_key`. Aucun fichier `E-XXXX-*/readme.md` ni `S-XXXX-*.md` n'est créé localement pour ces tickets. L'utilisateur doit avoir configuré le serveur MCP correspondant dans ses `settings.json` Claude Code — l'agent ne configure pas le MCP lui-même.

#### Override local via `.kp-agents.local.yml`

Un développeur peut surcharger `tickets.project_key` (et uniquement ce champ en pratique) dans son `.kp-agents.local.yml` pour envoyer les tickets dans **son** projet de test sans toucher la config partagée :

```yaml
# .kp-agents.local.yml
tickets:
  project_key: TODO    # override du KP partagé
```

Règle de merge : `.kp-agents.local.yml` surcharge `.kp-agents.yml` **champ par champ** (deep merge par dimension). Les champs absents du local héritent du partagé. Ne jamais override `mode` ou `mapping` en local sauf cas très ciblé — ça casserait la cohérence d'équipe.

#### Schéma `tickets.mapping`

Le mapping gouverne **comment** une story markdown est transcodée en ticket JIRA (et inversement). Le bloc YAML de la section « Fichier `.kp-agents.yml` » en tête de document en donne la forme complète. Sémantique champ par champ :

| Champ | Type | Défaut | Rôle |
|---|---|---|---|
| `summary_prefix` | string | `""` | Préfixe ajouté au début de chaque `summary` JIRA (ex: `[KP]`). Utile pour isoler les tickets kp-agents dans un projet partagé. |
| `issue_type_story` | string | `"Story"` | Nom du issue type utilisé pour les stories. Peut être `"User Story"` selon projet. |
| `issue_type_epic` | string | `"Epic"` | Nom du issue type utilisé pour les epics. Peut être `"Initiative"` ou `"Feature"` selon projet. |
| `status.TODO` / `IN_PROGRESS` / `REVIEW` / `DONE` | string | voir bloc YAML | Noms **exacts** des statuts workflow JIRA correspondants. Variable par projet (localisation + custom). |
| `labels` | array<string> | `["kp-agents"]` | Labels systématiquement ajoutés à tout ticket créé par un agent. |
| `label_patterns.story_id` | string | `"kp-story-{id}"` | Pattern pour encoder l'ID story kp-agents en label JIRA (ex: `S-0009` → `kp-story-S0009`). `{id}` sans tiret par convention (labels JIRA n'aiment pas les tirets dans certaines versions). |
| `label_patterns.epic_id` | string | `"kp-epic-{id}"` | Idem pour l'ID epic. |
| `label_patterns.author` | string | `"kp-author-{name}"` | Idem pour l'auteur (nom d'agent). |
| `label_patterns.status` | string | `"kp-status-{value}"` | Label redondant avec le workflow JIRA, mais utile pour retrouver les tickets en JQL par statut conceptuel. |
| `custom_fields` | object | `{}` | Clé-valeur de customfield_XXXXX à injecter à la création. Réservé aux projets exigeant Story Points / Sprint / etc. |
| `review_placement` | `description` \| `comment` | `"description"` | Où l'agent `review` écrit la section `## Review` : directement dans la description du ticket (append) ou comme commentaire JIRA dédié. Choix projet, pas imposé. |

#### Pipeline d'écriture (create epic ou story)

Suivi par `product`, `developer`, `review`, selon l'opération :

1. **Extraire le frontmatter** du markdown source (si agent a composé localement un brouillon) : `story-id`, `epic-id`, `status`, `author`, `title`, etc.
2. **Composer le `summary`** : `<mapping.summary_prefix><space><titre ou user story abrégée>` — 255 chars max côté JIRA, tronquer proprement avec `…` si besoin.
3. **Composer la `description`** : **body markdown uniquement**, sans frontmatter YAML (qui serait cassé par JIRA, voir rapport spike). Inclure explicitement le `contentFormat: markdown` à l'appel MCP si l'outil le supporte.
4. **Composer les `labels`** : union de `mapping.labels` + labels dérivés via `mapping.label_patterns` (un par `story_id`, `epic_id`, `author`, `status`). Convention : ne jamais laisser de `-` dans `{id}` (utiliser `S0009`, pas `S-0009`).
5. **Composer le `parent`** (pour une story) : clé JIRA de l'epic parente (ex: `KP-42`) — l'agent doit l'avoir obtenu au préalable via recherche ou argument utilisateur.
6. **Appeler `createJiraIssue`** avec `projectKey`, `issueTypeName` (`mapping.issue_type_story` ou `mapping.issue_type_epic`), `summary`, `description`, `parent`, et `additional_fields: { labels, ...custom_fields }`.
7. **Transitionner** si le statut visé n'est pas l'initial `TODO` : récupérer les transitions via `getTransitionsForJiraIssue`, trouver celle dont `to.name === mapping.status[<cible>]`, appeler `transitionJiraIssue`.
8. **Afficher** la clé JIRA + URL au format standardisé (voir ci-dessous).

#### Pipeline de lecture (récupérer une story/epic existante)

1. Appeler `getJiraIssue` avec `responseContentFormat: markdown` (fidélité suffisante mesurée au spike S-0005). Si plus tard ADF s'avère nécessaire, évaluer.
2. **Reconstruire le frontmatter** en chat ou en rendu markdown (pas de persistance disque en mode mcp) :
   - `title` ← `summary` (sans le `summary_prefix`)
   - `status` ← déduit du `status.name` JIRA via reverse-lookup dans `mapping.status` (ex: `Examiner` → `REVIEW`). Si aucune correspondance, fallback `status: UNKNOWN` + warn.
   - `story-id`, `epic-id`, `author` ← extraits des labels via les patterns inversés (`kp-story-S0009` → `S-0009`).
   - `date` ← `created` natif JIRA.
3. **Afficher** la story reconstruite à l'utilisateur sous forme markdown standard (frontmatter + body) — elle n'est **pas** persistée sur disque.

#### Mise à jour d'une story existante

- **Body** : appeler `editJiraIssue` avec `fields: { description: <nouveau markdown sans frontmatter> }`. Toujours **relire** d'abord la description actuelle pour préserver les sections rédigées hors agent (PM qui a ajouté un commentaire, par exemple — à laisser si détecté).
- **Statut** : `transitionJiraIssue` avec l'ID de transition vers `mapping.status[<nouvelle cible>]`. Si aucune transition disponible vers la cible, warn explicite.
- **Labels** : pour un changement de statut, `editJiraIssue` avec `fields: { labels: [...anciens sauf kp-status-*, nouveau kp-status-<cible>] }` si `label_patterns.status` est utilisé. Sinon, la transition de statut suffit.

#### Affichage standardisé des liens JIRA

Chaque fois qu'un agent a manipulé un ticket, il affiche dans sa réponse la référence complète. Format exact :

> **JIRA** : [`KP-42`](https://<site>.atlassian.net/browse/KP-42) — `<summary sans le prefix>` *(status: <Status>)*

L'URL est construite à partir de la ressource Atlassian (cloudId → hostname du site, récupéré une fois par session via `getAccessibleAtlassianResources`). En cas d'URL indisponible, afficher la clé seule.

#### Gestion d'erreur MCP

Quand un appel MCP échoue (timeout, 401, 403, 500, outil non chargé, etc.), l'agent warn l'utilisateur et propose **3 options** sans bloquer :

> ⚠️ **Échec MCP JIRA** — l'opération `<nom opération>` sur `<issue>` a échoué (raison : `<raison courte>`).
>
> 1. **Réessayer** — je retente immédiatement la même opération.
> 2. **Bascule locale pour cette opération** — je crée/modifie en local `docs/project/epics/...` pour que tu puisses reprendre plus tard. La config reste `mode: mcp`, seul ce ticket est désynchronisé.
> 3. **Annuler** — aucune modification, on repart en arrière.
>
> Quelle option préfères-tu ?

Trois causes typiques à distinguer dans le « raison courte » :

| Cause | Signal technique | Conseil à glisser dans le warn |
|---|---|---|
| **MCP server non chargé / déconnecté** | Tool indisponible, erreur « tool not found » | « Vérifier que le MCP JIRA est activé dans la session Claude Code, ou invoquer `/kp-agents:setup` pour valider `mcp_server`. » |
| **Auth expirée** | 401 / 403 | « Reconnexion OAuth Atlassian nécessaire (via Claude Code settings). » |
| **Champ requis manquant** | 400 avec `errors.fieldName` | « Champ JIRA obligatoire absent (`<nom>`). Ajouter dans `tickets.mapping.custom_fields` via `/kp-agents:setup`. » |

#### Non-régression en mode `tickets.mode: local`

**Comportement inchangé** : si `tickets.mode` est absent ou vaut `local`, tout le pipeline ci-dessus est **désactivé**. Les agents créent/lisent `docs/project/epics/E-XXXX-*/readme.md` et `S-XXXX-*.md` exactement comme aujourd'hui. Le mapping, les labels et les transitions MCP ne sont jamais considérés en mode local.

#### Agents concernés

| Agent | Opérations en `tickets.mode: mcp` |
|---|---|
| `product` | Crée epic et stories (pipeline d'écriture, statut initial `TODO`). Lit une epic/story existante pour découpage. |
| `developer` | Transitionne story : `TODO → IN_PROGRESS` au démarrage, `IN_PROGRESS → REVIEW` ou `DONE` en fin. Met à jour la description (section `## Implémentation` + `## Validation par critère` intégrées au body). |
| `review` | Transitionne story : `REVIEW → DONE` (GO) ou `REVIEW → IN_PROGRESS` (NO-GO). Ajoute la section `## Review` soit dans la description (edit), soit en commentaire JIRA (si la politique projet le préfère — choix pris à `setup`, pas de défaut imposé, demander à la première utilisation). |
| `brainstorm`, `architect`, `documentation`, `ux-ui`, `setup` | Non concernés (ni création ni transition de ticket). `documentation` maintient `docs/INDEX.md` local, qui reste indépendant de `tickets.mode`. |

### Écriture avec fallback local

Toute écriture sur une source externe (chemin `product.path` ou serveur MCP) suit ce protocole :

1. Tenter l'écriture au chemin externe ou via l'outil MCP.
2. Si l'écriture échoue, **basculer sur `docs/` local** en reproduisant **l'arborescence relative exacte** (ex: échec sur `<product.path>/ideas/foo.md` → fallback sur `./docs/ideas/foo.md`, jamais à la racine), et **warner explicitement** l'utilisateur.

#### Format standardisé du warn de fallback

Utiliser ce format exact (avec l'emoji d'alerte pour visibilité maximale) :

> ⚠️ **Fallback d'écriture local** — impossible d'écrire sur `<chemin externe complet>` (raison : `<raison courte>`). Fichier écrit localement dans `<chemin local complet>`. <conseil de résolution>

Exemple concret :

> ⚠️ **Fallback d'écriture local** — impossible d'écrire sur `/Users/vincent/Library/CloudStorage/OneDrive-KeyProd/MonProjet/ideas/auth.md` (raison : Permission denied). Fichier écrit localement dans `./docs/ideas/auth.md`. Vérifier les droits sur le dossier OneDrive ou invoquer `/kp-agents:setup` pour changer de chemin.

#### Cas d'erreur distingués

Trois causes d'échec d'écriture externe à traiter différemment dans le warn :

| Cause | Signal technique | Conseil à formuler |
|---|---|---|
| **Path inaccessible** (OneDrive non monté, disque déplacé) | `product.path` n'existe pas ou est inaccessible au moment de l'écriture | « Source externe introuvable — vérifier que OneDrive est bien monté (ouvre Finder ou relance l'app OneDrive). Sinon, invoquer `/kp-agents:setup` pour corriger le chemin. » |
| **Permission refusée** (lecture seule pour l'utilisateur) | Erreur système `Permission denied` (EACCES) | « Droits insuffisants sur la source externe — vérifier auprès du propriétaire du OneDrive / dossier partagé. La config reste valide, pas besoin de lancer `/kp-agents:setup`. » |
| **Erreur d'écriture transitoire** (espace plein, I/O error, réseau) | `ENOSPC`, `EIO`, timeout | « Erreur d'écriture temporaire — réessayer après avoir vérifié l'espace disque et la connexion. » |

Le warn est émis **à chaque fallback** (pas de dédoublonnage), pour que l'utilisateur constate immédiatement où son fichier a réellement été écrit.

#### Détection au démarrage vs au write

- **Au démarrage** (lecture initiale de la config) : vérifier que `product.path` est lisible. Si `product.path` est inaccessible dès le démarrage → warn global + proposer `/kp-agents:setup` + poursuivre en **mode local dégradé** pour toute la session (plus de tentative externe, directement local).
- **Au write** (pendant la session, sur un chemin initialement validé) : fallback par opération avec warn standardisé.

### Préférences Git (`git:`)

Bloc optionnel de `.kp-agents.yml` qui régule le comportement des agents qui touchent git (`developer`, `review`). **Non-régression absolue** : si la clé `git:` est absente du fichier, les agents se comportent comme aujourd'hui (demande de confirmation avant commit/push, pas d'imposition de nom de branche).

#### Schéma et défauts

| Champ | Valeurs | Défaut | Rôle |
|---|---|---|---|
| `branch_pattern` | string avec placeholders | non renseigné | Template de nommage pour les branches feature créées par `developer`. Placeholders supportés : `{slug}` (nom de story kebab-case), `{ticket}` (clé JIRA si `tickets.mode: mcp`, sinon ID `S-XXXX`), `{epic}` (ID epic ou clé JIRA parent). Exemples : `feat/{slug}`, `feature/KP-{ticket}-{slug}`. Si non renseigné, l'agent demande le nom à l'utilisateur (comportement actuel). |
| `auto_commit` | `yes` / `no` / `ask` | `ask` | `yes` : commit sans demander après validation d'une story. `no` : ne commit jamais, annonce ce qui est prêt et laisse la main. `ask` : demande confirmation avant chaque commit (comportement actuel). |
| `auto_push` | `yes` / `no` / `ask` | `no` | Même sémantique que `auto_commit` mais pour `git push`. Défaut `no` : push est toujours une décision utilisateur explicite. |

#### Règles d'application

- **Priorité sur les règles de sécurité globales** : `auto_commit: yes` ou `auto_push: yes` **n'autorise jamais** le skip de hooks, de signature GPG, ou tout autre bypass documenté dans `CLAUDE.md`. La préférence projet accélère le flow « OK » ; elle ne débloque pas de contournements.
- **Échec silencieux interdit** : si un commit auto échoue (hook, signature, sandbox), l'agent **annonce explicitement** l'erreur et laisse la main. Ne jamais considérer `auto_commit: yes` comme un « fait au mieux silencieux ».
- **Validation du `branch_pattern`** : à l'écriture par `setup`, parser le pattern et vérifier qu'il ne contient pas d'accolade non fermée. Les placeholders inconnus (hors `{slug}`, `{ticket}`, `{epic}`) → warn à l'utilisateur mais accepter (il décide).
- **Préférences partielles** : un `.kp-agents.yml` avec seulement `git.branch_pattern` mais pas `auto_commit` → défaut `ask` appliqué sur le champ manquant, pas de blocage.
- **Dimension indépendante** : `git:` est découplée de `product:` et `tickets:`. Un projet peut très bien avoir `tickets.mode: mcp` + `git.auto_commit: no` (cas typique : tickets dans JIRA mais commit contrôlé à la main).

### Redirection vers `/kp-agents:setup`

Si, au cours d'une opération, la config requise est absente, incomplète ou incohérente, proposer à l'utilisateur l'invocation `/kp-agents:setup` pour corriger. La redirection est une **suggestion, jamais un blocage** — l'utilisateur peut toujours refuser et poursuivre manuellement.
