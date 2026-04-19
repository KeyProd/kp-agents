---
title: Review des agents kp-agents
date: 2026-04-18
status: active
author: documentation-agent
---

# Review des agents kp-agents

> Audit des 7 sources dans `agents/*.md` : récap de chaque agent, forces, divergences observées et pistes d'optimisation **sans changer leur objectif actuel**.
> Ce document est une proposition d'évolution — aucune modification des agents n'a été appliquée. Validation utilisateur requise avant action.

---

## Synthèse transversale

### Points communs bien tenus

- **Frontmatter homogène** : `name`, `description`, `short_description`, `default_prompt` présents partout, format cohérent.
- **Includes standards** : `{{include:guardrails}}` + `{{include:handoff}}` présents dans les 7 agents. `docs-structure` (complet) pour product / developer / review, `docs-structure-light` pour brainstorm / architect / documentation / ux-ui — cohérent avec la stratégie documentée dans `CLAUDE.md`.
- **Modes d'utilisation** explicités quand plusieurs (architect, developer, review, documentation, ux-ui).
- **Recommandation de relais** systématiquement présente en fin de processus.

### Divergences observées (transversales)

| # | Constat | Impact | Agents concernés |
|---|---------|--------|------------------|
| T1 | Bloc "Activation et persistance" dupliqué verbatim dans 4 agents, **tronqué** dans 3 autres (review, ux-ui, review manque "change de sujet" et "distingue faits/hypothèses") | Incohérence de comportement entre agents ; maintenance x7 | brainstorm, product, architect, developer ✅ / review, ux-ui ⚠️ (partiels) / documentation ✅ |
| T2 | Templates d'epic / story / roadmap **écrits inline** dans `product.md` alors que `includes/epic-template.md` et `includes/story-template.md` existent | Double source de vérité : risque de divergence silencieuse avec les includes | product |
| T3 | Règle "Versions des dépendances — recherche internet" recopiée quasi à l'identique dans 3 agents | Duplication, maintenance x3 | architect, developer, review |
| T4 | Recours à la **mémoire projet** mentionné dans developer (config, simplify) et review (outil auto) sans convention partagée | Comportement difficile à tracer, pas de schéma commun | developer, review |
| T5 | `docs/agents.md` utilise `-.->` pour les chemins facultatifs, mais les agents eux-mêmes n'expriment pas cette distinction dans leurs règles | Divergence doc / source | tous |
| T6 | Étape "Simplification" du developer appelle `/simplify` (slash command Claude Code) ; pas d'équivalent décrit pour Cursor/Codex alors que la distribution est multi-cibles | Portabilité incomplète | developer |

---

## Récap par agent

### 1. Brainstorm — `agents/brainstorm.md` (140 lignes)

**Objectif (inchangé)** : facilitateur d'exploration d'idée, interactif, produit `docs/ideas/<theme>.md` incrémentalement.

**Forces** :
- Section "Choix de méthode" (5 Whys, SCAMPER, Six Thinking Hats, Starbursting, First Principles, Worst Possible Idea, Mind Mapping) → distingue cet agent d'un simple chat exploratoire.
- STOP explicite entre chaque phase (compréhension → exploration → critique → structuration).
- Sauvegarde **progressive** du fichier avec cycle de statut `draft → exploring → qualified | rejected`.

**Optimisations proposées** :
- **O1.1 (P3)** La phase 4 "Structuration" ne comporte pas de STOP comme les 3 précédentes — cohérent (c'est la sortie) mais pourrait expliciter "propose la suite et attends choix utilisateur".
- **O1.2 (P3)** Les 3 approches imposées (conventionnelle / créative / minimaliste) sont utiles comme plancher mais pourraient être adoucies par "au moins 3 approches, dont idéalement ces archétypes" pour laisser place à des catégorisations adaptées au sujet.

---

### 2. Product — `agents/product.md` (239 lignes, le plus long)

**Objectif (inchangé)** : PM qui transforme idées en roadmap / epics / stories actionnables avec critères d'acceptation.

**Forces** :
- "Principe de complétude avant avancement" + "Suggestion proactive de la suite" → discipline conversationnelle forte.
- Section "Contrôle de complétude" (étape 7) avant finalisation.
- Règles numérotation explicites (E-XXXX global, S-XXXX local à l'epic).
- Exemple "bon critère vs trop vague".

**Optimisations proposées** :
- **O2.1 (P1)** **Remplacer les templates inline par les includes** : `docs/project/roadmap.md`, `epic readme.md` et `story` sont définis dans le fichier alors que `includes/product-template.md`, `includes/epic-template.md`, `includes/story-template.md` existent. Gain : ~80 lignes + source de vérité unique partagée avec `documentation` qui s'y réfère déjà.
- **O2.2 (P2)** Le "mode init" (étape 5) est coincé entre les étapes 4 (stories) et 6 (vue globale). Le déplacer avant l'étape 1 "Cadrage produit" dans une section dédiée "Initialisation projet" clarifierait le flux.
- **O2.3 (P3)** Les deux dernières règles sur "Exemples de calibrage qualité" rompent la liste des règles (titre h3 imbriqué) — à extraire en section autonome.

---

### 3. Architect — `agents/architect.md` (157 lignes)

**Objectif (inchangé)** : conception technique, ADR, évaluation de compromis, en mode libre ou en mode epic.

**Forces** :
- "Principe de complétude avant décision" + questions bloquantes vs d'affinement.
- **Exemple d'ADR chiffré** (ADR-003 WebSocket) très pédagogique — à préserver tel quel.
- Règle "Versions des dépendances — recherche internet".
- Include `{{include:architect-template}}` dédié.

**Optimisations proposées** :
- **O3.1 (P2)** Règle "Versions des dépendances" candidate à un include partagé `{{include:dependency-versions}}` avec developer et review (cf. T3).
- **O3.2 (P3)** Le "Format recommandé" (section à part) et le "Processus" se recoupent partiellement (contexte / contraintes / hypothèses / options apparaissent deux fois). Fusionner en une checklist unique serait plus lisible.

---

### 4. Developer — `agents/developer.md` (181 lignes)

**Objectif (inchangé)** : implémentation rigoureuse sur base des specs `docs/`, en mode story ou epic.

**Forces** :
- Cadrage obligatoire **avant** chargement de contexte (branche, commits, PR) avec mémorisation de la préférence utilisateur.
- Plan d'implémentation **obligatoire** avec STOP validation.
- Section "Validation par critère" mappée aux critères d'acceptation.
- Règles explicites : "Pas de worktree", "Ne commence jamais à coder sans plan validé".

**Optimisations proposées** :
- **O4.1 (P1)** **Chevauchement étape 6 "Bilan" ↔ étape 7 "Mise à jour de la documentation"** : la 6 recommande déjà `/kp-documentation`, la 7 ré-énumère presque les mêmes actions. Fusionner en "6. Bilan et relais documentaire" améliorerait la lisibilité (~15 lignes gagnées).
- **O4.2 (P2)** L'étape 5 "Simplification" appelle `/simplify` (slash command Claude Code). Pour Cursor/Codex, le comportement à adopter n'est pas spécifié. Reformuler en "lance l'outil de simplification disponible sur la plateforme courante, sinon fais une passe manuelle" éviterait l'impasse multi-cibles (cf. T6).
- **O4.3 (P3)** Règle "Versions des dépendances" à extraire en include partagé (cf. T3).

---

### 5. Review — `agents/review.md` (185 lignes)

**Objectif (inchangé)** : reviewer senior, verdict GO/NO-GO + recommandations P1/P2/P3 écrites dans la story.

**Forces** :
- Tableau des recommandations avec colonnes claires (Catégorie, Priorité, Description, Exemple).
- Exemple "bien formulé vs trop vague" concret (JWT localStorage vs httpOnly cookie).
- Règle "Ne modifie JAMAIS le code source" — frontière nette avec developer.
- Bilan consolidé en mode epic.

**Optimisations proposées** :
- **O5.1 (P1)** **Bloc "Activation et persistance" tronqué** : seulement 2 puces explicites (actif + hors périmètre), manque "change de sujet → reste Review" et "distingue faits/hypothèses". Aligner sur la version complète (cf. T1).
- **O5.2 (P2)** L'étape 2 "Revue automatisée" mélange détection multi-plateforme, message utilisateur et mémorisation sur ~15 lignes. Simplifier en "Si un outil de review auto est disponible (MCP, skill, extension), l'utiliser ; sinon passer à l'étape 3" + mémoire conservée mais concise.
- **O5.3 (P3)** La règle "Versions des dépendances" placée **après** la section "Exemple de recommandation bien formulée" casse la lecture — à regrouper avec les autres règles (ou include partagé, cf. T3).

---

### 6. Documentation — `agents/documentation.md` (231 lignes)

**Objectif (inchangé)** : auditer, maintenir la documentation projet, propriétaire exclusif de `docs/INDEX.md`.

**Forces** :
- Périmètre étendu explicite (`docs/`, `README.md`, `CLAUDE.md`, docs locales composants).
- 3 modes clairs (interactif / analyse de code / maintenance).
- Format type pour présenter une divergence (5 champs).
- Règle "Syntaxe Mermaid" (guillemets dans labels, texte multi-lignes) — leçon apprise utile.

**Optimisations proposées** :
- **O6.1 (P2)** **Section "Format de l'index"** (≈50 lignes, template verbatim) pourrait être extraite en `includes/index-template.md` pour alléger l'agent. L'agent garde la responsabilité, le template devient maintenable séparément.
- **O6.2 (P3)** Redondance entre la liste de règles finale et les bullet-points des étapes 1–5 (ex: "Lis toujours la doc existante avant de proposer de la remplacer" apparaît deux fois). Dédoublonner.

---

### 7. UX/UI — `agents/ux-ui.md` (134 lignes)

**Objectif (inchangé)** : designer UX/UI senior, anti-générique, définit personas + identité visuelle + specs tokens pour developer.

**Forces** :
- Section "Philosophie" (anti-générique, utilisateur d'abord, moins mais mieux) — donne une voix à l'agent.
- Fiche persona structurée (rôle, contexte, objectif, frustrations, niveau technique, ce qui compte).
- Règle d'accessibilité WCAG 2.1 AA chiffrée (contraste 4.5:1, cibles 44×44px).
- 3 modes (discovery / feature / audit) concis.

**Optimisations proposées** :
- **O7.1 (P1)** **Bloc "Activation et persistance" tronqué** (3 puces au lieu de 5) — mêmes manques que review (cf. T1).
- **O7.2 (P3)** La section "Spécifications pour le Developer" (étape 5) énumère 5 groupes de specs sans format précis. Proposer un mini-template (tokens.css, README composant, états) rendrait la sortie plus prédictible pour le developer.

---

## Recommandations priorisées

### P1 — À traiter rapidement (cohérence / dédoublonnage à fort impact)

| ID | Action | Agents impactés | Gain estimé |
|----|--------|-----------------|-------------|
| T1 / O5.1 / O7.1 | Créer `includes/activation.md` et remplacer le bloc dans les 7 agents | tous | ~35 lignes, cohérence 100% |
| O2.1 | Remplacer les templates inline de product par les includes existants | product | ~80 lignes, source de vérité unique |
| O4.1 | Fusionner les étapes 6 et 7 de developer | developer | ~15 lignes, lisibilité |

### P2 — Prochain cycle (factorisation, portabilité)

| ID | Action | Agents impactés |
|----|--------|-----------------|
| T3 / O3.1 / O4.3 / O5.3 | Créer `includes/dependency-versions.md` et factoriser | architect, developer, review |
| O4.2 | Généraliser l'étape "Simplification" du developer pour multi-cibles | developer |
| O5.2 | Simplifier l'étape "Revue automatisée" de review | review |
| O6.1 | Extraire le template d'index en `includes/index-template.md` | documentation |
| O2.2 | Déplacer le "mode init" de product avant l'étape 1 | product |

### P3 — Backlog qualité (nettoyage)

| ID | Action | Agents impactés |
|----|--------|-----------------|
| O1.1 / O1.2 | Affiner brainstorm (STOP étape 4, ouverture des 3 approches) | brainstorm |
| O2.3 | Sortir "Exemples de calibrage qualité" des règles | product |
| O3.2 | Fusionner "Format recommandé" et "Processus" de architect | architect |
| O6.2 | Dédoublonner règles et étapes de documentation | documentation |
| O7.2 | Ajouter un mini-template de specs UX pour developer | ux-ui |

---

## Ce qui reste inchangé volontairement

- **Objectif de chaque agent** : aucun pivot de périmètre proposé.
- **Frontmatter** (name, description, short_description, default_prompt) : format validé, conservé.
- **Chaîne `brainstorm → product → architect → developer → review`** et agents transversaux (`ux-ui`, `documentation`) : workflow inchangé.
- **Règles critiques spécifiques** (ex: "Pas de worktree" pour developer, "Ne modifie jamais le code" pour review, "Seul responsable de INDEX.md" pour documentation) : conservées telles quelles.
- **Schémas Mermaid** de `docs/agents.md` : déjà à jour — pas de modification nécessaire suite à cette review.

---

## Prochaine étape suggérée

1. **Validation** des P1 par l'utilisateur → puis implémentation par l'agent Developer (les modifs sont ciblées sur `agents/` + ajout d'un ou deux includes, le sync.sh régénérera les artefacts).
2. Aucun bump de version `plugin.json` nécessaire pour les P3, mais un bump **mineur** (0.1.0 → 0.2.0) est recommandé après les P1+P2 car le comportement des agents évolue.
3. Les P2/P3 peuvent être traités opportunistiquement lors des prochaines interventions sur chaque agent concerné.

---

## Annexe — Review complémentaire à la lumière de `agentskills.io`

> Cette section applique aux agents `kp-agents` les recommandations de trois guides de référence :
> - [agentskills.io/skill-creation/optimizing-descriptions](https://agentskills.io/skill-creation/optimizing-descriptions)
> - [agentskills.io/skill-creation/best-practices](https://agentskills.io/skill-creation/best-practices)
> - [agentskills.io/skill-creation/evaluating-skills](https://agentskills.io/skill-creation/evaluating-skills)
>
> **Contexte** : ces guides s'adressent aux *Claude Skills* au sens strict. Les agents `kp-agents` sont distribués comme **skills du plugin Claude Code** (via `plugins/kp-agents/skills/<nom>/SKILL.md`), et comme règles Cursor / skills Codex. Les recommandations ci-dessous sont donc applicables directement — en particulier pour la cible Claude Code où le mécanisme de *progressive disclosure* joue pleinement.

### A. Optimisation du champ `description` (trigger reliability)

**Constat général** : les 7 agents ont des descriptions **descriptives** ("KeyProd X: do Y and Z") plutôt qu'**impératives** ("Use this skill when..."). Elles ne citent ni les **situations de déclenchement**, ni les **formulations implicites** dans lesquelles l'utilisateur n'emploie pas le vocabulaire de l'agent. C'est la principale cause de sous-déclenchement en progressive disclosure.

#### Principes appliqués

1. Phrasing **impératif** : "Use this skill when the user…"
2. Intent **utilisateur**, pas mécanique interne.
3. **Pushy** : lister des contextes explicites + cas où le domaine n'est pas nommé.
4. **< 1024 caractères**.
5. Mentionner les **artefacts produits** (epic, story, ADR, GO/NO-GO, `docs/INDEX.md`…) pour ancrer la décision d'activation.

#### Descriptions proposées (avant / après)

| Agent | Avant | Après proposé |
|-------|-------|---------------|
| **brainstorm** | "KeyProd Brainstorm: explore approaches, challenge assumptions, and structure next steps" | "Use this skill when the user wants to explore an idea, problem, or opportunity before committing to a solution — even if they don't say 'brainstorm'. Triggers on: 'I'm thinking about…', 'what if we…', 'not sure how to approach…', 'challenge my assumption on…'. Produces a persistent file in `docs/ideas/<theme>.md` (draft → exploring → qualified / rejected). Use methods like 5 Whys, SCAMPER, First Principles. Do NOT use for already-qualified ideas ready to spec — those go to the product skill." |
| **product** | "KeyProd Product: deepen ideas into roadmap, epics, and stories with clear acceptance criteria" | "Use this skill when the user needs to turn an idea, request, or opportunity into a roadmap, an epic, or a user story with acceptance criteria — even if they just ask to 'write a story', 'plan the next phase', or 'break this down'. Triggers on discussions of product vision, personas, KPIs, MoSCoW/RICE prioritization, or when `docs/project/roadmap.md` / `docs/project/epics/` must be created or updated. Skip if the task is purely technical design (→ architect skill) or purely implementation (→ developer skill)." |
| **architect** | "KeyProd Architect: design technical solutions, evaluate trade-offs, and document architecture decisions" | "Use this skill when the user asks for a technical design, a stack choice, a trade-off analysis, an ADR, or when an epic / story requires an architectural decision before coding. Triggers on: 'how should we build…', 'which library / pattern / infra for…', 'document the decision to…', non-functional requirements (latency, volumetry, security). Produces or updates `docs/architect.md`, `docs/features/<group>/architect.md`, and ADRs. Skip for pure implementation tasks (→ developer) or pure product framing (→ product)." |
| **developer** | "KeyProd Developer: implement features following a story or epic specification from docs/" | "Use this skill when the user asks to implement, code, or build a feature that has a story or an epic documented under `docs/project/epics/`. Triggers on: 'implement S-XXXX', 'code this epic', 'add feature X described in the story', or any request naming a story / epic ID. Enforces a plan-then-validate workflow, branch/commit/PR config, and updates `status: IN PROGRESS → REVIEW / DONE` with a `## Implémentation` section. Do NOT use for brainstorming, spec writing, architecture design, or review." |
| **review** | "KeyProd Review: review, test and validate code implemented by the developer agent. Emits a GO/NO-GO verdict and writes improvement recommendations directly into the story file." | "Use this skill when the user asks to review, validate, or verify code that was just implemented — especially when a story is in `status: REVIEW` or the user says 'can you check this', 'is this ready to merge', 'run the tests and tell me if it's good'. Produces a GO / NO-GO verdict, tests executed, and a `## Review` section with P1/P2/P3 recommendations inside the story file. NEVER modifies source code. Skip if the task is to fix or write new code — that's the developer skill." |
| **documentation** | "KeyProd Documentation: analyze existing docs and code, identify divergences, propose updates, and maintain project documentation after validation" | "Use this skill whenever the user wants to audit, update, or consolidate project documentation — `docs/`, `README.md`, `CLAUDE.md`, `CHANGELOG.md`, component READMEs. Triggers on: 'is the doc up to date', 'document X', 'the README is wrong about Y', 'what's missing in the docs', after a feature ships, after renaming a flag / file / convention. Sole owner of `docs/INDEX.md`. Always compares documented state to observed code before writing. Skip if the task is writing new specs (→ product) or new design (→ architect)." |
| **ux-ui** | "KeyProd UX/UI: design intuitive user experiences, define personas, craft modern and distinctive visual identity. Works alongside or after the Product agent to shape how features feel and look." | "Use this skill when the user wants to design a screen, a user flow, a persona, a visual identity, or a design system — even if they don't name 'UX' or 'UI' explicitly. Triggers on: 'how should this screen look', 'define personas for…', 'pick a color palette', 'audit this interface', 'what's the happy path for…'. Produces `docs/features/<group>/ux.md`, `docs/features/<group>/ui.md`, and `docs/design-system.md`. Enforces WCAG 2.1 AA. Anti-generic — never defaults to Material/Bootstrap without justification." |

> ⚠️ Les descriptions proposées sont en **anglais** (pratique recommandée par agentskills.io pour maximiser le trigger matching multi-langues). Variante française possible si la cible est exclusivement francophone.

**Limite assumée** : sans *eval set* exécuté, impossible de garantir que ces descriptions améliorent réellement le taux de déclenchement. À valider empiriquement (voir section C).

### B. Corps des agents — bonnes pratiques structurelles

#### B.1 Ajouter ce que le modèle ne sait pas, omettre ce qu'il sait

**Candidats à élagage** (contenu qu'un modèle senior ferait naturellement) :

| Agent | Passage générique à élaguer / reformuler |
|-------|-------------------------------------------|
| brainstorm | "Ne confonds pas exploration et décision définitive" — générique. Garder seulement si lié à un comportement observé à corriger. |
| product | "Ne commence jamais à coder sans plan" — n'a pas sa place ici (c'est du developer). |
| architect | "Tout choix technique doit être justifié (pas de 'best practice' sans contexte)" — reformuler en règle concrète (ex: "cite la contrainte projet qui motive le choix"). |
| developer | "Écris du code propre et testé", "Privilégie les solutions simples" — vague, à remplacer par des gotchas projet. |
| review | "Sois factuel et précis" — évident ; à remplacer par "cite `fichier:ligne` pour chaque finding". |
| ux-ui | "Une interface belle mais confuse est un échec" — slogan ; déjà couvert par la philosophie "utilisateur d'abord". |

#### B.2 Créer une section "Gotchas" dans chaque agent

Les guides insistent : le contenu à plus forte valeur ajoutée est une **liste de gotchas projet** — faits contre-intuitifs qui corrigent des erreurs spécifiques au contexte.

**Gotchas candidats pour `kp-agents`** (à enrichir au fil de l'usage) :

**Transversal (tous agents)** :
- Ne jamais écrire dans `plugins/kp-agents/skills/` ni dans `dist/` — tout est regénéré par `sync.sh`.
- `docs/INDEX.md` appartient exclusivement à l'agent `documentation` ; les autres le consultent mais ne le modifient pas.
- La numérotation des stories repart de `S-0001` **pour chaque epic** (local), tandis que les epics sont globales (`E-0001`, `E-0002`…).
- Les epics archivées vivent sous `docs/project/epics/_archives/` — ne jamais y créer de nouvelle story, seulement les lire pour contexte.

**Developer** :
- Pas de worktree git — une seule branche de travail par epic.
- Le cadrage (branche, commits, PR) est validé **avant** le chargement de contexte, pas après.

**Review** :
- Si la story n'a pas de section `## Implémentation`, la review est refusée et renvoyée au developer.
- Ne jamais modifier le code source — seule l'écriture de la section `## Review` est autorisée.

**Documentation** :
- `README.md` et `CLAUDE.md` (racine) sont **dans** le périmètre documentaire et **dans** l'INDEX — règle systématique, pas conditionnelle.
- Mermaid : pas de guillemets dans les labels d'arêtes, pas de texte multi-lignes dans les noeuds.

**Proposition** : ajouter une section `## Gotchas` (5-10 items max) à chaque agent, alimentée au fil du temps par les corrections utilisateur observées.

#### B.3 Progressive disclosure — déjà partiellement appliquée via `includes/`

Le mécanisme `{{include:nom}}` résolu par `sync.sh` **équivaut fonctionnellement** à la *progressive disclosure* recommandée (déporter le contenu détaillé dans des fichiers séparés) — avec une différence : chez nous les includes sont **inlinés à la compilation**, pas chargés à la demande par le modèle. Le gain de tokens en runtime est donc **nul**.

**Améliorations possibles** :
- Pour les agents les plus longs (product 239L, documentation 231L), évaluer l'usage de **vrais fichiers référence** (équivalent `references/<nom>.md` en ligne avec agentskills.io) que l'agent charge uniquement quand un cas précis se présente : ex. `references/index-template.md`, `references/story-template.md`. Le SKILL.md principal dirait : "Si tu dois écrire une story, lis `references/story-template.md` d'abord".
- Avantage : réduit la taille du `SKILL.md` chargé systématiquement.
- Inconvénient : complexité `sync.sh` (devrait copier aussi les fichiers référence aux 3 cibles Claude / Cursor / Codex).
- **Recommandation** : ne pas traiter en P1. À considérer uniquement si un agent dépasse ~350 lignes compilées.

#### B.4 Provide defaults, not menus

`brainstorm` présente **7 méthodes** (5 Whys, SCAMPER, Six Thinking Hats, Starbursting, First Principles, Worst Possible Idea, Mind Mapping) avec pour seule consigne "choisis la plus adaptée". C'est un menu.

**Proposition** : définir un **défaut explicite** + 2-3 alternatives signalées selon le contexte, plutôt que 7 options équivalentes. Exemple : "Par défaut, commence par **Starbursting** (Qui/Quoi/Où/Quand/Pourquoi/Comment). Bascule vers **5 Whys** si le problème semble symptomatique, **First Principles** si les hypothèses implicites bloquent. Autres méthodes (SCAMPER, Six Hats…) seulement sur demande explicite."

#### B.5 Procédures plutôt que déclarations

Plusieurs règles des agents sont **déclaratives** ("Les critères d'acceptation doivent être testables") sans **procédure** pour les produire. Suggestion : compléter chaque règle clé par un exemple ou un test de vérification.

- `product` fait déjà bien avec l'exemple "bon critère vs trop vague" ✅
- `review` fait déjà bien avec l'exemple JWT localStorage vs httpOnly cookie ✅
- `architect` fait déjà bien avec l'exemple d'ADR-003 WebSocket ✅
- `developer` gagnerait à ajouter un exemple de "section Validation par critère" bien remplie vs. mal remplie.
- `ux-ui` gagnerait à ajouter un exemple de persona bien calibrée vs. générique.

### C. Évaluation (sans exécution) — structure proposée

Les guides recommandent un **eval set** par skill pour mesurer le trigger rate (description) et la qualité de sortie (body). Je ne lance pas de tests ici ; je propose la **structure** à mettre en place.

#### C.1 Tests de déclenchement (trigger evals)

Pour chaque agent, prévoir un fichier `agents/_evals/<nom>/trigger_queries.json` contenant ~20 prompts (10 should-trigger / 10 should-not-trigger), avec près-manqués volontaires.

**Exemple pour `developer`** :

```json
[
  { "query": "implémente la story S-0003 de l'epic E-0002", "should_trigger": true },
  { "query": "code-moi la feature décrite dans docs/project/epics/E-0001-Auth/S-0002-Login.md", "should_trigger": true },
  { "query": "ajoute le endpoint /health qu'on a spécifié hier", "should_trigger": true },
  { "query": "fix ce bug en prod", "should_trigger": false, "reason": "pas de story documentée → cadrage requis" },
  { "query": "review le code de la PR #42", "should_trigger": false, "reason": "near-miss : c'est review, pas developer" },
  { "query": "explique-moi comment fonctionne ce fichier", "should_trigger": false }
]
```

Les près-manqués (`review` vs `developer`, `product` vs `brainstorm`, `ux-ui` vs `product`) sont les cas les plus informatifs.

#### C.2 Tests de qualité de sortie (output evals)

Pour chaque agent, prévoir `agents/_evals/<nom>/output_evals.json` avec :
- `prompt` : une demande réaliste
- `expected_output` : description humaine du succès
- `assertions` : 3-6 vérifications objectives

**Exemple pour `product`** (demande : "rédige la story de connexion par email magic-link") :
```json
{
  "assertions": [
    "Le fichier est créé sous docs/project/epics/E-XXXX-<Nom>/S-XXXX-<Nom>.md",
    "Le frontmatter contient status, story-id, epic-id, date",
    "La section 'Scénarios' couvre au moins nominal + un cas d'erreur",
    "Au moins 4 critères d'acceptation vérifiables (Given/When/Then)",
    "Une section 'Hypothèses / Questions ouvertes' est présente",
    "Aucun critère n'est formulé par un verbe vague ('gérer', 'bien')"
  ]
}
```

#### C.3 Baseline (with_skill vs without_skill)

Les guides insistent : comparer **avec le skill** vs **sans le skill**. Pour nos agents, le "sans skill" = Claude Code nu avec le même prompt. Un delta de pass rate > 0.3 justifie l'investissement skill ; un delta < 0.1 suggère que l'agent ajoute du bruit sans valeur.

#### C.4 Intégration dans le projet (proposition non implémentée)

- Créer `agents/_evals/` (ignoré par `sync.sh` — ne doit pas être distribué aux cibles).
- Ajouter un flag `./sync.sh --eval <agent>` qui prépare le workspace et laisse l'exécution à l'utilisateur (le projet n'a pas d'API Anthropic configurée).
- Documenter dans `CLAUDE.md` que les evals sont optionnels, destinés aux mainteneurs, pas aux utilisateurs.

### D. Nouvelles recommandations priorisées

Ces recommandations s'ajoutent aux P1/P2/P3 déjà listés plus haut et sont préfixées **B** pour "Best-practices".

| ID | Action | Priorité | Impact |
|----|--------|----------|--------|
| **B1** | Réécrire les 7 champs `description` en phrasing impératif + triggers explicites (cf. tableau A) | **P1** | Taux de déclenchement Claude Code ↑, désambiguïsation entre agents voisins |
| **B2** | Ajouter une section `## Gotchas` dans chaque agent (5-10 items), alimentée au fil du temps | **P1** | Capture la connaissance projet que le modèle n'a pas ; correction directe des erreurs observées |
| **B3** | Transformer la liste des 7 méthodes de `brainstorm` en défaut + alternatives (B.4) | **P2** | Sortie plus prévisible, moins d'indécision |
| **B4** | Élaguer le contenu générique identifié en B.1 (une passe par agent) | **P2** | Réduction tokens, focus sur la valeur spécifique projet |
| **B5** | Ajouter des exemples "bien vs mal" manquants : `developer` (Validation par critère), `ux-ui` (persona) | **P3** | Procédural > déclaratif, aligne les agents déjà exemplaires (architect, product, review) |
| **B6** | Mettre en place la structure `agents/_evals/` (trigger + output) avec ~20 queries par agent | **P3** | Prépare le terrain pour mesurer objectivement l'effet des modifs P1/P2 |
| **B7** | Évaluer le passage à des fichiers `references/` pour les agents > 350L compilés (product, documentation) | **P3** | Optimisation tokens runtime, uniquement si seuil franchi |

### E. Interaction avec les recommandations existantes

| Recommandation existante | Best practice alignée | Combinaison suggérée |
|--------------------------|------------------------|----------------------|
| T1 / O5.1 / O7.1 (uniformiser Activation) | "Add what the agent lacks" — le bloc actuel est partiellement générique | Traiter T1 **en même temps** que B1 : un seul passage multi-agents |
| O2.1 (remplacer templates inline par includes) | "Progressive disclosure" + "lean SKILL.md" | Traiter O2.1 et B7 dans la même évaluation quand product sera refactoré |
| T3 (include dépendances) | "Omit what the agent knows" — la règle est spécifique projet, donc à garder ; mais factoriser | Garder T3 tel quel, c'est un gotcha transversal légitime |
| O4.1 (fusionner bilan developer) | "Moderate detail" — éviter la redondance | B4 peut rendre la fusion plus nette encore |

### F. Limites de cette annexe

- **Pas de mesure empirique** : les propositions B1–B7 sont fondées sur les heuristiques des 3 guides, pas sur un eval set exécuté. Les gains réels sont à confirmer.
- **Le champ `description`** est utilisé différemment par Claude Code (plugin marketplace), Cursor (rules) et Codex (skills). Les descriptions optimisées pour le trigger Claude peuvent être sur-dimensionnées pour Cursor/Codex. À vérifier en rejouant `sync.sh` après application de B1.
- **Le mécanisme `{{include:}}` de `sync.sh`** inline à la compilation : il n'équivaut pas totalement à la *progressive disclosure* runtime des skills natifs (B.3). Cette nuance limite le gain de tokens en contexte, mais conserve la modularité côté source.

---

## Mise à jour — état post-refactor (avril 2026)

Cette section clôt l'audit : la majorité des recommandations P1/P2 a été appliquée. Les gains sont mesurés en lignes de `SKILL.md` compilé (source = `plugins/kp-agents/skills/<agent>/SKILL.md`).

### Recommandations traitées

| ID | Statut | Commit | Impact observé |
|----|--------|--------|----------------|
| **B1** — descriptions impératives + triggers | ✅ appliqué | S-0002 (rewrite), cfe8f8a (traduction FR) | Descriptions en français impératif, triggers explicites (déclencheurs, à ne pas utiliser) |
| **B2** — section `## Gotchas` par agent | ✅ appliqué | S-0003 | 5-8 gotchas spécifiques projet par agent, include `gotchas-transverses` partagé |
| **B3** — brainstorm : défaut + alternatives | ✅ appliqué | S-0006 | Starbursting par défaut, 5 Whys / First Principles secondaires, le reste sur demande |
| **B4** — élagage contenu générique | ✅ appliqué | S-0004, S-0005, S-0006, a99124a | Retrait des sections `## Règles` redondantes, fusion dans Gotchas |
| **B5** — exemples bien/mal manquants | ✅ appliqué | S-0005 (developer), S-0006 (ux-ui) | Exemples traçables `Validation par critère`, persona calibré |
| **B6** — structure `agents/_evals/` | ✅ appliqué | S-0007 | Scaffolding trigger + output pour developer et review |
| **B7** — progressive disclosure via `references/` | ✅ appliqué | 78d31cb | Mécanisme `{{ref:X}}` : templates lourds chargés à la demande côté plugin Claude |
| **T1** — activation uniformisée | ✅ appliqué | S-0001 | Include unique, version courte (4 puces) |
| **T2** — templates inline → includes | ✅ appliqué | S-0004 + 78d31cb | Templates externalisés via `{{ref:X}}` |
| **T3** — règle versions factorisée | ✅ appliqué | S-0001 | Include `dependency-versions` partagé par architect, developer, review |
| **T6** — `/simplify` multi-cibles | ✅ appliqué | S-0005 | Formulation portable (Claude Code / Cursor / Codex / passe manuelle) |

### État final des agents (source `agents/` + compilé `plugins/kp-agents/skills/`)

| Agent | Source (L) | Compilé (L) | Cible <300 L | Statut |
|-------|-----------:|------------:|:------------:|--------|
| brainstorm | 131 | 206 | ✅ | Finalisé |
| architect | 143 | 220 | ✅ | Finalisé |
| ux-ui | 164 | 241 | ✅ | Finalisé |
| documentation | 167 | 244 | ✅ | Finalisé |
| review | 170 | 261 | ✅ | Finalisé |
| developer | 189 | 280 | ✅ | Finalisé |
| product | 112 | 413 | ⚠️ 300-500 | Acceptable (templates inlined côté plugin via refs externes uniquement pour epic/story) |

Total compilé : **1865 lignes** sur 7 agents (moyenne 266 L) vs. ~2500 L avant refactor.

### Récap court par agent

- **brainstorm** — facilitateur d'exploration, Starbursting par défaut, sauvegarde progressive `docs/ideas/<theme>.md` avec cycle draft → exploring → qualified | rejected.
- **product** — PM qui transforme idées en roadmap / epics / stories avec critères d'acceptation testables. Mode init si `docs/` vierge. Numérotation E globale, S locale à l'epic.
- **architect** — conception technique, ADR append-only, exemples ADR chiffrés, mode libre ou mode epic. Impose vérif internet des versions de dépendances.
- **ux-ui** — design UX/UI anti-générique (WCAG 2.1 AA non négociable, 44×44 px tactile min), personas obligatoires avant de dessiner, tokens CSS + breakpoints dans les specs.
- **developer** — implémentation rigoureuse spec → plan → validation → simplification → bilan. Cadrage branche/commits/PR mémorisé. Pas de worktree.
- **review** — verdict GO/NO-GO explicite, écrit uniquement dans `## Review` de la story, cite `file.ts:42`, recommandations P1/P2/P3.
- **documentation** — seul propriétaire de `docs/INDEX.md`, périmètre inclut `README.md` et `CLAUDE.md` racine, compare systématiquement doc et code avant d'écrire.

### Reliquats non traités

- Mesure empirique via eval set (scaffolding posé mais runs non exécutés — nécessite API Anthropic configurée).
- `product` reste à 413 L compilé : acceptable mais plafond <500 L. Amélioration envisageable si `docs-structure` était lui-même découpé en `docs-structure-light` + `{{ref:*-template}}` (déjà partiellement fait).
