---
name: "kp-test-coverage-audit"
description: "Audit de couverture inter-cas E2E (lecture seule) : identifie les trous de couverture par axe et priorité."
---

## Mode `audit` — couverture inter-cas (lecture seule)

Vue d'ensemble de la cohérence référentiel ↔ code. **Aucun effet de bord** : ce mode diagnostique et propose, il ne crée/modifie/remonte rien.

### Ce qu'il détecte

| Anomalie | Méthode |
|----------|---------|
| **Test sans cas** (orphelin) | un test porte un préfixe `<test_link_pattern>` dont la clé n'existe pas / n'est pas un cas valide dans `case_repository` |
| **Test sans préfixe** | un test dans `tests_dir` ne porte aucun `<test_link_pattern>` → non remonté, non tracé |
| **Cas sans test** | un cas sous `root_folder` (label `<case_label>`) dont aucun test ne porte la clé |
| **Cas mal rangé** | un cas hors `root_folder` (via GraphQL `getFolder`) |
| **Liaison cassée** | la ligne `Automatisation:` d'un cas pointe un fichier inexistant (cf. critère 3) |
| **Doublon de libellé** | deux cas au summary quasi identique dans le même dossier |
| **Couverture par axe** | comparaison de l'arbre des axes de test attendus vs cas existants → trous |

### Procédure

1. **Filesystem** : `grep -roE "<test_link_pattern>" <tests_dir>` → inventaire des clés couvertes + tests sans préfixe.
2. **Référentiel** : `searchJiraIssuesUsingJql` (label `<case_label>`, projet `project_key`) + `getFolder(root_folder)` → inventaire des cas + rangement.
3. **Croiser** les deux ensembles → produire le rapport des anomalies ci-dessus.
4. **Agréger 1:N** : un cas couvert par plusieurs tests n'est pas un trou.

### Sortie

Rapport en chat (tableau par anomalie), puis **prochain pas proposé** :
- test orphelin → `case-design` (créer le cas) ou correction de préfixe ;
- cas sans test → `implementation` (ou priorisation à renvoyer vers `kp-product` si c'est une question de stratégie/axes) ;
- cas mal rangé → `case-design` (ranger via GraphQL).

L'audit ne tranche pas la **stratégie** de couverture (quels axes, quelles priorités P0/P1) — ça relève de `kp-product`. Il mesure l'écart et le signale.
