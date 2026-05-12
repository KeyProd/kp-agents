---
kp-agents:
  product: {}
  global_doc: {}
---

# Chemins locaux des sources de documentation

> **Fichier non commité** (gitignored). Chemins absolus machine-spécifiques — diffèrent d'un poste à l'autre, ne doivent pas être commités.

## Configuration machine-lisible

Schéma frontmatter complet :

```yaml
kp-agents:
  product:
    path: "<chemin absolu>"                # requis si product.mode: external dans documentation.md
  global_doc:
    specs: "<chemin absolu>"               # doc fonctionnelle (propriétaire: documentation)
    tech: "<chemin absolu>"                # doc technique globale (propriétaire: architect)
    product_inputs: "<chemin absolu>"      # inputs PM (lecture seule pour tous)
```

Présence d'une clé = chemin actif. Absence = pas de doc globale pour cette dimension.

### Exemples

```yaml
kp-agents:
  product:
    path: "/Users/jane/Library/CloudStorage/OneDrive - Acme/Product"
  global_doc:
    specs: "/Users/jane/Documents/wiki/specs"
    tech: "/Users/jane/Documents/wiki/tech"
    product_inputs: "/Users/jane/CloudStorage/OneDrive - Acme/PM Inputs"
```

## Règles

- Les **trois chemins `global_doc`** sont **toujours dans ce fichier**, jamais dans `documentation.md` — emplacements machine-spécifiques par nature.
- Les chemins peuvent être partagés entre plusieurs projets (wiki d'équipe, dossier PM partagé) — c'est intentionnel.
- Si un chemin devient inaccessible : warn une seule fois, l'agent continue en mode dégradé.

## Distinction `product.path` ≠ `global_doc.product_inputs`

- **`product.path`** — destination des **outputs** produits par l'agent `product` (roadmap, product.md…).
- **`global_doc.product_inputs`** — source d'**inputs** humains du PM (brief, vision, personas). Jamais modifiée par un agent.

Les deux peuvent coexister ou pointer vers le même dossier — choix projet.
