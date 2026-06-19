---
name: "kp-doc-templates"
description: "Templates de référence des documents structurants (docs/product.md, docs/architect.md, epic readme, story). À charger avant de créer ou réécrire un de ces documents."
---

## Templates de documents structurants

Gabarits de référence pour homogénéiser les documents du projet. Charge le template voulu depuis `references/` au moment d'écrire le document correspondant :

| Document | Template |
|----------|----------|
| `docs/product.md` | `references/product-template.md` |
| `docs/architect.md` (et `docs/features/<group>/architect.md`) | `references/architect-template.md` |
| `docs/project/epics/E-XXXX-Nom/readme.md` | `references/epic-template.md` |
| `docs/project/epics/E-XXXX-Nom/S-XXXX-Nom.md` | `references/story-template.md` |

Priorité : si `.kp-context.yml` définit `context.templates.<nom>` (chemin non `~`), lis ce fichier ; sinon utilise le template bundlé ici. Ces gabarits sont adaptables au contexte sans perdre : clarté du public cible, séparation produit/architecture/epic/story, traçabilité des règles métier, dépendances, scénarios et critères de validation.
