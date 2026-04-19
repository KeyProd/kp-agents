## Template recommandé - `docs/project/epics/E-XXXX-Nom-Simple/S-XXXX-Nom-Simple.md`

Objectif : document lisible par tous, mais suffisamment précis pour permettre une implémentation robuste et testable.

```markdown
---
title: [Titre]
date: YYYY-MM-DD
status: TODO | IN PROGRESS | REVIEW | DONE
author: product-agent
story-id: S-0001
epic-id: E-0001
---

# S-0001 - [Titre de la story]

## Résumé
[Description courte de la story]

## User Story
En tant que [persona], je veux [action] afin de [bénéfice].

## Contexte
- [contexte métier utile]
- [précondition ou dépendance]

## Règles métier
- [règle métier 1]
- [règle métier 2]

## Scénarios
### Nominal
- Étant donné [...]
- Quand [...]
- Alors [...]

### Alternatif
- Étant donné [...]
- Quand [...]
- Alors [...]

### Erreur / refus
- Étant donné [...]
- Quand [...]
- Alors [...]

## Cas limites
- [ ] état vide
- [ ] données invalides
- [ ] permissions / rôles
- [ ] doublons / idempotence
- [ ] limites de volumétrie ou seuils métier

## Critères d'acceptation
- [ ] Critère observable et testable
- [ ] Critère observable et testable
- [ ] Critère observable et testable

## Dépendances
- [story, epic, API, décision, composant]

## Notes techniques
- [contrainte technique]
- [point d'attention d'implémentation]

## Instrumentation / mesure
- [événement, KPI, log, métrique si pertinent]

## Questions ouvertes
- [question]

## Implémentation
- Fichiers créés / modifiés : [...]
- Commandes de test : [...]
- Notes de review : [...]

## Validation par critère
- **[Critère]** : [implémentation], [preuve/test], [limites]
```

### Principes de rédaction
- Écrire de manière lisible par tous
- Être suffisamment précis pour éviter l'interprétation implicite côté développement
- Couvrir au minimum le scénario nominal, un scénario alternatif et un cas d'erreur
- S'assurer que les critères d'acceptation sont directement vérifiables
