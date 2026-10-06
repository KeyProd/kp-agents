## Template recommandé — `docs/features/<group>/ux.md`

Objectif : personas, parcours et décisions UX d'une feature. Pas de design avant de savoir pour qui.

```markdown
---
title: UX — <feature group>
date: <YYYY-MM-DD>
status: draft
author: ux-ui-agent
---

# UX — <feature group>

## Personas
### Persona : <Nom>
- **Rôle** : …
- **Contexte d'usage** : device, fréquence, environnement
- **Objectif principal** : …
- **Frustrations actuelles** : …
- **Niveau technique** : novice | intermédiaire | expert
- **Ce qui compte le plus** : rapidité | clarté | contrôle | esthétique | …

## Parcours utilisateur
- **Happy path** : étapes numérotées (≤ 5 pour une action courante)
- **Points de friction** : …
- **Cas limites** : premier usage, état vide, erreur, données volumineuses

## Propositions UX (par écran)
- **Layout** : zones, hiérarchie de l'information
- **Interactions** : clic / swipe / raccourci / drag…
- **Feedback** : loading, succès, erreur, transition
- **Accessibilité** : contraste, clavier, cibles tactiles, labels

## Wireframes
(ASCII ou descriptions structurées — données réalistes, pas de lorem ipsum)

## Décisions UX
- … (chaque décision justifiée : persona / contrainte, pas « parce que c'est mieux »)
```
