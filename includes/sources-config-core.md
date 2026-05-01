## Configuration des sources

Ce projet peut pointer vers des sources externes (doc produit OneDrive, répertoires de documentation globale partagée) via deux fichiers optionnels à la racine du projet. En leur absence, **tous les outputs vont dans `docs/` local** (comportement par défaut, inchangé).

> Cet agent ne gère pas les tickets (`tickets.mode: mcp`) ni les préférences git — ces dimensions sont réservées aux agents `product`, `developer`, `review` et `setup`.

### Fichier `.kp-agents.yml` (commité) — politique de sources

```yaml
product:
  mode: local | external      # défaut: local
  access: read-write | read-only   # défaut: read-write, ignoré si mode: local
global_doc:                     # optionnel, répertoires de documentation globale partagée
  specs: <chemin absolu>        # doc fonctionnelle de ce qui est implémenté (piloté par documentation)
  tech: <chemin absolu>         # documentation technique globale (piloté par architect)
```

### Fichier `.kp-agents.local.yml` (gitignoré) — chemins machine-spécifiques

```yaml
product:
  path: <chemin absolu>       # requis si product.mode: external
global_doc:
  specs: <chemin absolu>           # doc fonctionnelle de l'implémenté (propriétaire: documentation)
  tech: <chemin absolu>            # documentation technique globale (propriétaire: architect)
  product_inputs: <chemin absolu>  # inputs produit du PM — lecture seule pour tous les agents
```

### Comportement au démarrage

1. **Lire** `.kp-agents.yml` via Read. S'il est absent → mode 100% local, aucune vérification supplémentaire.
2. **Lire** `.kp-agents.local.yml` via Read (si présent) — contient les chemins machine-spécifiques.
3. **Pour chaque dimension activée en externe**, vérifier les prérequis :
   - `product.mode: external` → `.kp-agents.local.yml` présent et `product.path` renseigné et accessible en lecture.
   - `global_doc.specs` ou `global_doc.tech` renseigné → chemin accessible en lecture.
4. **Si config incomplète ou chemin inaccessible** → warn l'utilisateur, proposer `/kp-agents:setup` pour corriger, et continuer en mode local dégradé pour la session.

### Résolution de chemin pour la dimension `product`

Quand `product.mode: external` est actif et le chemin est valide, les outputs suivants sont **redirigés vers `<product.path>/`** au lieu de `docs/` local :

- `ideas/<theme>.md`
- `product.md`
- `features/<group>/product.md`
- `project/roadmap.md`

**Toujours écrits en local** : `docs/architect.md`, `docs/features/<group>/architect.md`, `docs/INDEX.md`, toute doc technique.

#### Création implicite de sous-dossiers

Au premier write dans un sous-dossier du chemin externe, créer le sous-dossier à la volée si absent (équivalent `mkdir -p`). Ne jamais prompter l'utilisateur pour confirmer.

#### Résolution de conflit local + externe

Si un fichier existe à la fois localement et sur `<product.path>/<path>` :
- **Lecture** : privilégier le fichier externe (source de vérité).
- **Écriture** : écrire sur l'externe ; ne pas toucher au fichier local.
- **Warn** une seule fois par session à la première détection.

### Mode `product.access: read-only`

Quand `product.mode: external` **et** `product.access: read-only`, ne **jamais** écrire sur le chemin externe ni en fallback local. Rendre le contenu en chat au format :

> 🔒 **Mode produit read-only** — la doc produit externe (`<product.path>`) est configurée en lecture seule. Je n'écris pas `<chemin relatif>`. Contenu proposé conservé ci-dessous pour copie manuelle.
>
> ```markdown
> <contenu complet rédigé par l'agent>
> ```

### Écriture avec fallback local

Toute écriture sur une source externe suit ce protocole :

1. Tenter l'écriture au chemin externe.
2. Si échec, **basculer sur `docs/` local** en reproduisant l'arborescence relative exacte, et **warner explicitement** l'utilisateur.

Format du warn :

> ⚠️ **Fallback d'écriture local** — impossible d'écrire sur `<chemin externe complet>` (raison : `<raison courte>`). Fichier écrit localement dans `<chemin local complet>`. <conseil de résolution>

### Documentation globale partagée (`global_doc`)

`global_doc` est un bloc optionnel de `.kp-agents.local.yml` qui définit des répertoires partagés complémentaires à `docs/`. Les fichiers locaux dans `docs/` **restent toujours écrits** — le global est un complément, jamais une substitution.

| Clé | Contenu | Agent propriétaire | Autres agents |
|-----|---------|-------------------|---------------|
| `global_doc.specs` | Documentation fonctionnelle de ce qui est implémenté | `documentation` | Lecture en contexte si pertinent ; écriture interdite |
| `global_doc.tech` | Documentation technique globale | `architect` | Lecture en contexte si pertinent ; écriture interdite |
| `global_doc.product_inputs` | Inputs produit du PM | Aucun — **lecture seule pour tous** | Lecture seule, sans exception |

#### Lecture du global : sur demande ou suggestion

Ne pas lire les chemins `global_doc` automatiquement au démarrage. Uniquement :
- Sur demande explicite de l'utilisateur
- Quand le contexte global apporte de la valeur — **suggérer avant de lire** :
  > « Cette question semble bénéficier d'un contexte global. Veux-tu que je consulte `<chemin>` avant de répondre ? »

#### Écriture : agent propriétaire + demande explicite uniquement

| Chemin | Seul autorisé à écrire |
|--------|------------------------|
| `global_doc.specs` | `documentation` |
| `global_doc.tech` | `architect` |
| `global_doc.product_inputs` | **Personne** |

Processus : lire le fichier cible → proposer le contenu → attendre confirmation explicite → écrire.

Si un chemin `global_doc` est inaccessible : warn une seule fois, poursuivre normalement.

> ⚠️ **Documentation globale inaccessible** — `<chemin>` (`global_doc.<clé>`) est configuré mais introuvable. La documentation locale est utilisée comme seule source.

### Redirection vers `/kp-agents:setup`

Si la config requise est absente, incomplète ou incohérente, proposer `/kp-agents:setup` pour corriger. Suggestion, jamais un blocage.
