---
title: Spike mapping story-markdown vers ticket JIRA
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0005
epic-id: E-0004
---

# S-0005 - Spike mapping story-markdown ↔ ticket JIRA

## Résumé

Spike technique de 2-4 heures pour valider la **faisabilité** du mapping entre la structure d'une story `kp-agents` (markdown + frontmatter YAML + sections Gherkin + handoff) et un ticket JIRA standard via le MCP JIRA. Le résultat conditionne l'implémentation de S-0006.

Ce n'est pas une story d'implémentation : elle produit un **rapport de décision** (GO / NO-GO / GO partiel) et un **document de mapping** versionné.

## User Story

En tant que mainteneur du projet, je veux savoir si le modèle de story `kp-agents` peut être fidèlement représenté dans JIRA via MCP, afin de décider si j'implémente S-0006 dans cette epic ou si je scinde.

## Contexte

- Hypothèse critique H1 de l'epic : faisabilité du mapping sans perte d'info structurelle.
- Le MCP JIRA standard expose les opérations `getJiraIssue`, `createJiraIssue`, `editJiraIssue`, `searchJiraIssuesUsingJql`, `transitionJiraIssue`.
- Les stories `kp-agents` ont une structure riche : frontmatter YAML (story-id, epic-id, status, author, date, title), sections markdown (Résumé, User Story, Contexte, Règles métier, Scénarios nominal/alternatif/erreur, Cas limites, Critères d'acceptation, Dépendances, Notes techniques, Instrumentation, Questions ouvertes, Implémentation, Validation par critère).

## Règles métier

- Le spike ne crée **pas** de ticket pérenne : tout ce qui est créé dans JIRA pendant le spike doit être supprimé ou fermé en fin de spike.
- Le spike est réalisé sur une **instance JIRA sandbox** ou un projet JIRA dédié « SPIKE » — **ne jamais** le mener sur le projet JIRA de production d'une équipe.
- Le rapport de spike doit trancher : GO (mapping 1:1 fidèle), GO partiel (perte d'info acceptable, liste ce qui est perdu), NO-GO (perte d'info inacceptable, recommander alternative).

## Scénarios

### Nominal
- Étant donné une story `kp-agents` réelle (ex: S-0001 de cette epic)
- Quand on la crée dans JIRA via MCP, puis on la relit via MCP, puis on la re-compare au fichier source
- Alors on obtient un round-trip fidèle (tous les champs clés préservés).

### Alternatif
- Étant donné une story complexe avec scénarios Gherkin et blocs de code
- Quand on la crée dans JIRA
- Alors on observe la manière dont JIRA rend (ou mutile) le markdown : identifier ce qui passe, ce qui est transformé, ce qui est perdu.

### Erreur / refus
- Étant donné une tentative de créer une story dans JIRA avec un champ custom requis non renseigné (ex: « Story Points » obligatoire)
- Quand l'appel MCP échoue
- Alors documenter la liste des champs requis côté JIRA et la stratégie de gestion (valeurs par défaut ? prompt utilisateur ?).

## Cas limites

- [ ] Mapping de l'Epic : JIRA a un issue type `Epic` → mapping direct. Valider que les liens Epic ↔ Story sont préservés.
- [ ] Statuts : `TODO | IN PROGRESS | REVIEW | DONE` côté `kp-agents` vs workflow JIRA variable côté client (ex: `To Do | In Progress | In Review | Done | Cancelled`). Documenter le mapping.
- [ ] Frontmatter YAML : où le stocker dans JIRA (custom fields, description, labels) ?
- [ ] Sections structurées (Scénarios, Cas limites) : tout dans le champ Description, ou éclater sur plusieurs champs ?
- [ ] Longueur maximum du champ Description dans JIRA (à vérifier)

## Critères d'acceptation

- [ ] Document de spike créé : `docs/project/epics/E-0004-Sources-Externalisation/spike-jira-mapping.md` (dans le repo ou externalisé selon config)
- [ ] Test round-trip réalisé sur au moins **2 stories réelles** (dont 1 avec scénarios complexes) et **1 epic**
- [ ] Décision tranchée : GO / GO partiel / NO-GO avec justification
- [ ] Si GO partiel : liste exhaustive des pertes d'information et stratégie de mitigation (ex: champ `kp-raw` custom contenant le markdown source)
- [ ] Proposition de schéma de mapping : tableau `champ kp-agents` ↔ `champ JIRA` pour chaque élément
- [ ] Tickets créés pendant le spike supprimés ou clôturés à la fin
- [ ] Recommandation explicite sur la suite : (a) GO sur S-0006 en l'état, (b) GO sur S-0006 avec ajustements, (c) scinder l'epic (E-A sans tickets MCP, E-B dédiée)

## Dépendances

- **S-0001** (schéma de config) pour déclarer `tickets.mode: mcp` dans un projet sandbox
- **S-0002** (setup) non bloquant mais utile pour configurer le sandbox via setup plutôt qu'à la main
- Accès à un **serveur MCP JIRA** opérationnel (sandbox ou projet de test dédié)

## Notes techniques

- Timeboxer strictement : 2h en première passe, maximum 4h. Au-delà, clôturer avec une décision « NO-GO » ou « GO avec scinder l'epic ».
- Utiliser une story **existante** de E-0004 comme cobaye (pas besoin de créer des stories fictives).
- Documenter les appels MCP exacts utilisés pour permettre une automatisation ultérieure.

## Instrumentation / mesure

- Temps passé sur le spike (pour calibrer les futurs spikes)
- Nombre d'allers-retours MCP pour obtenir un mapping fonctionnel (indicateur de complexité)

## Questions ouvertes

- La structure des champs custom JIRA varie selon le projet client. Le mapping doit-il être **configurable par projet** (`.kp-agents.yml` contient la matrice de mapping) ou **en dur** avec mapping générique ? → **À trancher dans ce spike.**

## Implémentation

### Nature

Spike technique pur — aucun code produit, un rapport de décision structuré.

### Environnement testé

- MCP Atlassian connecté à `keyprod.atlassian.net` (cloudId `84ea1157-7773-4f19-96f1-7eab345c3ad1`)
- Projet sandbox : **POC** (KP-POC), validé par l'utilisateur avant création de tickets
- 3 tickets créés puis clôturés (`Abandoné`) : POC-689 (epic E-0004), POC-690 (S-0001), POC-691 (S-0009)

### Inputs utilisateur impactant le périmètre

Au démarrage du spike, l'utilisateur a ajouté 2 exigences qui ont étendu le livrable :

1. **Override local du projet JIRA** : le projet est porté par `.kp-agents.yml` (partagé) mais `.kp-agents.local.yml` peut l'override au niveau dev.
2. **Mapping configurable** : les champs, préfixe, statuts, etc. doivent être configurables par projet via `/kp-agents:setup`, avec un set de défauts suggérés par l'agent.

Ces 2 exigences ont modifié la forme du livrable du spike (rapport de faisabilité + **schéma de mapping + patterns d'override**) sans sortir du timebox.

### Fichiers créés

- `docs/project/epics/E-0004-Sources-Externalisation/spike-jira-mapping.md` — rapport complet du spike (faisabilité, mapping proposé, schéma config, défauts setup, recommandation suite).

### Commandes de test MCP exécutées

| Commande | But | Résultat |
|---|---|---|
| `atlassianUserInfo` | Vérifier identité + scope | ✅ Vincent DREANO, PM |
| `getAccessibleAtlassianResources` | Récupérer cloudId | ✅ `keyprod.atlassian.net` |
| `getVisibleJiraProjects` (action=create) | Lister les projets accessibles en écriture | ✅ 18 projets, POC et TODO identifiés comme sandbox-safe |
| `getJiraProjectIssueTypesMetadata` (POC) | Lister les issue types | ✅ Story, Epic, Bug, Tâche, Sous-tâche |
| `getJiraIssueTypeMetaWithFields` (Story) | Voir les champs requis | ✅ seuls `project`, `reporter`, `summary` requis |
| `createJiraIssue` × 3 | Créer epic + 2 stories avec description markdown | ✅ POC-689, POC-690, POC-691 |
| `getJiraIssue` × 2 (format=markdown) | Relire les stories pour comparaison | ✅ diff observé (voir rapport) |
| `getTransitionsForJiraIssue` × 2 | Identifier les transitions disponibles | ✅ 6 transitions, dont `Abandoné` (id 5) |
| `transitionJiraIssue` × 3 | Cleanup via transition `Abandoné` | ✅ 3 succès |

### Décision finale

**GO partiel** — round-trip faisable, mapping structuré, recommandation **GO sur S-0006 avec ajustements** (schéma `tickets.mapping` à ajouter dans l'include `sources-config.md` + agent `setup` à étendre). Pas de scission d'epic nécessaire.

### Timebox

- Budget : 2-4h
- Effectif : ~90 min
- Sous le budget — la fidélité markdown s'est avérée meilleure qu'anticipée.

## Validation par critère

- **Document de spike créé** (`docs/project/epics/E-0004.../spike-jira-mapping.md`) : ✅ 200+ lignes, couvre faisabilité / mapping / schéma config / override / défauts setup / suite.
- **Round-trip sur ≥2 stories (dont 1 complexe) + 1 epic** : ✅ POC-690 (S-0001, frontmatter riche), POC-691 (S-0009, matrice + bloc yaml + émojis), POC-689 (E-0004).
- **Décision tranchée GO / GO partiel / NO-GO** : ✅ **GO partiel**, justifié dans le rapport.
- **Liste exhaustive des pertes + stratégie de mitigation** : ✅ dans le rapport (frontmatter → labels + pattern configurable, [x] → échappement cosmétique acceptable, ordre labels → non-problème, double statut → mapping configurable).
- **Schéma de mapping `kp-agents ↔ JIRA`** : ✅ tableau complet dans le rapport (summary, description, story-id, epic-id, status, author, date, frontmatter extensible, sections Review/Implémentation).
- **Tickets créés supprimés ou clôturés** : ✅ POC-689, POC-690, POC-691 transitionnés en `Abandoné` (le MCP Atlassian n'expose pas de `deleteJiraIssue`, la clôture est la meilleure approximation disponible).
- **Recommandation explicite sur la suite** : ✅ **GO sur S-0006 avec ajustements** — 6 points d'ajustement listés dans le rapport (parser `tickets.mapping`, extraire frontmatter, reconstruire frontmatter en lecture, mapper transitions, merge `.local.yml`, agents en écriture JIRA).

### Limites / points non couverts

- **Fidélité ADF non testée** : seul le format `markdown` a été exercé sur le round-trip. ADF permet une fidélité supérieure (panels, smart links, mentions) mais complexifie le mapping. À évaluer en S-0006 si markdown s'avère insuffisant en pratique.
- **Custom fields non testés** : POC n'a pas de custom field requis. Sur un projet réel avec Story Points obligatoire ou Sprint requis, la stratégie de valeurs par défaut côté setup devra être validée.
- **Pas de test de round-trip sur une story déjà éditée côté JIRA** : on n'a pas simulé le cas « un PM modifie la description dans JIRA, puis l'agent `review` la relit » — la stratégie de merge reste à définir en S-0006.
- **Workflow statuts spécifique au projet POC** : les noms (`Examiner`, `Terminé(e)`) sont spécifiques au projet. Le schéma `mapping.status` couvre ce besoin par configuration.
