## Configuration de la dimension `documentation`

Cette dimension regroupe **deux sous-dimensions** :
- **`product`** — où vivent les outputs produit (mode local/external, accès)
- **`global_doc`** — répertoires de documentation partagée (specs, tech, product_inputs)

Elle écrit dans **deux fichiers** :
- `docs/documentation.md` (commité) — politique projet (`product.mode`, `product.access`)
- `docs/documentation.local.md` (gitignored) — chemins absolus machine-spécifiques (`product.path`, `global_doc.*`)

### Sous-dimension `product`

#### Questions à poser

1. **Mode** ? `local` (défaut, dans `docs/`) ou `external` (chemin absolu, ex: OneDrive).
2. Si `external` → **chemin absolu** du dossier. Présence d'espaces ou caractères spéciaux acceptée (ex: `Library/CloudStorage/OneDrive - Entity/`).
3. Si `external` → **accès** ? `read-write` (défaut, agents peuvent écrire) ou `read-only` (PM humain maintient ailleurs, agents lisent uniquement).

   Formuler ainsi :
   > La doc produit externe sera-t-elle **modifiable par les agents** (`read-write`, défaut) ou **en lecture seule** (`read-only`) ? Le mode `read-only` convient quand un PM humain maintient la doc ailleurs : les agents la lisent comme source de vérité mais n'y touchent jamais. Les epics et stories restent créables indépendamment via la dimension `tickets`.

#### Validation d'accessibilité (si mode external)

Tente une lecture du `product.path` (ex: `Read` sur un fichier factice ou listing). Si échec :
- Option (a) : corriger le chemin
- Option (b) : enregistrer quand même, mode dégradé (warn à chaque démarrage d'agent)
- Option (c) : annuler le setup

### Sous-dimension `global_doc`

Trois sous-clés indépendantes — répertoires de documentation partagée complémentaires à `docs/`. **Toujours dans `docs/documentation.local.md`** (jamais dans `documentation.md`) car machine-spécifiques.

#### Questions à poser (par sous-clé)

**`global_doc.product_inputs`** — inputs produit rédigés par le PM (vision, brief, personas, cahier des charges…).
> Souhaites-tu indiquer où se trouvent les inputs produit du PM ? Ce dossier sera lu en contexte par tous les agents mais **jamais modifié** — c'est la source d'inputs humains, pas un output des agents.
- Si oui → chemin absolu.

**`global_doc.specs`** — doc fonctionnelle de ce qui est implémenté (specs validées).
> Souhaites-tu configurer un répertoire de specs globales ? Ce dossier sera maintenu par l'agent `documentation` et lu en contexte par `architect`, `developer`, `review` et `product`. La doc locale dans `docs/` reste toujours maintenue en parallèle.
- Si oui → chemin absolu (structure libre, l'agent s'adapte).

**`global_doc.tech`** — documentation technique globale (architecture, patterns cross-projets).
> Souhaites-tu configurer un répertoire de doc technique globale ? Ce dossier sera maintenu par l'agent `architect` et lu en contexte par `developer`, `review`, `documentation` et `product`. La doc locale dans `docs/` reste toujours maintenue en parallèle.
- Si oui → chemin absolu (structure libre, l'agent s'adapte).

#### Règles fixes (global_doc)

- **Pas d'option `access`** — ni `read-only`, ni `read-write`. La règle d'écriture est figée dans le comportement des agents (agent propriétaire + demande explicite pour `specs` et `tech` ; lecture seule absolue pour `product_inputs`).
- **Les trois chemins sont indépendants** — on peut configurer un, deux ou les trois.

#### Validation d'accessibilité (global_doc)

Pour chaque chemin renseigné, tente une lecture. Si échec :
- Option (a) : corriger le chemin
- Option (b) : enregistrer quand même, warn à chaque démarrage d'agent concerné
- Option (c) : annuler

### Écriture dans `docs/documentation.md` (commité)

Frontmatter :

```markdown
---
kp-agents:
  product:
    mode: local | external
    access: read-write | read-only   # uniquement si mode: external et non-défaut
---
```

`access` n'est écrit que s'il vaut explicitement `read-only` (ou si l'utilisateur l'a explicité même à `read-write`). Le body humain liste les sources externes consommées avec leurs propriétaires. Si le fichier n'existe pas, bootstrap depuis ``references/template-documentation.md`` et compléter le body avec les sources renseignées par l'utilisateur.

### Écriture dans `docs/documentation.local.md` (gitignored)

Frontmatter :

```markdown
---
kp-agents:
  product:
    path: "<chemin absolu>"          # uniquement si mode: external
  global_doc:
    product_inputs: "<chemin absolu>"   # uniquement si configuré
    specs: "<chemin absolu>"            # uniquement si configuré
    tech: "<chemin absolu>"             # uniquement si configuré
---
```

Présence d'une clé = chemin actif. Absence = pas de doc globale pour cette dimension.

Si le fichier n'existe pas, bootstrap depuis ``references/template-documentation-local.md``.

Vérifier que `docs/documentation.local.md` figure dans `.gitignore` (pattern `docs/*.local.md` accepté).

### Cas limites

- **`access` omis ou absent** → ne pas écrire le champ (laisser les agents appliquer le défaut `read-write`). N'écris le champ que s'il vaut explicitement `read-only`, ou si l'utilisateur l'a explicité même à `read-write`.
- **`access` en mode local** → inutile, ne jamais le proposer ni l'écrire. Si déjà présent dans un `docs/documentation.md` existant lors d'une modification, warn (« champ ignoré en mode local ») et propose de le retirer.
- **`global_doc` toujours dans `documentation.local.md`** — ne jamais proposer d'écrire `global_doc` dans `documentation.md`, même si l'utilisateur le demande. Les chemins sont machine-spécifiques par nature.
- **Chemins partagés entre plusieurs projets** → c'est intentionnel, c'est le cas d'usage principal (wiki d'équipe, dossier PM partagé). Ne pas en déduire une erreur de configuration.
- **`global_doc.product_inputs` ≠ `product.path`** → si confusion : `product.path` est où `product` écrit ses outputs (roadmap, product.md…) ; `product_inputs` est où le PM écrit ses inputs (brief, vision…). Les deux peuvent coexister ou pointer vers le même dossier — choix projet.
- **Fichier `docs/documentation.md` édité manuellement** → diff sur frontmatter, demander confirmation, **préserver le body**.
