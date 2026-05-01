---
title: Guide des agents
date: 2026-04-18
status: active
author: documentation-agent
---

# Guide des agents

> Description de chaque agent et visualisation de leurs workflows.
> Les traits pleins (`-->`) indiquent les chemins **obligatoires**. Les traits pointillés (`-.->`) indiquent les chemins **facultatifs**.

> **Invocation** : via le plugin Claude Code, les agents sont namespacés sous la forme `/kp-agents:<nom>`. Dans Cursor, ils apparaissent sous `@kp-<nom>`. Dans Codex, ce sont les skills `kp-<nom>`.

---

## Vue d'ensemble

Le projet expose **8 agents** : 7 agents génériques pour le workflow de développement (de l'exploration d'une idée à la validation du code implémenté) + 1 agent transversal `setup` pour la configuration projet (`.kp-agents.yml` / `.kp-agents.local.yml`). Les agents sont indépendants mais chaînables via un bloc de handoff structuré.

---

## Routing — Quand appeler quel agent

Table de référence machine-readable. Signaux = mots-clés ou contexte déclencheur. `requires` = condition nécessaire. `anti` = cas d'exclusion explicite.

| Signal déclencheur | Agent | Requires | Anti (→ autre agent) |
|---|---|---|---|
| « idée », « et si on », « je réfléchis à », « challenge mon hypothèse », « brainstorm » | `brainstorm` | — | Idée déjà qualifiée avec critères d'acceptation → `product` |
| « story », « epic », « roadmap », « spec », « user story », « critères d'acceptation », « priorise », « découpe » | `product` | — | Implémentation de code → `developer` |
| « architecture », « ADR », « choix technique », « quelle lib », « quel pattern », « latence », « volumétrie », besoin non-fonctionnel | `architect` | — | Implémentation pure → `developer` ; cadrage produit → `product` |
| « implémente », « code », « développe », « ajoute la feature », ID story `S-XXXX`, ID epic `E-XXXX` | `developer` | Story ou epic documentée dans `docs/` | Rédiger une spec → `product` ; design archi → `architect` |
| « review », « valide », « vérifie », « c'est prêt ? », « peux-tu vérifier », story en statut `REVIEW` | `review` | Story implémentée | Corriger ou écrire du code → `developer` |
| « écran », « parcours utilisateur », « persona », « wireframe », « palette », « identité visuelle », « UX », « UI » | `ux-ui` | — | Spec produit → `product` ; implémentation CSS/front → `developer` |
| « audite la doc », « documente X », « la doc est fausse », « qu'est-ce qui manque », « INDEX », post-implémentation | `documentation` | — | Nouvelle spec → `product` ; nouveau design → `architect` |
| « configure les sources », « setup le projet », « où vit la doc », config manquante détectée par un agent | `setup` | — | — |

> Cette table est lue par les agents via `context.routing` (`.kp-context.yml`). Elle remplace les indications de routing textuelles dispersées dans chaque skill.

---

## Pipeline développement — Vue globale

```mermaid
flowchart LR
    S["/kp-agents:setup"]
    B["/kp-agents:brainstorm"]
    P["/kp-agents:product"]
    A["/kp-agents:architect"]
    D["/kp-agents:developer"]
    R["/kp-agents:review"]
    UX["/kp-agents:ux-ui"]
    DOC["/kp-agents:documentation"]
    FIN((DONE))

    S -->|config prête| P
    B -->|idée qualifiée| P
    P -->|epics et stories| A
    A -->|design technique| D
    D -->|implémentation| R
    R -->|GO| FIN

    R -->|NO-GO| D

    P -.->|besoin UX| UX
    UX -.->|specs visuelles| D
    R -.->|écarts documentaires| DOC
    D -.->|écarts détectés| DOC
    P -.->|config manquante| S
    A -.->|config manquante| S
    D -.->|config manquante| S

    style S fill:#f3e5f5,stroke:#8E24AA
    style B fill:#e8f4fd,stroke:#2196F3
    style P fill:#e8f4fd,stroke:#2196F3
    style A fill:#e8f4fd,stroke:#2196F3
    style D fill:#e8f4fd,stroke:#2196F3
    style R fill:#e8f4fd,stroke:#2196F3
    style UX fill:#fff3e0,stroke:#FF9800
    style DOC fill:#fff3e0,stroke:#FF9800
    style FIN fill:#c8e6c9,stroke:#4CAF50
```

**Chemin obligatoire** : brainstorm --> product --> architect --> developer --> review
**Agents transversaux** (facultatifs) : ux-ui (entre product et developer), documentation (après review ou developer), setup (auto-redirect depuis tout agent détectant une config manquante)

---

## Agents — Détail

---

### 1. Brainstorm (`/kp-agents:brainstorm`)

**Rôle** : facilitateur de brainstorming. Explore une idée sous tous ses angles, propose des approches créatives et structure la réflexion pour la faire avancer concrètement.

**Sortie** : fichier `docs/ideas/<thème>.md` mis à jour progressivement.

```mermaid
flowchart TD
    START([Idée brute]) --> CHECK{docs/ideas existe ?}
    CHECK -->|oui| REPRISE[Reprendre la réflexion existante]
    CHECK -->|non| COMP
    REPRISE --> COMP

    COMP[1. Compréhension du problème]
    COMP --> STOP1{Réponses utilisateur ?}
    STOP1 -->|oui| EXPLO

    EXPLO[2. Exploration divergente — 3 approches min]
    EXPLO --> STOP2{Retour utilisateur ?}
    STOP2 -->|oui| CRIT

    CRIT[3. Analyse critique — hypothèses et contraintes]
    CRIT --> STOP3{Validation utilisateur ?}
    STOP3 -->|oui| STRUCT

    STRUCT[4. Structuration — synthèse et next steps]
    STRUCT --> OUT

    OUT{Relais ?}
    OUT -->|sujet mature| PRODUCT["/kp-agents:product"]
    OUT -.->|incertitudes techniques| ARCHITECT["/kp-agents:architect"]

    style COMP fill:#e3f2fd,stroke:#1976D2
    style EXPLO fill:#e3f2fd,stroke:#1976D2
    style CRIT fill:#e3f2fd,stroke:#1976D2
    style STRUCT fill:#e3f2fd,stroke:#1976D2
    style PRODUCT fill:#c8e6c9,stroke:#4CAF50
    style ARCHITECT fill:#fff3e0,stroke:#FF9800
```

---

### 2. Product (`/kp-agents:product`)

**Rôle** : Product Manager. Transforme des idées brutes en spécifications produit actionnables : vision, roadmap, epics et stories avec critères d'acceptation.

**Sortie** : `docs/product.md`, `docs/project/roadmap.md`, epics et stories dans `docs/project/epics/`.

```mermaid
flowchart TD
    START([Idée qualifiée ou besoin]) --> IDEAS{Brainstorm existant ?}
    IDEAS -->|oui| READ_IDEA[Lire docs/ideas/thème.md]
    IDEAS -->|non| CADRAGE
    READ_IDEA --> CADRAGE

    CADRAGE[1. Cadrage produit — vision, cibles, KPIs]
    CADRAGE --> STOP_C{Infos suffisantes ?}
    STOP_C -->|non| QUESTIONS[Poser les questions bloquantes]
    QUESTIONS --> CADRAGE
    STOP_C -->|oui| ROADMAP

    ROADMAP[2. Roadmap — phases, jalons, priorités]
    ROADMAP --> EPICS

    EPICS[3. Epics — objectif, périmètre, dépendances]
    EPICS --> STORIES

    STORIES[4. Stories — scénarios et critères d'acceptation]
    STORIES --> CHECK_Q[5. Contrôle de complétude]
    CHECK_Q --> PRODUCT_MD[6. Mise à jour docs/product.md]
    PRODUCT_MD --> OUT

    OUT{Relais ?}
    OUT -->|design technique| ARCHITECT["/kp-agents:architect"]
    OUT -.->|besoin UX| UX["/kp-agents:ux-ui"]
    OUT -.->|doc à mettre à jour| DOC["/kp-agents:documentation"]

    style CADRAGE fill:#e3f2fd,stroke:#1976D2
    style ROADMAP fill:#e3f2fd,stroke:#1976D2
    style EPICS fill:#e3f2fd,stroke:#1976D2
    style STORIES fill:#e3f2fd,stroke:#1976D2
    style CHECK_Q fill:#e3f2fd,stroke:#1976D2
    style PRODUCT_MD fill:#e3f2fd,stroke:#1976D2
    style ARCHITECT fill:#c8e6c9,stroke:#4CAF50
    style UX fill:#fff3e0,stroke:#FF9800
    style DOC fill:#fff3e0,stroke:#FF9800
```

---

### 3. Architect (`/kp-agents:architect`)

**Rôle** : Architecte logiciel senior. Conçoit des solutions techniques solides, évalue les compromis et documente les décisions d'architecture (ADR).

**Modes** : libre (réflexion technique sans epic) ou epic (conception liée à une epic produit).

**Sortie** : `docs/architect.md`, `docs/features/<group>/architect.md`, ADR.

```mermaid
flowchart TD
    START([Epics et stories ou sujet technique]) --> MODE{Mode ?}
    MODE -->|epic| READ_EPIC[Lire epic, stories, architect.md, product.md]
    MODE -->|libre| READ_IDEAS[Consulter docs/ideas/ si existant]
    READ_EPIC --> ANALYSE
    READ_IDEAS --> ANALYSE

    ANALYSE[1. Analyse du contexte et contraintes]
    ANALYSE --> STOP_A{Infos suffisantes ?}
    STOP_A -->|non| QUESTIONS[Poser les questions bloquantes]
    QUESTIONS --> ANALYSE
    STOP_A -->|oui| OPTIONS

    OPTIONS[2. Exploration des options — avantages, inconvénients]
    OPTIONS --> DESIGN

    DESIGN[3. Design technique — diagrammes, modèle de données, stack]
    DESIGN --> ADR

    ADR[4. ADR — décisions structurantes documentées]
    ADR --> OUT

    OUT{Relais ?}
    OUT -->|implémentation| DEV["/kp-agents:developer"]
    OUT -.->|questions produit| PRODUCT["/kp-agents:product"]
    OUT -.->|doc obsolète| DOC["/kp-agents:documentation"]

    style ANALYSE fill:#e3f2fd,stroke:#1976D2
    style OPTIONS fill:#e3f2fd,stroke:#1976D2
    style DESIGN fill:#e3f2fd,stroke:#1976D2
    style ADR fill:#e3f2fd,stroke:#1976D2
    style DEV fill:#c8e6c9,stroke:#4CAF50
    style PRODUCT fill:#fff3e0,stroke:#FF9800
    style DOC fill:#fff3e0,stroke:#FF9800
```

---

### 4. Developer (`/kp-agents:developer`)

**Rôle** : Développeur senior. Implémente les fonctionnalités en suivant rigoureusement les spécifications produit et techniques documentées.

**Modes** : story (une story) ou epic (toutes les stories séquentiellement).

**Sortie** : code implémenté, stories mises à jour avec sections Implémentation et Validation.

```mermaid
flowchart TD
    START([Story ou epic à implémenter]) --> CADRAGE

    CADRAGE[0. Cadrage — périmètre, branche, stratégie de commit]
    CADRAGE --> STOP_C{Périmètre validé ?}
    STOP_C -->|non| ASK[Clarifier avec l'utilisateur]
    ASK --> CADRAGE
    STOP_C -->|oui| CTX

    CTX[1. Chargement du contexte — specs et codebase]
    CTX --> PLAN

    PLAN[2. Plan d'implémentation — fichiers, ordre, tests]
    PLAN --> STOP_P{Plan validé ?}
    STOP_P -->|non| PLAN
    STOP_P -->|oui| IMPL

    IMPL[3. Implémentation — code, tests, suivi des écarts]
    IMPL --> VALID

    VALID[4. Validation — critères d'acceptation, tests exécutés]
    VALID --> SIMPLIFY

    SIMPLIFY[5. Simplification du code modifié]
    SIMPLIFY --> BILAN

    BILAN[6. Bilan post-implémentation]
    BILAN --> OUT

    OUT{Relais ?}
    OUT -->|review recommandée| REVIEW["/kp-agents:review"]
    OUT -.->|écarts documentaires| DOC["/kp-agents:documentation"]

    style CADRAGE fill:#e3f2fd,stroke:#1976D2
    style CTX fill:#e3f2fd,stroke:#1976D2
    style PLAN fill:#e3f2fd,stroke:#1976D2
    style IMPL fill:#e3f2fd,stroke:#1976D2
    style VALID fill:#e3f2fd,stroke:#1976D2
    style SIMPLIFY fill:#e3f2fd,stroke:#1976D2
    style BILAN fill:#e3f2fd,stroke:#1976D2
    style REVIEW fill:#c8e6c9,stroke:#4CAF50
    style DOC fill:#fff3e0,stroke:#FF9800
```

---

### 5. Review (`/kp-agents:review`)

**Rôle** : Reviewer senior. Relit, teste et valide le code produit par le Developer. Émet un verdict GO/NO-GO et écrit les recommandations d'amélioration dans la story.

**Modes** : story (une story) ou epic (toutes les stories en REVIEW/DONE).

**Sortie** : section Review ajoutée dans la story, verdict GO/NO-GO.

```mermaid
flowchart TD
    START([Story implémentée]) --> CTX

    CTX[1. Chargement du contexte]
    CTX --> AUTO

    AUTO[2. Revue automatisée si outils disponibles]
    AUTO --> CODE_REVIEW

    CODE_REVIEW[3. Revue de code — fonctionnel, qualité, archi, sécu]
    CODE_REVIEW --> TESTS

    TESTS[4. Tests — exécution et couverture]
    TESTS --> VERDICT

    VERDICT{5. Verdict}
    VERDICT -->|GO| RECO
    VERDICT -->|NO-GO| BLOQUANTS

    BLOQUANTS[Lister les points bloquants]
    BLOQUANTS --> RECO

    RECO[6. Recommandations catégorisées P1/P2/P3]
    RECO --> WRITE[7. Écriture dans la story]
    WRITE --> OUT

    OUT{Relais ?}
    VERDICT -->|GO, story DONE| FIN((DONE))
    VERDICT -->|NO-GO, story IN PROGRESS| DEV["/kp-agents:developer"]
    WRITE -.->|écarts documentaires| DOC["/kp-agents:documentation"]

    style CTX fill:#e3f2fd,stroke:#1976D2
    style AUTO fill:#e3f2fd,stroke:#1976D2
    style CODE_REVIEW fill:#e3f2fd,stroke:#1976D2
    style TESTS fill:#e3f2fd,stroke:#1976D2
    style RECO fill:#e3f2fd,stroke:#1976D2
    style WRITE fill:#e3f2fd,stroke:#1976D2
    style BLOQUANTS fill:#ffcdd2,stroke:#E53935
    style FIN fill:#c8e6c9,stroke:#4CAF50
    style DEV fill:#fff3e0,stroke:#FF9800
    style DOC fill:#fff3e0,stroke:#FF9800
```

---

### 6. Documentation (`/kp-agents:documentation`)

**Rôle** : responsable documentation technique et produit. Analyse la documentation existante, identifie les divergences avec le code, propose des corrections et maintient la documentation après validation.

**Modes** : interactif, analyse de code, ou maintenance documentaire.

**Sortie** : documents mis à jour dans `docs/`, `docs/INDEX.md` maintenu.

```mermaid
flowchart TD
    START([Demande documentaire ou écarts signalés]) --> MODE{Mode ?}
    MODE -->|interactif| CLARIFY[Clarifier objectif et public cible]
    MODE -->|analyse de code| READ_CODE[Lire le code et la doc associée]
    MODE -->|maintenance| SCOPE[Identifier le périmètre impacté]
    CLARIFY --> ANALYSE
    READ_CODE --> ANALYSE
    SCOPE --> ANALYSE

    ANALYSE[1. Analyse du contexte — INDEX.md, sources de vérité]
    ANALYSE --> AUDIT

    AUDIT[2. Audit de l'existant — git log, git diff, doc]
    AUDIT --> DIVERGENCES

    DIVERGENCES[3. Analyse des divergences — existant vs réalité]
    DIVERGENCES --> STOP_V{Validation demandée ?}
    STOP_V -->|oui| WAIT[Attendre validation]
    STOP_V -->|non| MAJ
    WAIT --> MAJ

    MAJ[4. Mise à jour — corrections ciblées]
    MAJ --> INDEX[5. Mise à jour INDEX.md]
    INDEX --> OUT

    OUT{Relais ?}
    OUT -.->|spécification future| PRODUCT["/kp-agents:product"]
    OUT -.->|décision technique| ARCHITECT["/kp-agents:architect"]

    style ANALYSE fill:#e3f2fd,stroke:#1976D2
    style AUDIT fill:#e3f2fd,stroke:#1976D2
    style DIVERGENCES fill:#e3f2fd,stroke:#1976D2
    style MAJ fill:#e3f2fd,stroke:#1976D2
    style INDEX fill:#e3f2fd,stroke:#1976D2
    style PRODUCT fill:#fff3e0,stroke:#FF9800
    style ARCHITECT fill:#fff3e0,stroke:#FF9800
```

---

### 7. UX/UI (`/kp-agents:ux-ui`)

**Rôle** : Designer UX/UI senior. Conçoit des interfaces intuitives et visuellement distinctives. Travaille entre Product et Developer.

**Modes** : discovery (exploration UX), feature (conception liée à une epic) ou audit (analyse critique).

**Sortie** : `docs/features/<group>/ux.md`, `docs/features/<group>/ui.md`, `docs/design-system.md`.

```mermaid
flowchart TD
    START([Besoin UX depuis Product ou demande directe]) --> MODE{Mode ?}
    MODE -->|discovery| QUESTIONS[Cadrer personas et usages]
    MODE -->|feature| READ_EPIC[Lire epic et stories]
    MODE -->|audit| ANALYSE_UI[Analyser l'interface existante]
    QUESTIONS --> USERS
    READ_EPIC --> USERS
    ANALYSE_UI --> USERS

    USERS[1. Compréhension des utilisateurs — personas]
    USERS --> PARCOURS

    PARCOURS[2. Parcours utilisateur — happy path, frictions]
    PARCOURS --> UX

    UX[3. Proposition UX — layout, interactions, accessibilité]
    UX --> VISUAL

    VISUAL[4. Direction visuelle — palette, typo, composants]
    VISUAL --> SPECS

    SPECS[5. Spécifications Developer — tokens, états, breakpoints]
    SPECS --> OUT

    OUT{Relais ?}
    OUT -->|specs prêtes| DEV["/kp-agents:developer"]
    OUT -.->|choix produit non tranchés| PRODUCT["/kp-agents:product"]
    OUT -.->|implications techniques fortes| ARCHITECT["/kp-agents:architect"]

    style USERS fill:#e3f2fd,stroke:#1976D2
    style PARCOURS fill:#e3f2fd,stroke:#1976D2
    style UX fill:#e3f2fd,stroke:#1976D2
    style VISUAL fill:#e3f2fd,stroke:#1976D2
    style SPECS fill:#e3f2fd,stroke:#1976D2
    style DEV fill:#c8e6c9,stroke:#4CAF50
    style PRODUCT fill:#fff3e0,stroke:#FF9800
    style ARCHITECT fill:#fff3e0,stroke:#FF9800
```

---

### 8. Setup (`/kp-agents:setup`)

**Rôle** : configurateur du projet. Audite l'état de `.kp-agents.yml` et `.kp-agents.local.yml`, guide l'utilisateur pas à pas pour les compléter ou les corriger, et écrit les fichiers de config sans jamais écraser sans confirmation. **Seul agent autorisé** à écrire `.kp-agents.yml` et `.kp-agents.local.yml` — les 7 autres agents sont en lecture seule sur ces fichiers.

**Dimensions gérées** (3, indépendantes) :
- **`product`** : mode local ou external (OneDrive), avec option `access: read-only` si le PM humain maintient la doc ailleurs.
- **`tickets`** : mode local ou MCP (JIRA), avec matrice de mapping configurable par projet.
- **`git`** : `branch_pattern`, `auto_commit`, `auto_push` — préférences Git d'équipe.

**Sortie** : `.kp-agents.yml` (commité, politique partagée), `.kp-agents.local.yml` (gitignoré, chemins machine et override local), ajout automatique de l'entrée `.kp-agents.local.yml` au `.gitignore`.

```mermaid
flowchart TD
    START([Demande de config ou auto-redirect])
    START --> AUDIT[1. Audit des fichiers existants<br/>.kp-agents.yml, .local.yml, .gitignore]
    AUDIT --> INTENT{Intention claire ?}
    INTENT -->|non| ORIENT[Question d'orientation<br/>création / modification / vérification]
    INTENT -->|oui| QUEST
    ORIENT --> QUEST
    QUEST[2. Questions ciblées<br/>groupées par dimension<br/>product / tickets / git]
    QUEST --> VERIFY{Mode externe actif ?}
    VERIFY -->|product.mode=external| CHECK_PATH[3a. Vérifier accessibilité du chemin]
    VERIFY -->|tickets.mode=mcp| CHECK_MCP[3b. Valider issue types + statuts via MCP]
    VERIFY -->|aucun| ANNONCE
    CHECK_PATH --> ANNONCE
    CHECK_MCP --> ANNONCE
    ANNONCE[4. Annonce du contenu à écrire<br/>diff lisible, demande confirmation]
    ANNONCE --> CONFIRM{Confirmation ?}
    CONFIRM -->|non| CANCEL[Aucune modification, annonce explicite]
    CONFIRM -->|oui| WRITE[5. Écriture atomique<br/>.kp-agents.yml<br/>.kp-agents.local.yml si nécessaire<br/>maj .gitignore]
    WRITE --> HANDOFF[Bloc de handoff<br/>vers agent appelant ou /kp-agents:product]
    CANCEL --> FIN((Fin))
    HANDOFF --> FIN

    style AUDIT fill:#f3e5f5,stroke:#8E24AA
    style QUEST fill:#f3e5f5,stroke:#8E24AA
    style CHECK_PATH fill:#f3e5f5,stroke:#8E24AA
    style CHECK_MCP fill:#f3e5f5,stroke:#8E24AA
    style ANNONCE fill:#f3e5f5,stroke:#8E24AA
    style WRITE fill:#f3e5f5,stroke:#8E24AA
    style HANDOFF fill:#c8e6c9,stroke:#4CAF50
    style CANCEL fill:#ffebee,stroke:#E53935
    style FIN fill:#eeeeee,stroke:#9E9E9E
```

**Auto-redirect** : tout agent qui détecte une config manquante / incomplète dans `.kp-agents.yml` propose `/kp-agents:setup` à l'utilisateur — la redirection est une **suggestion, jamais un blocage**. L'utilisateur peut toujours refuser et continuer en mode local dégradé.

---

## Légende des schémas

| Élément | Signification |
|---------|---------------|
| Trait plein (`-->`) | Chemin **obligatoire** |
| Trait pointillé (`-.->`) | Chemin **facultatif** |
| Fond bleu clair | Étape interne de l'agent |
| Fond vert | Sortie obligatoire / destination principale |
| Fond orange | Sortie facultative / relais conditionnel |
| Fond rouge clair | Point bloquant |
| Losange | Point de décision |
| Cercle double | Fin du flux |
