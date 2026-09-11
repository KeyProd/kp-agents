## Template recommandé — `docs/features/<group>/ui.md`

Objectif : direction visuelle d'une feature, conforme à `docs/design-system.md`. Chaque choix justifié.

```markdown
---
title: UI — <feature group>
date: <YYYY-MM-DD>
status: draft
author: ux-ui-agent
---

# UI — <feature group>

## Principe directeur
Une phrase qui résume l'intention visuelle (ex : « précision chirurgicale », « chaleur artisanale »).

## Palette
| Rôle | Couleur | Justification |
|------|---------|---------------|
| Primaire | #… | … |
| Accent | #… | … |
| Neutre 1 / 2 | #… / #… | … |

## Typographie
- **Titres** : <font> — ton visé (ex : géométrique et technique)
- **Corps** : <font> — ton visé

## Composants signature
- 2-3 éléments UI différenciants (forme des boutons, style des cartes, micro-animations, iconographie…)

## Ce qu'on évite explicitement
- Patterns génériques écartés (Material / Bootstrap par défaut…) + pourquoi

## Design tokens
- Couleurs, espacements, rayons, ombres — conformes à `docs/design-system.md`

## États & breakpoints
- Specs détaillées pour le developer : voir la skill `kp-ux-ui` (procédure `uxui-dev-specs`)
```
