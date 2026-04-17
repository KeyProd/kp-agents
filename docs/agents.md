---
title: Guide des agents
date: 2026-04-15
status: active
author: documentation-agent
---

# Guide des agents

> Description de chaque agent et visualisation de leurs workflows.
> Les traits pleins (`-->`) indiquent les chemins **obligatoires**. Les traits pointillés (`-.->`) indiquent les chemins **facultatifs**.

---

## Vue d'ensemble

Le projet comprend deux pipelines d'agents :

- **Pipeline développement** (7 agents) : workflow complet de l'idée au code validé
- **Pipeline RecetteMoi** (3 agents) : gestion des tickets de support utilisateur

---

## Pipeline développement — Vue globale

```mermaid
flowchart LR
    B["/kp-brainstorm"]
    P["/kp-product"]
    A["/kp-architect"]
    D["/kp-developer"]
    R["/kp-review"]
    UX["/kp-ux-ui"]
    DOC["/kp-documentation"]
    FIN((DONE))

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
**Agents transversaux** (facultatifs) : ux-ui (entre product et developer), documentation (après review ou developer)

---

## Pipeline RecetteMoi — Vue globale

```mermaid
flowchart LR
    S["/kp-recettemoi-support"]
    DEV["/kp-recettemoi-dev"]
    REV["/kp-recettemoi-review"]
    FIN((Ticket traité))

    S -->|ticket technique| DEV
    S -->|ticket fonctionnel| REV
    DEV -->|rapport de traitement| REV
    REV -->|réponse envoyée| FIN
    REV -.->|autre ticket| S

    style S fill:#fce4ec,stroke:#E91E63
    style DEV fill:#fce4ec,stroke:#E91E63
    style REV fill:#fce4ec,stroke:#E91E63
    style FIN fill:#c8e6c9,stroke:#4CAF50
```

**Chemin obligatoire** : toujours commencer par support, puis dev (technique) ou review (fonctionnel)
**Retour facultatif** : review peut relancer support pour un nouveau ticket

---

## Agents génériques — Détail

---

### 1. Brainstorm (`/kp-brainstorm`)

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
    OUT -->|sujet mature| PRODUCT["/kp-product"]
    OUT -.->|incertitudes techniques| ARCHITECT["/kp-architect"]

    style COMP fill:#e3f2fd,stroke:#1976D2
    style EXPLO fill:#e3f2fd,stroke:#1976D2
    style CRIT fill:#e3f2fd,stroke:#1976D2
    style STRUCT fill:#e3f2fd,stroke:#1976D2
    style PRODUCT fill:#c8e6c9,stroke:#4CAF50
    style ARCHITECT fill:#fff3e0,stroke:#FF9800
```

---

### 2. Product (`/kp-product`)

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
    OUT -->|design technique| ARCHITECT["/kp-architect"]
    OUT -.->|besoin UX| UX["/kp-ux-ui"]
    OUT -.->|doc à mettre à jour| DOC["/kp-documentation"]

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

### 3. Architect (`/kp-architect`)

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
    OUT -->|implémentation| DEV["/kp-developer"]
    OUT -.->|questions produit| PRODUCT["/kp-product"]
    OUT -.->|doc obsolète| DOC["/kp-documentation"]

    style ANALYSE fill:#e3f2fd,stroke:#1976D2
    style OPTIONS fill:#e3f2fd,stroke:#1976D2
    style DESIGN fill:#e3f2fd,stroke:#1976D2
    style ADR fill:#e3f2fd,stroke:#1976D2
    style DEV fill:#c8e6c9,stroke:#4CAF50
    style PRODUCT fill:#fff3e0,stroke:#FF9800
    style DOC fill:#fff3e0,stroke:#FF9800
```

---

### 4. Developer (`/kp-developer`)

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
    OUT -->|review recommandée| REVIEW["/kp-review"]
    OUT -.->|écarts documentaires| DOC["/kp-documentation"]

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

### 5. Review (`/kp-review`)

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
    VERDICT -->|NO-GO, story IN PROGRESS| DEV["/kp-developer"]
    WRITE -.->|écarts documentaires| DOC["/kp-documentation"]

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

### 6. Documentation (`/kp-documentation`)

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
    OUT -.->|spécification future| PRODUCT["/kp-product"]
    OUT -.->|décision technique| ARCHITECT["/kp-architect"]

    style ANALYSE fill:#e3f2fd,stroke:#1976D2
    style AUDIT fill:#e3f2fd,stroke:#1976D2
    style DIVERGENCES fill:#e3f2fd,stroke:#1976D2
    style MAJ fill:#e3f2fd,stroke:#1976D2
    style INDEX fill:#e3f2fd,stroke:#1976D2
    style PRODUCT fill:#fff3e0,stroke:#FF9800
    style ARCHITECT fill:#fff3e0,stroke:#FF9800
```

---

### 7. UX/UI (`/kp-ux-ui`)

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
    OUT -->|specs prêtes| DEV["/kp-developer"]
    OUT -.->|choix produit non tranchés| PRODUCT["/kp-product"]
    OUT -.->|implications techniques fortes| ARCHITECT["/kp-architect"]

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

## Agents RecetteMoi — Détail

---

### 8. RecetteMoi Support (`/kp-recettemoi-support`)

**Rôle** : porte d'entrée unique de la gestion des tickets RecetteMoi. Trie les tickets, filtre ceux en attente, analyse la nature du ticket et passe le relais au skill adapté.

**Types de tickets** : BUG, IMPROVEMENT, IDEA, QUESTION, COMPLIMENT.

```mermaid
flowchart TD
    START([Demande ticket]) --> MODE{ID de ticket fourni ?}
    MODE -->|non| RECO

    RECO[1. Recommandation — scoring et filtrage mémoire]
    RECO --> PRESENT[Présenter 2-3 recommandations]
    PRESENT --> CHOIX[Utilisateur choisit un ticket]
    CHOIX --> LECTURE

    MODE -->|oui| LECTURE

    LECTURE[2. Lecture et analyse — résumé, classification]
    LECTURE --> NATURE{Nature du ticket ?}

    NATURE -->|incomplet| CLARIF

    CLARIF[3. Clarification — max 3 questions, tutoiement]
    CLARIF --> CONFIRM{Confirmation admin ?}
    CONFIRM -->|oui| SEND[Envoyer le message]
    SEND -.->|autre ticket| RECO

    NATURE -->|technique| DEV["/kp-recettemoi-dev"]
    NATURE -->|fonctionnel| REV["/kp-recettemoi-review"]

    style RECO fill:#fce4ec,stroke:#E91E63
    style PRESENT fill:#fce4ec,stroke:#E91E63
    style LECTURE fill:#fce4ec,stroke:#E91E63
    style CLARIF fill:#fce4ec,stroke:#E91E63
    style DEV fill:#c8e6c9,stroke:#4CAF50
    style REV fill:#c8e6c9,stroke:#4CAF50
```

**Chemin obligatoire** : lecture du ticket --> classification --> handoff (dev ou review)
**Chemins facultatifs** : recommandation (si pas d'ID), clarification (si ticket incomplet)

---

### 9. RecetteMoi Dev (`/kp-recettemoi-dev`)

**Rôle** : traitement technique des tickets BUG ou IMPROVEMENT avec impact code. Analyse, crée une branche, implémente via `/kp-developer`, commit/push, puis passe le relais à recettemoi-review.

**Entrée obligatoire** : contexte transmis depuis recettemoi-support.

```mermaid
flowchart TD
    START([Contexte depuis recettemoi-support]) --> ANALYSE

    ANALYSE[D1. Analyse technique — fichiers, complexité, faisabilité]
    ANALYSE --> STATUS[Passer le ticket En cours]
    STATUS --> PLAN[Présenter le plan]
    PLAN --> CONFIRM{Confirmation admin ?}
    CONFIRM -->|oui| BRANCHE

    BRANCHE[D2. Préparation de la branche — hotfix ou feature]
    BRANCHE --> MODE{Mode ?}

    MODE -->|automatique| AUTO[D3a. Agent /kp-developer — implémentation autonome]
    MODE -->|manuel| MANUAL[D3b. Guidage pas à pas]

    AUTO --> HANDOFF
    MANUAL --> HANDOFF

    HANDOFF["/kp-recettemoi-review"]

    style ANALYSE fill:#fce4ec,stroke:#E91E63
    style STATUS fill:#fce4ec,stroke:#E91E63
    style PLAN fill:#fce4ec,stroke:#E91E63
    style BRANCHE fill:#fce4ec,stroke:#E91E63
    style AUTO fill:#fce4ec,stroke:#E91E63
    style MANUAL fill:#fce4ec,stroke:#E91E63
    style HANDOFF fill:#c8e6c9,stroke:#4CAF50
```

**Chemin obligatoire** : analyse --> branche --> implémentation --> handoff review
**Choix interne** : mode automatique (agent) ou manuel (guidé)

---

### 10. RecetteMoi Review (`/kp-recettemoi-review`)

**Rôle** : validation et réponse utilisateur. Rédige une réponse fonctionnelle (depuis support) ou valide le rapport technique (depuis dev) et prépare la communication utilisateur. Conclut le cycle de vie du ticket.

**Entrée obligatoire** : contexte transmis depuis recettemoi-support ou recettemoi-dev.

```mermaid
flowchart TD
    START([Contexte depuis support ou dev]) --> ORIGINE{Origine ?}

    ORIGINE -->|support, fonctionnel| R1

    R1[R1. Réponse fonctionnelle — analyser et formuler]
    R1 --> R1_CHECK[Review interne de la réponse]
    R1_CHECK --> R1_PRESENT[Présenter à l'admin]
    R1_PRESENT --> CONFIRM1{Confirmation ?}
    CONFIRM1 -->|oui| SEND1[Envoyer le message]

    ORIGINE -->|dev, technique| R2

    R2[R2. Validation technique — branche, commit, cohérence]
    R2 --> R2_PRESENT[Présenter le rapport à l'admin]
    R2_PRESENT --> R2_MSG[Rédiger le message utilisateur]
    R2_MSG --> CONFIRM2{Confirmation ?}
    CONFIRM2 -->|oui| SEND2[Envoyer le message]

    SEND1 --> CLOTURE
    SEND2 --> CLOTURE

    CLOTURE[R3. Clôture — récapitulatif et statut]
    CLOTURE -.->|autre ticket| SUPPORT["/kp-recettemoi-support"]

    style R1 fill:#fce4ec,stroke:#E91E63
    style R1_CHECK fill:#fce4ec,stroke:#E91E63
    style R1_PRESENT fill:#fce4ec,stroke:#E91E63
    style R2 fill:#fce4ec,stroke:#E91E63
    style R2_PRESENT fill:#fce4ec,stroke:#E91E63
    style R2_MSG fill:#fce4ec,stroke:#E91E63
    style CLOTURE fill:#fce4ec,stroke:#E91E63
    style SUPPORT fill:#fff3e0,stroke:#FF9800
```

**Chemin obligatoire** : selon l'origine, R1 (fonctionnel) ou R2 (technique) --> clôture
**Chemin facultatif** : retour vers support pour un autre ticket

---

## Légende des schémas

| Élément | Signification |
|---------|---------------|
| Trait plein (`-->`) | Chemin **obligatoire** |
| Trait pointillé (`-.->`) | Chemin **facultatif** |
| Fond bleu clair | Étape interne de l'agent |
| Fond rose clair | Étape interne (agents RecetteMoi) |
| Fond vert | Sortie obligatoire / destination principale |
| Fond orange | Sortie facultative / relais conditionnel |
| Fond rouge clair | Point bloquant |
| Losange | Point de décision |
| Cercle double | Fin du flux |
