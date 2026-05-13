## Configuration des sources

La configuration des sources externes vit dans des **fichiers markdown** dans `docs/` à la racine du projet. Chaque fichier porte un **frontmatter YAML** sous la clé top-level `kp-agents:` qui contient la config machine-lisible. Absent ou clé absente = comportement par défaut (mode 100% local).

### Fichiers de configuration

| Fichier | Commit | Clés `kp-agents:` portées |
|---|---|---|
| `docs/git.md` | ✅ | `branch_pattern` |
| `docs/git.local.md` | ❌ gitignored | `auto_commit`, `auto_push` |
| `docs/project.md` | ✅ | `tickets.mode`, `tickets.mcp_server`, `tickets.project_key`, `tickets.mapping.*` |
| `docs/project.local.md` | ❌ gitignored | overrides `tickets.*` |
| `docs/documentation.md` | ✅ | `product.mode`, `product.access` |
| `docs/documentation.local.md` | ❌ gitignored | `product.path`, `global_doc.specs`, `global_doc.tech`, `global_doc.product_inputs` |

### Comportement au démarrage

1. Lire le frontmatter `kp-agents:` des fichiers `docs/*.md` listés ci-dessus si ils existent.
2. Pour chaque dimension activée en externe, vérifier les prérequis :
   - `product.mode: external` (dans `documentation.md`) → `product.path` (dans `documentation.local.md`) renseigné et accessible.
   - `global_doc.specs` ou `global_doc.tech` (dans `documentation.local.md`) → chemin accessible.
   - `tickets.mode: mcp` (dans `project.md`) → `mcp_server` et `project_key` renseignés.
3. Config incomplète ou chemin inaccessible → warn + proposer `/kp-agents:kp-setup` + continuer en mode local dégradé.

### Comment parser le frontmatter

Le frontmatter YAML est entre deux lignes `---` en tête de fichier. Exemple `docs/git.md` :

```markdown
---
kp-agents:
  branch_pattern: "feat/{slug}"
---

# Conventions Git du projet
...
```

Pour lire `branch_pattern`, lis le fichier `docs/git.md` et extrais la clé `kp-agents.branch_pattern` du frontmatter. **Ne jamais parser la prose du body** pour récupérer une config machine.

### Migration depuis `.kp-agents.yml` (v1.x)

Les anciens fichiers `.kp-agents.yml` et `.kp-agents.local.yml` ne sont **plus lus** depuis la v2.0.0. Si tu détectes leur présence à la racine du projet, signale-le à l'utilisateur et propose `/kp-agents:kp-setup` pour migrer automatiquement le contenu vers les nouveaux MD canoniques.

### Résolution de chemin pour la dimension `product`

Quand `product.mode: external` (dans `docs/documentation.md`) **et** `product.path` (dans `docs/documentation.local.md`) valide, les outputs suivants sont **redirigés vers `<product.path>/`** :

- `ideas/<theme>.md`
- `product.md`
- `features/<group>/product.md`
- `project/roadmap.md`

**Toujours écrits en local** : `docs/architect.md`, `docs/features/<group>/architect.md`, `docs/index.md`, toute doc technique. Les epics/stories suivent la dimension `tickets`.

Au premier write dans un sous-dossier externe, créer le sous-dossier à la volée (`mkdir -p`). Ne jamais demander confirmation pour ça.

Si un fichier existe à la fois localement et sur `<product.path>/<path>` : lire l'externe (source de vérité), écrire sur l'externe, warn une seule fois par session.

### Mode `product.access: read-only`

Quand `product.mode: external` **et** `product.access: read-only` : lire uniquement, ne jamais écrire — ni externe, ni fallback local. Rendre le contenu en chat :

> 🔒 **Mode produit read-only** — `<product.path>` en lecture seule. Je n'écris pas `<chemin relatif>`. Contenu ci-dessous pour copie manuelle. Pour autoriser l'écriture : `/kp-agents:kp-setup` → `product.access: read-write`.
>
> ```markdown
> <contenu rédigé>
> ```

Règles : refus absolu (pas de contournement). `access: read-only` ignoré si `mode: local`. Défaut `read-write` si omis. `product.access` et `tickets.mode` restent découplés.

### Écriture avec fallback local

Toute écriture sur source externe suit ce protocole :

1. Tenter l'écriture sur le chemin externe.
2. Échec → basculer sur `docs/` local en reproduisant **l'arborescence relative exacte** + warner explicitement.

> ⚠️ **Fallback d'écriture local** — impossible d'écrire sur `<chemin externe>` (raison : `<raison>`). Fichier écrit dans `<chemin local>`. `<conseil>`

| Cause | Signal | Conseil |
|---|---|---|
| Path inaccessible | chemin inexistant | Vérifier que OneDrive est monté. Sinon `/kp-agents:kp-setup` pour corriger le chemin. |
| Permission refusée | EACCES | Vérifier droits auprès du propriétaire. Config valide, pas besoin de `/kp-agents:kp-setup`. |
| Erreur transitoire | ENOSPC, EIO, timeout | Réessayer après vérification espace disque et connexion. |

Warn à chaque fallback (pas de dédoublonnage). Au démarrage : si `product.path` inaccessible dès le début → warn global + mode local dégradé pour toute la session.

### Documentation globale partagée (`global_doc`)

Répertoires partagés complémentaires à `docs/` — clés dans le frontmatter de `docs/documentation.local.md`. Les fichiers locaux **restent toujours écrits** — le global est un complément, jamais une substitution.

| Clé | Propriétaire écriture | Lecture | Règle pour les autres agents |
|---|---|---|---|
| `global_doc.specs` | `documentation` | tous | Écriture interdite → suggérer : « Veux-tu passer le relais à `/kp-agents:kp-documentation` ? » |
| `global_doc.tech` | `architect` | tous | Écriture interdite → suggérer : « Veux-tu passer le relais à `/kp-agents:kp-architect` ? » |
| `global_doc.product_inputs` | **personne** | tous | Jamais modifiable par un agent. Maintenu par un humain (PM). |

`global_doc.product_inputs` ≠ `product.path` : `.path` = destination des outputs de `product` ; `product_inputs` = source d'inputs du PM humain. Peuvent coexister et pointer différents dossiers.

**Lecture** : ne pas lire `global_doc` automatiquement au démarrage. Uniquement sur demande explicite ou quand le contexte global apporte clairement de la valeur — **suggérer avant de lire** :
> « Cette question semble bénéficier d'un contexte global. Veux-tu que je consulte `<chemin>` avant de répondre ? »

**Écriture** : uniquement par l'agent propriétaire, sur demande explicite. Processus : lire le fichier cible → proposer le contenu → attendre confirmation → écrire.

Si chemin `global_doc` inaccessible : warn une seule fois, poursuivre normalement.
> ⚠️ **Documentation globale inaccessible** — `<chemin>` (`global_doc.<clé>`) introuvable. Documentation locale utilisée. Vérifier le chemin ou `/kp-agents:kp-setup`.

### Redirection vers `/kp-agents:kp-setup`

Si config requise absente, incomplète ou incohérente, proposer `/kp-agents:kp-setup`. Suggestion, jamais un blocage.
