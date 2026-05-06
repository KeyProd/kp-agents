## Configuration de la dimension `global_doc`

Trois sous-dimensions indépendantes — répertoires de documentation partagée complémentaires à `docs/`. **Toujours dans `.kp-agents.local.yml`** (jamais dans `.kp-agents.yml`) car machine-spécifiques.

### Questions à poser (par sous-dimension)

**`global_doc.product_inputs`** — inputs produit rédigés par le PM (vision, brief, personas, cahier des charges…).
> Souhaites-tu indiquer où se trouvent les inputs produit du PM ? Ce dossier sera lu en contexte par tous les agents mais **jamais modifié** — c'est la source d'inputs humains, pas un output des agents.
- Si oui → chemin absolu.

**`global_doc.specs`** — doc fonctionnelle de ce qui est implémenté (specs validées).
> Souhaites-tu configurer un répertoire de specs globales ? Ce dossier sera maintenu par l'agent `documentation` et lu en contexte par `architect`, `developer`, `review` et `product`. La doc locale dans `docs/` reste toujours maintenue en parallèle.
- Si oui → chemin absolu (structure libre, l'agent s'adapte).

**`global_doc.tech`** — documentation technique globale (architecture, patterns cross-projets).
> Souhaites-tu configurer un répertoire de doc technique globale ? Ce dossier sera maintenu par l'agent `architect` et lu en contexte par `developer`, `review`, `documentation` et `product`. La doc locale dans `docs/` reste toujours maintenue en parallèle.
- Si oui → chemin absolu (structure libre, l'agent s'adapte).

### Règles fixes

- **Pas d'option `access`** — ni `read-only`, ni `read-write`. La règle d'écriture est figée dans le comportement des agents (agent propriétaire + demande explicite pour `specs` et `tech` ; lecture seule absolue pour `product_inputs`).
- **Les trois chemins sont indépendants** — on peut configurer un, deux ou les trois.

### Validation d'accessibilité

Pour chaque chemin renseigné, tente une lecture. Si échec :
- Option (a) : corriger le chemin
- Option (b) : enregistrer quand même, warn à chaque démarrage d'agent concerné
- Option (c) : annuler

### Écriture dans `.kp-agents.local.yml`

```yaml
global_doc:
  product_inputs: <chemin absolu>
  specs:          <chemin absolu>
  tech:           <chemin absolu>
```

Présence d'une clé = chemin actif. Absence = pas de doc globale pour cette dimension.

### Cas limites

- **`global_doc` toujours dans `.kp-agents.local.yml`** — ne jamais proposer d'écrire `global_doc` dans `.kp-agents.yml`, même si l'utilisateur le demande. Les chemins sont machine-spécifiques par nature.
- **Chemins partagés entre plusieurs projets** → c'est intentionnel, c'est le cas d'usage principal (wiki d'équipe, dossier PM partagé). Ne pas en déduire une erreur de configuration.
- **`global_doc.product_inputs` ≠ `product.path`** → si confusion : `product.path` est où `product` écrit ses outputs (roadmap, product.md…) ; `product_inputs` est où le PM écrit ses inputs (brief, vision…). Les deux peuvent coexister ou pointer vers le même dossier — choix projet.
