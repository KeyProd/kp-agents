---
kp-agents:
  product:
    mode: local
---

# Sources de documentation

> Fichier commité — politique des sources de doc partagée par l'équipe. Les chemins absolus (machine-spécifiques) vont dans `documentation.local.md`.

## Configuration machine-lisible

Schéma frontmatter complet :

```yaml
kp-agents:
  product:
    mode: local | external      # défaut: local
    access: read-write | read-only   # si mode: external, défaut: read-write
```

### Modes de la doc produit

- **`local`** (défaut) — La doc produit (`product.md`, roadmap, ideas, features/<g>/product.md) est écrite localement dans `docs/`.
- **`external`** — La doc produit vit hors du repo (ex: OneDrive partagé du PM). Le chemin absolu est dans `documentation.local.md` (machine-spécifique).
  - `access: read-write` (défaut) — Les agents peuvent écrire sur le chemin externe.
  - `access: read-only` — Les agents lisent uniquement, ne touchent pas. Utile quand un PM humain maintient la doc ailleurs.

## Sources externes consommées

<!-- Décrire ici les sources de documentation externes que l'équipe consulte régulièrement. Les chemins absolus locaux sont dans documentation.local.md. -->

| Source | Type | Propriétaire | Détail |
|---|---|---|---|
| <!-- ex: Wiki Spécifications --> | <!-- specs validées --> | <!-- équipe Documentation --> | <!-- voir `documentation.local.md` clé `global_doc.specs` --> |
| <!-- ex: Doc Tech globale --> | <!-- architecture cross-projets --> | <!-- équipe Architect --> | <!-- voir `documentation.local.md` clé `global_doc.tech` --> |
| <!-- ex: Inputs PM --> | <!-- vision, brief, personas --> | <!-- PM humain (lecture seule) --> | <!-- voir `documentation.local.md` clé `global_doc.product_inputs` --> |

## Comportement des agents

- **`global_doc.specs`** — Maintenu par l'agent `documentation`. Lu par `architect`, `developer`, `review`, `product`. Écriture interdite pour les autres → ils suggèrent un relais vers `/kp-agents:documentation`.
- **`global_doc.tech`** — Maintenu par l'agent `architect`. Lu par `developer`, `review`, `documentation`, `product`. Écriture interdite pour les autres.
- **`global_doc.product_inputs`** — **Jamais modifiable par un agent**. Maintenu par un humain (PM). Lecture seule pour tous.

**Lecture des sources externes** : pas automatique au démarrage. Uniquement sur demande explicite ou quand le contexte global apporte clairement de la valeur — suggérer avant de lire.

**Écriture** (specs, tech) : uniquement par l'agent propriétaire, sur demande explicite. Processus : lire le fichier cible → proposer le contenu → attendre confirmation → écrire.
