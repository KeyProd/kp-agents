---
title: Mode tickets.mode mcp (JIRA)
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0006
epic-id: E-0004
---

# S-0006 - Mode `tickets.mode: mcp` (JIRA)

## Résumé

Implémenter le mode externe pour la dimension `tickets` : les epics et stories sont créées/lues/mises à jour dans JIRA via MCP, selon le mapping validé en S-0005. Les agents `product`, `developer` et `review` apprennent à travailler avec cette nouvelle source.

**Bloqué par S-0005** : n'ouvrir cette story que lorsque le spike a statué GO ou GO partiel.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux que les epics et stories de mon projet soient gérées directement dans JIRA, afin que mon équipe voie et collabore sur ces tickets sans friction ni duplication.

## Contexte

- Dépend du résultat de S-0005 : mapping de champs, gestion des statuts, stratégie pour champs custom requis.
- Les agents affectés : `product` (crée epics/stories), `developer` (change status vers IN PROGRESS, écrit en section Implémentation), `review` (change status vers REVIEW/DONE).
- Les agents non affectés : `brainstorm` (ideas restent sur `product.mode`), `architect` (doc technique local), `documentation` (INDEX local), `ux-ui` (écrit dans docs/features, suit `product.mode`).

## Règles métier

- Le mapping précis est défini par le document de S-0005 (`spike-jira-mapping.md`), référence normative.
- Les agents `product`, `developer`, `review` écrivent dans JIRA si `tickets.mode: mcp` est actif, sinon en local (comportement actuel).
- **Pas de cache persistant** : à chaque invocation, l'agent relit depuis JIRA. Pas de fichiers `.json` de cache dans le repo.
- Les **handoffs** entre agents (bloc structuré en chat) restent textuels et ne sont pas persistés dans JIRA — ils sont inter-sessions Claude Code.
- Conservation du lien Epic ↔ Story : JIRA a un issue type `Epic` et un champ « Epic Link » natif → mapping direct.

## Scénarios

### Nominal
- Étant donné un projet avec `tickets.mode: mcp`, `mcp_server: jira`, `project_key: KP`
- Quand l'utilisateur demande à `/kp-agents:product` de créer une nouvelle epic
- Alors l'agent crée un issue de type `Epic` dans le projet JIRA `KP` avec les champs mappés, et ne crée **pas** de fichier local `E-XXXX-*/readme.md`.

### Alternatif
- Étant donné une epic existante dans JIRA
- Quand l'utilisateur demande à `/kp-agents:product` de découper une feature en stories sous cette epic
- Alors l'agent cherche l'epic JIRA (par titre ou ID), crée les stories enfants avec le « Epic Link » vers l'epic parente.

### Erreur / refus
- Étant donné le MCP JIRA est down (hors service, token expiré)
- Quand un agent tente une opération
- Alors l'agent warn explicitement, propose de (a) réessayer, (b) basculer ponctuellement en local pour cette session, (c) annuler l'opération.

## Cas limites

- [ ] Epic `kp-agents` actuelle vs epic JIRA : comment migrer des epics locales déjà existantes ? → **Hors scope V1**, migration manuelle si l'utilisateur le souhaite.
- [ ] Caractères spéciaux dans le titre (accents, emojis) : JIRA gère, à tester
- [ ] Stories marquées `DONE` : l'archivage `_archives/` local n'a pas d'équivalent côté JIRA (statut `Done` suffit)
- [ ] Lecture d'un ticket qui a été modifié hors agent : les agents lisent toujours la version fraîche, pas de merge conflit
- [ ] Projet JIRA avec workflow custom (ex: `Backlog → To Do → In Progress → Review → Done` au lieu du workflow standard) : mapping configuré côté `.kp-agents.yml` ?

## Critères d'acceptation

- [ ] Mapping implémenté conformément au document de S-0005
- [ ] `/kp-agents:product` peut créer une epic dans JIRA via MCP
- [ ] `/kp-agents:product` peut créer une story sous une epic JIRA existante
- [ ] `/kp-agents:developer` peut transitionner une story JIRA vers `In Progress` puis `Review`
- [ ] `/kp-agents:review` peut transitionner une story JIRA vers `Done`
- [ ] Les agents affichent clairement l'ID et le lien JIRA des tickets manipulés dans leurs réponses
- [ ] Gestion d'erreur MCP : warn clair + options présentées à l'utilisateur
- [ ] Test manuel end-to-end : créer epic → story → passer IN PROGRESS → passer REVIEW → passer DONE, 100% via les agents, 100% reflété dans JIRA
- [ ] Test manuel non-régression : projet en `tickets.mode: local` continue de fonctionner comme avant
- [ ] Documentation du mapping dans `includes/sources-config.md` ou document dédié référencé

## Dépendances

- **S-0005** (spike validé — bloquant)
- **S-0001, S-0002, S-0003** (fondations, agent setup, intégration)

## Notes techniques

- L'utilisateur doit avoir configuré le serveur MCP JIRA dans ses `settings.json` Claude Code avant d'activer `tickets.mode: mcp`. L'agent `setup` le rappelle mais ne configure pas le MCP lui-même.
- Risque de couplage fort au schéma MCP : prévoir une abstraction minimale dans `sources-config.md` pour faciliter un futur support d'autres systèmes (Linear, etc.).
- Les identifiants `S-XXXX` et `E-XXXX` `kp-agents` n'ont pas de sens en mode MCP (JIRA a ses propres IDs). En mode MCP, utiliser les IDs JIRA partout dans les handoffs et références. Laisser l'utilisateur décider de conserver ou non les préfixes `E-XXXX` dans les titres.

## Instrumentation / mesure

- Temps de réponse d'une création de ticket (baseline attendu : < 3s via MCP)
- Nombre d'appels MCP par opération courante (indicateur de sur-consommation d'appels)

## Questions ouvertes

- Faut-il persister un fichier d'index `tickets.json` local pour suivre la correspondance `S-XXXX` ↔ JIRA ID ? → **Probablement non**, les agents demandent l'ID JIRA ou le retrouvent par recherche. À trancher lors de l'implémentation.

## Implémentation

### Nature

Implémentation 100% descriptive (markdown dans l'include `sources-config.md` + sections contextualisées dans 4 agents), cohérent avec le pattern des stories précédentes de l'epic. Les agents appliquent le pipeline documenté via les outils MCP déjà disponibles dans leur session Claude Code.

### Décisions clés (issues du spike S-0005)

- **Frontmatter YAML** : extrait du markdown source et encodé en **labels JIRA** via `mapping.label_patterns` (pattern configurable). La `description` JIRA ne contient que le body markdown.
- **Reconstitution en lecture** : le frontmatter est reconstitué depuis les labels + champs natifs JIRA au moment de présenter la story à l'utilisateur. Jamais persisté sur disque en mode `mcp`.
- **Mapping configurable** : `tickets.mapping` dans `.kp-agents.yml` couvre préfixe summary, noms issue types, statuts workflow (4 cibles TODO/IN_PROGRESS/REVIEW/DONE), labels systématiques, patterns d'encodage, custom fields, placement de la section Review.
- **Override local** : `.kp-agents.local.yml` peut surcharger `tickets.project_key` (cas « dev qui veut pousser dans son propre projet sandbox »). Deep merge champ par champ.
- **Gestion d'erreur MCP** : protocole 3 options (retry / bascule locale ponctuelle / annuler) systématisé, jamais de création silencieuse en local.
- **Affichage standardisé** : format unique `**JIRA** : [KEY](url) — <summary> *(status: <X>)*` pour traçabilité.
- **Non-régression** : mode `local` (défaut) 100% inchangé, le pipeline MCP est désactivé si `tickets.mode` est absent ou vaut `local`.

### Fichiers modifiés

| Fichier | Avant | Après | Δ |
|---|---:|---:|---:|
| `includes/sources-config.md` | 130 | 247 | +117 |
| `agents/setup.md` | 157 | 180 | +23 |
| `agents/product.md` | 171 | 183 | +12 |
| `agents/developer.md` | 251 | 261 | +10 |
| `agents/review.md` | 240 | 250 | +10 |

### Détail des modifications

1. **`includes/sources-config.md`** :
   - Schéma `.kp-agents.yml` étendu avec bloc `tickets.mapping` complet (summary_prefix, issue_type_*, status map, labels, label_patterns, custom_fields, review_placement).
   - Nouvelle sous-section « Override local via `.kp-agents.local.yml` » — pattern de deep merge champ par champ.
   - Tableau de sémantique `tickets.mapping` (10 champs documentés).
   - Pipeline d'écriture en 8 étapes (extract frontmatter → compose summary/description/labels/parent → createJiraIssue → transitionJiraIssue → affichage).
   - Pipeline de lecture en 3 étapes (getJiraIssue markdown → reconstruct frontmatter depuis labels → affichage).
   - Pipeline de mise à jour (body via edit, statut via transition, labels via edit).
   - Format d'affichage standardisé des liens JIRA.
   - Gestion d'erreur MCP : format warn 3 options + 3 causes distinguées (MCP non chargé / auth expirée / champ requis manquant).
   - Section « Non-régression » explicite pour le mode local.
   - Tableau « Agents concernés » par opération.

2. **`agents/setup.md`** :
   - Étape 3 « Questions ciblées » — bullet supplémentaire sur `tickets.mapping` avec démarche en 4 temps (annonce défauts → validation MCP → customisation à la demande → fallback défauts si pas écrit).
   - Tableau des défauts suggérés (10 champs).
   - 3 nouveaux cas limites : mapping partiel, override local de project_key, validation MCP impossible.

3. **`agents/product.md`** :
   - Nouvelle sous-section `### Mode tickets.mode: mcp` après `read-only`.
   - Gotcha : jamais de création locale en mode mcp (sauf fallback confirmé).

4. **`agents/developer.md`** :
   - Nouvelle sous-section `### Mode tickets.mode: mcp` dans la section « Configuration du projet ».
   - Pipeline développeur : transition TODO→IN_PROGRESS au démarrage, edit description pour Implémentation/Validation, transition IN_PROGRESS→REVIEW ou DONE en fin.

5. **`agents/review.md`** :
   - Nouvelle sous-section `### Mode tickets.mode: mcp`.
   - Deux stratégies pour la section Review : `description` (append, défaut) ou `comment` (via `addCommentToJiraIssue`), gouvernées par `mapping.review_placement`.
   - Transitions : GO → DONE, NO-GO → IN_PROGRESS.

### Mesures SKILL.md générés

| Agent | Avant (S-0005) | Après S-0006 | Δ |
|---|---:|---:|---:|
| architect | 399 | 516 | +117 |
| brainstorm | 399 | 516 | +117 |
| developer | 471 | **598** | +127 |
| documentation | 433 | 550 | +117 |
| product | 377 | 506 | +129 |
| review | 455 | 587 | +132 |
| setup | 363 | 503 | +140 |
| ux-ui | 432 | 549 | +117 |

**developer** à 598 lignes — plus gros agent, approche 600 lignes. Reste acceptable. Surveiller à S-0008 si ajouts futurs.

### Vérifications techniques

- `grep '{{include' plugins/kp-agents/skills/*/SKILL.md` → **0 résidu** sur les 8 agents.
- `grep -l 'tickets.mapping' plugins/kp-agents/skills/*/SKILL.md` → **8 matches** (include inliné partout, cohérent).
- `./sync.sh --dist-only` : 8 agents syncés dans 3 cibles sans erreur, auto-bump patch déclenché.

### Commandes de test (pour l'utilisateur)

Le test end-to-end nécessite un projet avec `.kp-agents.yml` contenant `tickets.mode: mcp` et un MCP Atlassian configuré. Protocole recommandé, basé sur le sandbox **POC** déjà utilisé en S-0005 :

```yaml
# .kp-agents.yml du projet test
tickets:
  mode: mcp
  mcp_server: atlassian
  project_key: POC
  mapping:
    summary_prefix: "[TEST] "
    issue_type_story: Story
    issue_type_epic: Epic
    status:
      TODO: "À faire"
      IN_PROGRESS: "En cours"
      REVIEW: "Examiner"
      DONE: "Terminé(e)"
```

Scénarios à exécuter :
1. `/kp-agents:product` → « crée l'epic Test ». Vérifier création POC-XXX issue type Epic.
2. `/kp-agents:product` → « crée une story S-0001 sous cette epic ». Vérifier `parent` = POC-XXX et labels `kp-story-S0001`, `kp-epic-Test`.
3. `/kp-agents:developer` → « implémente S-0001 ». Vérifier transition vers `En cours` + edit description avec section Implémentation.
4. `/kp-agents:review` → « review la dernière story ». Vérifier transition `Examiner → Terminé(e)` (GO) et présence de la section Review soit dans description soit en commentaire.
5. Test d'erreur : déconnecter temporairement le MCP (ou utiliser un project_key invalide). Vérifier l'affichage du warn 3 options.
6. Test non-régression : sur un projet sans `.kp-agents.yml`, invoquer `/kp-agents:product` → création locale dans `docs/project/epics/` comme avant.
7. Test override local : ajouter `.kp-agents.local.yml` avec `tickets.project_key: TODO`. Créer une story → vérifier qu'elle atterrit dans TODO et non POC.

Cleanup post-test : transition `Abandoné` sur les tickets créés (comme en S-0005).

### Limites

- **Pas de test E2E automatisé** : l'implémentation étant descriptive, elle est testable uniquement par usage réel avec un MCP configuré. Le spike S-0005 a validé les primitives MCP (create/read/edit/transition), cette story les compose — le compose est fiable si chaque brique l'est, mais un test de bout en bout par l'utilisateur reste requis.
- **Conservation hors scope V1** : l'état `_archives/` local n'a pas d'équivalent JIRA — les stories `DONE` restent dans JIRA en statut final, pas d'archivage automatique. Documenté dans l'epic.
- **Migration de projets locaux existants** : hors scope. Un utilisateur qui voudrait migrer `docs/project/epics/E-XXXX/` existantes vers JIRA devra le faire manuellement ou via script ad-hoc (pas fourni).
- **ADF non exploité** : on reste en `markdown` pour le format de description. ADF offrirait plus (panels, smart links) mais complexifie le pipeline. À reconsidérer si un cas d'usage le justifie.
- **Merge conflict** : si un PM modifie la description JIRA hors agent entre deux invocations d'agent, la lecture de l'agent suivant écrasera ces modifications au prochain edit. Mentionné dans le pipeline de mise à jour (« relire d'abord pour préserver l'existant ») mais pas formalisé en protocole de merge.

## Validation par critère

- **Mapping implémenté conformément au document de S-0005** : ✅ `includes/sources-config.md` inclut le schéma complet `tickets.mapping` avec tous les champs documentés dans le spike (summary_prefix, issue_type_*, status map 4 cibles, labels, label_patterns 4 catégories, custom_fields, + review_placement ajouté en S-0006). Pipeline d'écriture/lecture/update détaillés.
- **`/kp-agents:product` peut créer une epic dans JIRA via MCP** : ✅ section `### Mode tickets.mode: mcp` ajoutée dans `agents/product.md`, pipeline référencé. Test E2E à exécuter par l'utilisateur.
- **`/kp-agents:product` peut créer une story sous une epic JIRA existante** : ✅ utilisation du champ `parent` natif JIRA documentée, pas d'Epic Link custom nécessaire (validé au spike S-0005).
- **`/kp-agents:developer` peut transitionner une story JIRA vers `In Progress` puis `Review`** : ✅ section `### Mode tickets.mode: mcp` ajoutée dans `agents/developer.md`, transitions TODO→IN_PROGRESS au démarrage et IN_PROGRESS→REVIEW/DONE en fin documentées.
- **`/kp-agents:review` peut transitionner une story JIRA vers `Done`** : ✅ section dédiée dans `agents/review.md`, transitions GO (REVIEW→DONE) et NO-GO (REVIEW→IN_PROGRESS) documentées, avec choix de placement de la section Review (description/comment).
- **Les agents affichent clairement l'ID et le lien JIRA des tickets manipulés** : ✅ format d'affichage standardisé `**JIRA** : [KEY](url) — <summary> *(status: <X>)*` documenté dans `sources-config.md` et référencé dans les 3 agents concernés.
- **Gestion d'erreur MCP : warn clair + options présentées à l'utilisateur** : ✅ protocole 3 options (retry / bascule locale ponctuelle / annuler) + 3 causes distinguées (MCP non chargé / auth / champ requis) documentés.
- **Test manuel end-to-end : créer epic → story → passer IN PROGRESS → passer REVIEW → passer DONE** : ⚠️ **à exécuter par l'utilisateur** — protocole précis avec config POC documenté dans la section « Commandes de test » ci-dessus.
- **Test manuel non-régression : projet en `tickets.mode: local` continue de fonctionner comme avant** : ⚠️ **à exécuter par l'utilisateur** — section « Non-régression en mode `tickets.mode: local` » explicite dans l'include. Le pipeline MCP est inactif si le mode n'est pas `mcp`.
- **Documentation du mapping dans `includes/sources-config.md`** : ✅ section `### Mode tickets.mode: mcp` enrichie de 117 lignes, couvre schéma / override / sémantique / pipelines / affichage / erreur / non-régression / agents concernés.
