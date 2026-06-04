---
title: Refonte du dispositif E2E — orchestrateur unique kp-test (Xray ↔ test code)
date: 2026-06-04
status: qualified
brainstorm-format: complet
author: brainstorm-agent
---

# Refonte du dispositif E2E — orchestrateur unique `kp-test`

> Session de cadrage : repenser les agents `kp-xray` et `kp-e2e`, alignés sur l'ancienne méthodo Playwright standalone, pour les remplacer par **un agent unique `kp-test`**, cohérent avec le nouveau socle keyprod (Pest 4 Browser + préfixe `[KP-XXXXX]` + remontée `xray-sync.mjs`) — tout en gardant une **architecture project-agnostic** (config-driven) pour les autres projets distribués via le plugin Claude Code / Cursor / Codex.

---

## Décisions validées (2026-06-04)

Arbitrages tranchés par l'utilisateur après lecture de la proposition complète. **Ces décisions prévalent sur les hypothèses des phases 1-3 ci-dessous** (conservées comme trace de l'exploration divergente).

| # | Sujet | Décision | Conséquence |
|---|---|---|---|
| **D1** | Approche retenue | **B — orchestrateur unique** (cf. scoring 4,75) | Pas de binôme conservé, pas de 3ᵉ agent, pas de Workflow scripté |
| **D2** | Nommage | L'agent s'appelle **`kp-test`** (et non `kp-e2e`) | Sémantiquement juste : couvre Xray + tests + validation + remontée. `kp-xray` **ET** `kp-e2e` sont remplacés |
| **D3** | Priorité de l'agent | **Garant de conformité** : sa mission n°1 est que *tout soit bien défini selon les règles attendues* — cas Xray, test code, validation, remontée Xray, **stratégie de seed et de clean**. Pas un simple générateur de tests | La colonne vertébrale devient une **Definition of Done à 6 critères** (cf. §4) que l'agent audite et fait converger |
| **D4** | Framework | **`pest-browser` uniquement** livré. `playwright` = extension future (hook prévu en config). `cypress` = **déprécié, non supporté** | Scope concret resserré ; l'architecture reste config-driven pour accueillir playwright plus tard sans réécrire l'agent |
| **D5** | Seeds | Périmètre **`kp-developer`**, confirmé. **Invariant ajouté** : l'orchestration garantit que tout seed utilisé est **dédié aux tests** (jamais un seed métier de l'application) | Handoff vers `kp-developer` spécifiant « seed dédié test » ; détection/refus si un seed métier est détourné |
| **D6** | Multi-cible | **Claude = cible de référence**. L'agent reste **nativement disponible sur Cursor et Codex**, avec pertes potentielles assumées | Confirme B (et non E/Workflow Claude-only) : on optimise pour Claude sans sacrifier la disponibilité Cursor/Codex |

---

## 1. Compréhension du problème

### Reformulation

Le projet `kp-agents` distribue 9 agents IA via 3 cibles (plugin Claude Code, Cursor, Codex). Deux de ces agents portent aujourd'hui la promesse d'un dispositif E2E **bout en bout** :

- `kp-xray` (« Test Designer ») : crée des cas Xray manuels dans le référentiel JIRA, livre une clé `KP-XXXXX`.
- `kp-e2e` (« Test Engineer ») : génère un binôme `specs/<feature>.spec.md` + `tests/<feature>.spec.ts` dans un dossier **`devel/`** dédié, avec annotation Playwright `{ type: 'xray', description: 'KP-XXXX' }`, et pousse les résultats via un script `sync-xray.js`.

Or, **côté keyprod (le projet de référence pour `kp-agents`)** le socle a entièrement basculé :

| Dimension | Ancien socle (encodé dans les 2 agents) | Nouveau socle (juin 2026, ADR-011/012/013) |
|---|---|---|
| Cadre E2E | Playwright standalone | **Pest 4 Browser** (wrapper Playwright in-process Laravel) |
| Dossier tests | `devel/tests/*.spec.ts` | `apps/kpweb/tests/Browser/<Domaine>Test.php` |
| Liaison test ↔ cas | Annotation `xray` (Playwright fixtures) | **Préfixe `[KP-XXXXX]` dans la description du `it()`** |
| Remontée | `sync-xray.js` lit annotations | `xray-sync.mjs` parse JUnit + regex `KP-\d+` |
| Exécution | Playwright remote vers `dev.inno` | `make test-browser` / `make test-browser-xray`, local sur DB isolée |
| Discovery | Playwright MCP | Playwright MCP **local uniquement** (i18n EN local vs FR remote) |
| Isolation | Multi-worker partagé | DB `keyprod_test` + seeders `beforeEach` + `ref` unique par test |
| Pairing | `spec.md` + `spec.ts` | Pas de spec.md ; le cas Xray **est** la spec |
| Identité Xray | « Test ID = annotation » | « Test ID = chaîne dans le libellé », **non-idempotent**, une Test Execution par push |
| Référentiel | 911 tests, racines mixtes | **Purge complète**, reconstruit autour de **13 cas P0 KP-18179 → KP-18191** |

**Les deux agents sont donc obsolètes dans ~80 % de leur contenu** — pas seulement « à rafraîchir » : l'arborescence, l'outillage, la stratégie de pairing et la mécanique de remontée ont toutes bougé. Reste réutilisable : la mécanique d'auth Xray Cloud GraphQL et le format des steps (côté `kp-xray`), les règles de sélecteurs robustes et le juge LLM « le test teste-t-il la bonne chose ? » (côté `kp-e2e`).

### Le besoin sous-jacent (réel, plus large que « refresh »)

L'utilisateur ne demande pas juste un coup de polish. Il pose **trois questions structurantes** simultanément :

1. **Adéquation au socle** : encoder le nouveau workflow Pest Browser + `[KP-]` sans casser le pattern « source `agents/`, distribution multi-cible ».
2. **Orchestration** : aujourd'hui le flux nominal (story → cas Xray → test → run → remontée) est implicite, chaîné à la main. Peut-on **automatiser le pilotage** : un prompt → détection d'état → décision du prochain pas → exécution ?
3. **Conformité (priorité n°1, cf. D3)** : l'agent doit surtout **garantir que tout est défini selon les règles attendues** — pas juste produire du code, mais être le gardien d'une définition de fini complète (cas Xray, test, validation, remontée, **seed/clean**).

### Distinction problème / solution / hypothèse

| Niveau | Énoncé |
|---|---|
| **Problème utilisateur** | Le tour de table « cas Xray puis test code puis remontée » est laborieux, chaîné à la main, et rien ne garantit que chaque maillon respecte les règles (bonne stack, bon dossier, bonne liaison, **seed dédié test, clean correct**). La moitié des règles encodées dans les agents actuels sont fausses. |
| **Solution imaginée** | Un orchestrateur unique qui sait où on en est et **fait converger chaque cas vers une définition de fini conforme**. |
| **Hypothèse à tester** | Un seul point d'entrée IA suffit pour garantir + piloter la chaîne complète, sans perdre la rigueur de la séparation des rôles. |

### Hypothèses critiques

1. **H1 — Pattern universel** : le couplage « ID dans le libellé du test » est généralisable au-delà de Pest (utile pour le hook playwright futur). *À valider ultérieurement, non bloquant tant qu'on ship pest-browser.*
2. **H2 — Persona unique pertinente** : la séparation designer (Xray) / engineer (code) est une commodité humaine, pas une frontière dure → fusion en une persona « garant E2E ». **Confirmé par l'utilisateur (D2/D3).**
3. **H3 — Détection d'état faisable** : l'agent peut situer où on en est en lisant story + Xray (MCP) + filesystem `tests/Browser/` + historique Test Executions.
4. **H4 — Conformité encodable en DoD** : les « règles attendues » (D3) se formalisent en une checklist objective de 6 critères, auditables un par un. **C'est le pari central de l'agent.**
5. **H5 — Frontières tiennent** : seeds = `kp-developer` (D5), couverture/axes = `kp-product`, bootstrap harness = `kp-architect`.

### Méthode mobilisée

Starbursting + **First Principles** sur l'agnosticité : *« qu'est-ce qu'un workflow Xray↔E2E indépendamment du framework ? »* → minimum vital = **(1)** un référentiel de cas externe, **(2)** un identifiant pérenne, **(3)** un canal de liaison stable dans le code, **(4)** un mécanisme de remontée, **(5)** une stratégie d'isolation des données. Tout le reste (Pest, Make, JIRA, Cognito) = mécanique projet à paramétrer.

---

## 2. Exploration divergente — 5 approches

> Les approches sont rédigées au moment de l'exploration ; la **B est retenue** (cf. D1) et mise à jour avec les décisions. A/C/D/E conservées comme comparatif.

### Approche A — Conventionnelle : maintien du binôme, refresh des contenus

**Principe** : garder `kp-xray` et `kp-e2e` comme **deux agents séparés**, réécrits pour Pest Browser + `[KP-]` + `tests/Browser/`. Pas d'orchestrateur — l'humain (ou `kp-developer`) appelle l'un puis l'autre.

**Effort** : ~1 jour par agent (refonte quasi-totale des deux).

**Avantages** : frontières connues ; modèle documenté côté keyprod ; pas de rupture utilisateur ; découplage strict (invoquer xray seul ou e2e seul).

**Risques** : **ne répond pas à la demande d'orchestration ni à la priorité conformité (D3)** ; redondance documentaire entre les deux agents ; probable hardcode Pest/Make.

**Signal de poursuite** : si l'utilisateur disait « pas d'orchestrateur, juste corriger ». — *Écarté.*

**Analogie** : changer les 4 pneus sans toucher au moteur.

---

### Approche B — RETENUE : agent orchestrateur unique `kp-test`, garant de conformité

**Principe** : **un seul agent user-facing `kp-test`** (D2), architecturé selon le pattern **orchestrateur + refs procédurales** déjà éprouvé sur `kp-setup` (cf. CLAUDE.md : « agent = orchestrateur + refs »).

**Persona (D3)** : *garant de la chaîne E2E*. Pas un générateur de tests : sa mission n°1 est de **garantir que, pour chaque cas, toute la chaîne respecte les règles attendues** (cas Xray, test code, liaison, isolation seed/clean, validation, remontée). Il **audite** une **Definition of Done à 6 critères** (cf. §4), détecte le premier écart, le résout ou le délègue, et boucle jusqu'au vert complet.

Structure cible :
```
plugins/kp-agents/skills/kp-test/
├── SKILL.md                        Persona « garant E2E » + DoD + scope + router (≤ 250 lignes)
├── persona.md                      Carte d'identité (auto-généré)
└── references/
    ├── e2e-state-detection.md      AUDIT DoD : situer « où on en est » sur les 6 critères + arbre de décision
    ├── e2e-case-design.md          Critère 1 — concevoir le cas Xray (absorbe kp-xray : auth GraphQL, steps, rangement)
    ├── e2e-test-implementation.md  Critères 2+3 — implémenter le test (discovery MCP local, conventions, préfixe [KP-])
    ├── e2e-data-isolation.md       Critère 4 — stratégie seed/clean + invariant « seed dédié test » + frontière kp-developer
    ├── e2e-results-sync.md         Critères 5+6 — runs, validation, parsing JUnit, remontée Xray, protocole rouge/flake
    └── e2e-coverage-audit.md       Vue inter-cas — orphelins (cas sans test / test sans cas), trous de couverture
```

**Paramétrisation agnostique** (bloc `testing:` dans `.kp-agents.yml`, géré par `kp-setup`) — **pest-browser livré, playwright en hook futur, cypress retiré (D4)** :

```yaml
testing:
  framework: pest-browser          # SEUL supporté. playwright = extension future. cypress = déprécié (non supporté)
  tests_dir: apps/kpweb/tests/Browser
  test_file_pattern: "*Test.php"
  run_commands:
    headless: "make test-browser"
    with_sync: "make test-browser-xray"
    up:   "make test-browser-up"
    down: "make test-browser-down"
  case_repository:
    type: xray                     # xray | (autres à venir)
    mcp_server: claude_ai_Atlassian
    project_key: KP
    root_folder: "/Tests PlayWright"
    test_link_pattern: "\\[KP-\\d+\\]"   # regex de liaison test ↔ cas
    test_link_format: "[KP-{id}]"        # gabarit de préfixe injecté dans le it()
  isolation:                        # critère 4 de la DoD — cœur de la priorité D3/D5
    test_seed_namespace: database/seeds/Browser   # seeds DÉDIÉS test — jamais les seeds métier
    baseline_seeder: BrowserTestSeeder
    unique_ref_strategy: "ref = 'e2e-' . uniqid()"
  conventions_doc: apps/kpweb/docs/e2e/conventions.md
  discovery:
    mcp: playwright
    base_url_local: "http://localhost:8081"
```

Toute la mécanique projet-spécifique (Pest, `make`, `[KP-]`, `/Tests PlayWright`, namespace de seed) **sort de l'agent** et vit dans cette config. L'agent lit le bloc et applique.

**Optimisation Claude-first (D6)** : Claude est la cible de référence — on peut exploiter la richesse Claude (progressive disclosure des refs via `{{ref:}}`, lectures parallèles pour la détection d'état, MCP Xray/Playwright). Cursor/Codex restent **nativement servis** (refs inlinées par `sync.sh`) avec pertes assumées sur la détection d'état avancée.

**Effort** : SKILL.md ~250 lignes + 6 refs (~200-350 lignes ch.) + bloc `testing:` + dimension `testing` dans `kp-setup` + retrait de `kp-xray`/`kp-e2e`.

**Avantages** : répond aux 3 questions **et** ancre la priorité conformité (DoD) ; pattern déjà validé (`kp-setup`) ; progressive disclosure (contexte léger) ; un seul point d'entrée mental (« je teste KP-XXXXX → l'agent garantit + pilote ») ; découpe orthogonale à l'organisation humaine.

**Risques** (traités en §3) : agent volumineux ; config `testing:` à bien poser ; détection d'état à rendre robuste.

**Analogie** : un praticien polyvalent avec une **checklist de sortie** stricte et des protocoles spécialisés sous la main — plutôt que deux spécialistes qui se passent un dossier sans garant du résultat final.

---

### Approche C — Minimaliste : un seul agent fin sans orchestration

**Principe** : supprimer `kp-xray`, réécrire `kp-e2e` en **un agent ramassé** (design + impl + run en procédure linéaire, sans modes ni router).

**Avantages** : le plus simple ; pas de tension orchestrateur/sous-agents.

**Risques** : **pas de détection d'état** ni de garant DoD (≠ D3) ; pas de mode `audit` séparé ; orchestration repoussée sur `kp-developer`.

**Analogie** : couteau suisse à un seul mode.

---

### Approche D — Hybride : orchestrateur dédié + binôme préservé

**Principe** : garder xray + e2e (rafraîchis) **et** ajouter un 3ᵉ agent orchestrateur qui lit l'état et délègue via handoff.

**Avantages** : séparation orchestration/exécution ; binôme invocable seul.

**Risques** : **3 agents** (surface ×1,5) ; les agents Claude Code n'ont pas de **pipeline programmatique** (juste des handoffs) → l'orchestrateur n'est qu'un router conversationnel, ce que B fait déjà sans 3ᵉ agent ; chevauchement avec `kp-developer`.

**Analogie** : chef de chantier + maçon + plombier.

---

### Approche E — First Principles : workflow déterministe Claude Code

**Principe** : un **workflow scripté** (tool `Workflow`) qui appelle séquentiellement designer → implementer → `make test-browser-xray` → boucle si rouge.

**Avantages** : ordre garanti, idéal pour du batch (« génère les 12 cas P1 manquants »).

**Risques** : **multi-cible cassée** — Cursor/Codex n'ont pas `Workflow`, ce qui viole D6 (dispo native exigée) ; flexibilité conversationnelle perdue.

**Reconsidéré sous D6 (Claude prioritaire) puis ré-écarté** : l'utilisateur veut Claude prioritaire *mais* l'agent natif sur Cursor/Codex. Un workflow Claude-only ne serait pas natif ailleurs. → **B reste le bon véhicule** ; un workflow batch pourra venir *en plus* plus tard, sans remplacer l'agent.

**Analogie** : chaîne de production vs atelier — surdimensionné en bootstrap.

---

### Tableau de synthèse

| Critère | A — Refresh binôme | **B — `kp-test` orchestrateur** | C — Agent fin | D — Trio | E — Workflow |
|---|---|---|---|---|---|
| Répond à l'orchestration | ❌ | ✅ | ⚠️ | ✅ | ✅ |
| Priorité conformité (DoD, D3) | ❌ | ✅ | ❌ | ⚠️ | ⚠️ |
| Refresh Pest/[KP-] | ✅ | ✅ | ✅ | ✅ | ✅ |
| Architecture agnostique (config) | possible | **native** | possible | possible | possible |
| Dispo native Claude+Cursor+Codex (D6) | ✅ | ✅ | ✅ | ✅ | ❌ |
| Coût implémentation | moyen | élevé | faible | très élevé | moyen |
| Pattern éprouvé chez kp-agents | ✅ binôme | ✅ kp-setup | ❌ | ❌ | ❌ |

---

## 3. Analyse critique

### Hypothèses implicites

| # | Hypothèse | Statut | Si fausse → impact |
|---|---|---|---|
| HI-1 | « Préfixe `[ID]` dans le libellé » portable hors Pest | Probable (hook playwright futur) | Si limité, l'agnostique reste latent — sans impact tant qu'on ship pest-browser |
| HI-2 | Persona unique > binôme | **Confirmé (D2/D3)** | — |
| HI-3 | `kp-setup` gère une 4ᵉ dimension `testing` sans refonte | Probable (déjà 3 dimensions) | Si non, coût B sous-évalué |
| HI-4 | La conformité (D3) se formalise en DoD objective à 6 critères | **Pari central — à éprouver par spike** | Si flou, l'orchestrateur oriente mal |
| HI-5 | Détecter l'état sans cache est faisable | À tester (spike KP-18190) | Si non, suppositions fragiles |
| HI-6 | Seeds = `kp-developer`, **dédiés test** | **Confirmé (D5)** | Si l'agent crée des seeds, il devient mini-developer (anti-pattern) |
| HI-7 | Playwright MCP local suffit pour la discovery | Confirmé (docs E2E) | Sinon, gérer un mode dégradé |

### Contraintes structurantes

**Techniques** :
- Un agent = **un seul `.md` dans `agents/`** ; le pattern orchestrateur+refs s'exprime via `{{include:}}` / `{{ref:}}` (supportés par `sync.sh`).
- Le projet-spécifique (Pest, Make, `[KP-]`, `/Tests PlayWright`, namespace seed) **ne doit pas** être hardcodé dans `agents/kp-test.md` → lecture du bloc `testing:`.
- **Framework livré = pest-browser uniquement (D4)** ; la config porte un champ `framework` prêt pour `playwright` ; `cypress` retiré.
- Le tool `Workflow` est Claude-only → **exclu du cœur** même sous priorité Claude (D6 exige le natif Cursor/Codex). Réservé à un éventuel mode batch *additionnel*.

**Humaines** : utilisateur solo, multi-projets → simplicité > spécialisation organisationnelle. Méthode keyprod **récente** (juin 2026) → l'agent doit la **rendre lisible**, pas juste la suivre.

**Temporelles / inertie** : pas de deadline dure ; ancien Xray purgé → coût d'une mauvaise reco faible, peu d'inertie installée → **on peut remplacer proprement plutôt que déprécier longuement**.

**Budget cognitif** : passer de 9 → 8 agents nets (retrait de xray+e2e, ajout de kp-test) **réduit** la surface — argument fort pour B contre D.

### Désirabilité / Faisabilité / Viabilité (B)

| Axe | Verdict | Détail |
|---|---|---|
| **Désirabilité** | ✅ forte | « Je teste KP-18180 » → l'agent garantit la DoD et pilote design→impl→run→remontée. Single point of entry + garant de rigueur. |
| **Faisabilité** | ✅ haute | Pattern orchestrateur+refs éprouvé (`kp-setup` : 592→261 lignes + 4 refs). `sync.sh` gère déjà `{{ref:}}`. |
| **Viabilité** | ⚠️ dépend de la config + de la DoD | Vit avec la qualité du bloc `testing:` et la solidité de la DoD (HI-4). Mitigation : défauts pest-browser sensés + spike de validation. |

### Risques et mitigations

| Risque | Prob. | Impact | Mitigation |
|---|---|---|---|
| **R1 — Bloc `testing:` non posé** sur un nouveau projet | Moyenne | Élevé | Auto-redirect `kp-setup` + défauts pest-browser si Laravel détecté |
| **R2 — `test_link_pattern` rate des cas** (multi-clés, clé en milieu) | Moyenne | Moyen | Edge-cases documentés (`[KP-a][KP-b]`, plusieurs `it()` même clé, test `->todo()`) + test explicite |
| **R3 — Playwright MCP indispo** (local pas up, MCP absent) | Élevée | Moyen | Mode dégradé : ébauche depuis story+conventions, test marqué `->todo()`, demande de démarrer MCP pour finaliser |
| **R4 — Mauvaise détection d'état** (doublon créé) | Moyenne | Élevé | Protocole : `grep -r "[KP-XXXXX]" <tests_dir>` + lecture Xray MCP **avant** toute création |
| **R5 — Seed métier détourné en seed test** | **Confirmée par D5** | Élevé | **Invariant dur** : l'agent n'utilise/n'exige que des seeds sous `isolation.test_seed_namespace`. S'il détecte un seed métier utilisé pour un test → **refus + handoff `kp-developer`** pour créer un seed **dédié test**. Ex. concret : Events/Dashboards bloqués = story `kp-developer` (seed test manquant), pas un trou de `kp-test`. |
| **R6 — Agent volumineux** (SKILL + 6 refs) | Moyenne | Moyen | Progressive disclosure côté Claude. Côté Cursor/Codex (inline), surveiller la taille ; scinder si >500 lignes générées |
| **R7 — Remplacement xray+e2e** casse un workflow | Faible (utilisateur quasi-unique) | Faible | Remplacement propre via `.installed-agents` (purge chirurgicale). Stub de redirection court-vécu optionnel si besoin |

### Critères de décision (scoring)

| Critère | Poids | A | **B** | C | D | E |
|---|---|---|---|---|---|---|
| Orchestration + conformité (D3) | 35 % | 1 | **5** | 2 | 4 | 3 |
| Dispo native Claude+Cursor+Codex (D6) | 25 % | 5 | **5** | 5 | 5 | 1 |
| Architecture agnostique (config) | 15 % | 3 | **5** | 3 | 3 | 4 |
| Coût total (impl + maintenance) | 15 % | 3 | **3** | 5 | 1 | 3 |
| Pattern aligné kp-agents | 10 % | 4 | **5** | 4 | 3 | 2 |
| **Score pondéré** | | 2,90 | **4,70** | 3,40 | 3,55 | 2,65 |

**B sort nettement en tête.** Le poids accru sur conformité (D3) creuse l'écart avec C/E.

---

## 4. Structuration — recommandation et next steps

### Persona et priorité de `kp-test` (cœur du design)

> **`kp-test` est le garant de la chaîne E2E.** Sa priorité n'est pas de produire un test, mais de **garantir qu'un cas de test est conforme aux règles attendues de bout en bout.** Un test n'est « fini » que lorsque les 6 critères ci-dessous sont verts. L'agent les audite, identifie le premier écart, le résout (ou délègue), et boucle.

### Definition of Done d'un cas de test E2E (colonne vertébrale)

| # | Critère | Vérifié par | Délégation |
|---|---|---|---|
| **1** | **Cas Xray défini** — issue `KP-XXXXX` existe, rangée sous `root_folder`, summary métier, steps action/result observables, liée à la story, labellisée | `e2e-case-design.md` | — (l'agent le fait) |
| **2** | **Test code conforme** — fichier dans `tests_dir`, conventions respectées (`data-cy`, pas de `sleep`, strict mode), description FR métier | `e2e-test-implementation.md` | — |
| **3** | **Liaison établie** — préfixe `[KP-XXXXX]` exact dans la description du `it()` (`test_link_pattern`) | `e2e-test-implementation.md` | — |
| **4** | **Isolation seed + clean correcte** — seed **dédié test** (jamais métier, D5), seedé en `beforeEach`, `ref` unique par entité, cleanup idempotent en `afterEach` | `e2e-data-isolation.md` | **Seed de domaine manquant → handoff `kp-developer`** |
| **5** | **Validation** — runs verts répétables (2-3×), zéro flake | `e2e-results-sync.md` | — |
| **6** | **Remontée effective** — résultat poussé dans Xray (Test Execution via `run_commands.with_sync`) | `e2e-results-sync.md` | — |

**Orchestration = pour la cible donnée (clé `KP-XXXXX` ou parcours), auditer ces 6 critères (`e2e-state-detection.md`), traiter le premier non satisfait, répéter jusqu'au vert complet.** C'est ainsi que se matérialise « où on en est ».

### Composants à produire

1. **`agents/kp-test.md`** (≤ 250 lignes) : persona « garant E2E » + énoncé de la DoD + lecture du bloc `testing:` au démarrage + routine d'orientation (détection d'état d'abord) + router de modes + anti-patterns transverses (jamais d'écriture côté app, jamais de modif `data-cy`, jamais d'écriture seed).

2. **6 refs dans `includes/`** (copiées vers `skills/kp-test/references/` par `sync.sh`) : `e2e-state-detection`, `e2e-case-design`, `e2e-test-implementation`, `e2e-data-isolation`, `e2e-results-sync`, `e2e-coverage-audit`.
   - *Question ouverte pour l'architect* : `e2e-data-isolation` en ref dédiée (recommandé vu la priorité D5) **ou** section de `e2e-test-implementation` ?

3. **Évolution de `kp-setup`** : 4ᵉ dimension `testing` (après product/tickets/git) → ref `setup-testing.md` + schéma `sources-config-testing.md`. Heuristique : présence de Pest → propose `framework: pest-browser` + défauts.

4. **Modes user-forçables** : `auto` (orchestré, défaut) + `design` / `implement` / `sync` / `audit` (court-circuit ponctuel). L'audit de couverture notamment doit être invocable seul.

5. **Remplacement de `kp-xray` et `kp-e2e`** : retrait des deux fichiers `agents/` (purge chirurgicale via `.installed-agents` sur les 3 cibles). Stub de redirection court-vécu **optionnel** (faible enjeu, utilisateur quasi-unique). **Bump version** : retrait de 2 agents + ajout = candidat **`--minor`** (au minimum) voire **`--major`** (rupture namespace) — à trancher au moment de la release.

6. **Docs** : `docs/agents.md` (retirer xray+e2e, ajouter kp-test, nouveau diagramme du flux orchestré + DoD), `CLAUDE.md` du repo (table des agents), `docs/INDEX.md` via `kp-documentation`.

### Frontières (confirmées)

- **`kp-developer`** — owner des seeds. `kp-test` détecte un besoin → **handoff explicite** : « créer un seeder **dédié test** pour `<domaine>` sous `isolation.test_seed_namespace`, ne pas toucher aux seeders métier ». `kp-test` **n'écrit jamais** dans `database/seeds/`. **Invariant D5** : un seed métier détourné pour un test = refus + handoff.
- **`kp-product`** — owner de la stratégie de couverture (axes des 13 catégories, priorités P0/P1/P2). `kp-test` exécute la couverture demandée ; handoff entrant possible depuis `kp-product` (« voici l'axe à couvrir »). Au quotidien, l'utilisateur dit « teste tel parcours / tel KP- ».
- **`kp-architect`** — owner du bootstrap du harness (scaffolder `tests/Browser/`, Makefile, `.env.testing`) sur un nouveau projet.

### Type de next step

- **`kp-product`** : non nécessaire — refonte interne d'agents, pas une feature produit de `kp-agents`. Pas d'epic.
- **Spike (recommandé)** : valider la **DoD + détection d'état** (HI-4/HI-5) sur un cas réel keyprod (**KP-18190 password reset**) — ~30 min conversationnel, avant le design théorique.
- **`kp-architect`** : prochain pas principal. À trancher : ref dédiée isolation ou non ; schéma exact `testing:` (validé contre keyprod + 1 projet fictif) ; protocole de détection d'état (ordre des lectures, cas ambigus, mode dégradé MCP) ; modes forçables ; stub de redirection ou non ; bump version.
- **`kp-developer`** : ensuite, réécriture effective sur la base du design.

### Décision / Next steps

| # | Action | Owner | Output |
|---|---|---|---|
| 1 | **Spike DoD + détection d'état** sur KP-18190 (optionnel mais recommandé) | utilisateur + `kp-e2e` actuel | Confirme que story + grep `[KP-18190]` + lecture cas Xray suffisent à situer + orienter |
| 2 | **Handoff `kp-architect`** | utilisateur | Design : DoD figée, schéma `testing:`, structure des 6 refs, protocole détection, stratégie de remplacement, bump |
| 3 | **Implémentation `kp-developer`** | utilisateur | `agents/kp-test.md` + 6 includes + dimension `testing` dans kp-setup + retrait xray/e2e + maj docs |
| 4 | **Test sur keyprod réel** | utilisateur | Invoquer `kp-test` sur 1-2 cas P0 (KP-18190) — flux DoD end-to-end |
| 5 | **Validation agnostique** (plus tard) | utilisateur | Hook `playwright` activé sur un projet tiers via `.kp-agents.yml` |

---

## Spike de validation — détection d'état sur le référentiel réel (2026-06-04)

> Spike « sur dossier » (sans exécution `make`, sans MCP Atlassian) sur `apps/kpweb/tests/Browser/`. But : éprouver **HI-4** (DoD formalisable) et **HI-5** (détection d'état faisable sans cache). **Verdict : les deux confirmés, avec 5 findings qui enrichissent le design.**

### Ce que le filesystem révèle

| Mesure | Valeur |
|---|---|
| Clés `[KP-]` uniques référencées | **13 / 13** (KP-18179→18191, toutes grep-ables) |
| `it()` actifs (corps `function`) | **7** |
| `it()` en `->todo()` | **78** |
| Commentaires `BLOCKER:` (préconditions/seed manquants) | **4** |
| Marqueurs `DISCOVERY` (sélecteurs `data-cy` non confirmés) | **13** |

### Findings

**F1 — Détection d'état par filesystem : validée (HI-5 ✅).** `grep -roE "\[KP-[0-9]+\]" <tests_dir>` retrouve les 13 clés sans MCP ni cache ; la lecture du `it()` correspondant classe l'état. *Limite initiale* : le critère 1 (« cas Xray défini ») n'avait pas pu être vérifié live (MCP Atlassian absent) — **levée le 2026-06-04 après réactivation du MCP, cf. « Complément Xray live » ci-dessous.**

**F2 — 4 états filesystem, pas 2.** Le modèle initial (absent / présent) était trop grossier :

| État | Signature | Prochain pas DoD |
|---|---|---|
| Absent | aucun `it()` pour la clé | créer le cas + le test |
| Squelette | `it("[KP-X] …")->todo();` sans corps | implémenter (discovery MCP) |
| **Rédigé mais bloqué** | corps `function` complet **+** `->todo()` **+** commentaire `BLOCKER:` | **lever la précondition → souvent handoff `kp-developer`** |
| Actif | `it("[KP-X] …", function(){…})` | valider (run) + remonter |

+ statut **runtime** (vert / rouge / flake), orthogonal, qui vient du run. → **La détection d'état doit parser les commentaires `BLOCKER:`** : ils encodent *pourquoi* un test n'est pas actif et pointent quasi-toujours une précondition de seed/flag.

**F3 — Le goulot réel = seed/précondition, pas le code (valide D3/D5 en plein).** 78 `->todo()` contre 7 actifs. Les 4 `BLOCKER:` sont tous des préconditions non garanties par `BrowserTestSeeder` :
- KP-18188/18189/18190 (Events) → **flag tenant `enable_create_deviceless_event`** non provisionné, bouton « Créer un événement » masqué (`v-if`).
- KP-18184 (changement de mot de passe) → besoin d'un **compte Cognito dédié réinitialisable**, avec règle dure terrain : **« NE PAS muter les personas partagés seedés »**.

→ Le **critère 4 (isolation seed/clean) est le maillon critique** de la DoD, exactement là où porte la priorité D3. `e2e-data-isolation.md` doit encoder l'invariant « ne jamais muter un persona baseline → exiger un compte/flag **dédié test** provisionné par `kp-developer` ».

**F4 — Mapping clé ↔ `it()` = 1:N confirmé.** KP-18183 et KP-18184 portent chacune 2 `it()` (un actif + un `->todo()`). La DoD raisonne « le cas est-il couvert » en **agrégeant** les `it()` d'une même clé — comme `xray-sync.mjs` qui remonte le statut maximal (FAILED > PASSED > TODO).

**F5 — Discovery MCP local indispensable (valide R3).** 13 `DISCOVERY` : sélecteurs `data-cy` supposés (`event-form-submit`) ou ciblés par texte faute de `data-cy`. Frontière confirmée : `kp-test` **recommande** des `data-cy` à `kp-developer` (`kpweb-recommendations.md`), ne les pose jamais. i18n géré test-par-test via `->withLocale('fr-FR')` — ancre concrète pour `e2e-test-implementation.md`.

### Complément Xray live (MCP réactivé, 2026-06-04)

Lecture seule des 13 cas via `getJiraIssue` / `searchJiraIssuesUsingJql` (cloudId `keyprod.atlassian.net`, projet KP `10007`). **Critère 1 désormais vérifiable de bout en bout.**

**FX1 — Le MCP Atlassian standard suffit pour le critère 1.** Les 13 cas existent en type **Test** (Xray Test Issue Type `10011`), summary au format `Module > comportement` (« Auth > Connexion réussie… », « Événements > Bouton Enregistrer désactivé… »), description suivant un **gabarit régulier** : Persona / Écran(s) / Préconditions / Étapes / Résultat attendu / Automatisation / Cadre. → l'agent **audite et crée le contenu d'un cas via le MCP standard** (champ description) ; le **GraphQL Xray n'est nécessaire que pour le rangement en folder** `/Tests PlayWright` (non exposé par le MCP). Les « steps » sont en **prose markdown dans la description**, pas en Xray Manual Steps natifs → dépendance technique allégée.

**FX2 — Double canal de liaison (invariant à durcir).** La liaison cas ⇄ test est **redondante** : préfixe `[KP-XXXXX]` côté `it()` **et** ligne `**Automatisation** : Pest 4 Browser — apps/kpweb/tests/Browser/…Test.php` dans la description Xray. → le critère 3 de la DoD ne vérifie pas seulement « préfixe présent » mais la **cohérence bidirectionnelle** (le test pointe le bon cas, la description du cas pointe le bon fichier).

**FX3 — Lien story manquant en réalité.** `issuelinks: []` sur KP-18190 : les cas P0 ne sont **pas** liés à une story par lien JIRA natif. Le sous-critère « lié à la story » de la DoD n'est donc **pas rempli** dans le référentiel actuel → le traiter comme **signalable (warn), configurable**, pas bloquant.

**FX4 — Conventions réelles.** Label de convention = **`pest-browser`** (et non `Automatisable` comme l'indiquait l'ancien `kp-xray`). Statut JIRA = `Backlog` pour les 13 (le statut du cas n'est **pas** un indicateur de couverture — l'exécution vit dans les Test Executions). → `testing.case_repository.case_label: pest-browser`.

### Conséquences pour le design
- Détection d'état = **4 états filesystem + statut runtime + parsing `BLOCKER:`** ; critère 1 audité via **MCP Atlassian standard** (GraphQL Xray seulement pour le rangement folder).
- DoD critère 3 (liaison) = **cohérence bidirectionnelle** préfixe `[KP-]` ⇄ ligne `Automatisation:` (FX2).
- DoD critère 4 (seed/clean) = maillon critique → `e2e-data-isolation` mérite sa **ref dédiée** (tranche la question §4 en faveur du oui).
- « Lié à la story » = sous-critère **warn/configurable**, pas bloquant (FX3).
- Config `testing:` : gabarit de description + `case_label: pest-browser` + question ouverte sur le **catalogue de préconditions/flags tenant** (ex. `enable_create_deviceless_event`) vs convention `BLOCKER:`.

---

## Bloc de handoff

> **Handoff → /kp-agents:kp-architect**
> **Depuis** : brainstorm-agent
> **Contexte** : refonte du dispositif E2E `kp-agents` — remplacement du binôme obsolète `kp-xray` + `kp-e2e` par **un agent unique `kp-test`**, garant de conformité, aligné Pest Browser + `[KP-]`, architecture config-driven.
> **Acquis (décisions tranchées D1-D6)** :
> - **D1** Approche B (orchestrateur unique) ; **D2** nom = `kp-test` (remplace xray ET e2e) ; **D3** priorité = garant de conformité via une **DoD à 6 critères** (cas Xray / test code / liaison / **seed-clean** / validation / remontée) ; **D4** `pest-browser` seul livré, `playwright` en hook futur, `cypress` retiré ; **D5** seeds = `kp-developer` avec invariant « **dédiés test, jamais métier** » ; **D6** Claude prioritaire, natif Cursor/Codex avec pertes assumées.
> - Diagnostic : les 2 agents actuels obsolètes à ~80 % (stack, dossier, liaison, remontée).
> - Pattern d'implémentation : « orchestrateur + refs » à la `kp-setup`.
> - Agnosticité via bloc `testing:` dans `.kp-agents.yml` (framework, tests_dir, run_commands, case_repository, **isolation**, conventions_doc, discovery).
> **Questions résolues** : binôme→agent unique ; conversationnel (pas Workflow) ; liaison = préfixe `[KP-]` regex-paramétrable ; persona = garant DoD ; seeds = kp-developer (dédiés test).
> **À traiter (architect)** :
> - Figer la **DoD à 6 critères** comme spec opposable de l'agent.
> - Schéma exact du bloc `testing:` (valider contre keyprod + 1 projet fictif).
> - Structure des 6 refs : confirmer le découpage, **trancher `e2e-data-isolation` en ref dédiée ou section de `test-implementation`**.
> - **Protocole de détection d'état** : ordre des lectures (story → grep filesystem → MCP Xray → historique Test Executions), cas ambigus, mode dégradé si Playwright MCP indispo.
> - Modes forçables (`design`/`implement`/`sync`/`audit`) vs 100 % auto.
> - Stratégie de remplacement xray+e2e : retrait propre (`.installed-agents`) ± stub de redirection ; **bump version** (`--minor` vs `--major`).
> - Gestion de la contradiction i18n EN local vs FR remote (côté `test-implementation`).
> - Invariant seed (D5) : comment l'agent **détecte** qu'un seed est métier et non test (heuristique : hors `test_seed_namespace`).
> - **Détection d'état (spike F2/F3)** : gérer **4 états filesystem** (absent / squelette `->todo()` / rédigé-bloqué avec `BLOCKER:` / actif) + statut runtime, et **parser les commentaires `BLOCKER:`** pour router les préconditions vers `kp-developer`.
> - **Catalogue de préconditions/flags tenant** (ex. `enable_create_deviceless_event`) : en config `testing:` ou via convention `BLOCKER:` ? (spike F3)
> - **Mapping clé ↔ `it()` = 1:N** (spike F4) : agréger les `it()` d'une même clé (statut max FAILED>PASSED>TODO) pour juger la couverture d'un cas.
> - **Double canal de liaison (spike FX2)** : DoD critère 3 = cohérence bidirectionnelle préfixe `[KP-]` ⇄ ligne `Automatisation:` de la description Xray.
> - **Accès au référentiel (spike FX1)** : MCP Atlassian standard suffit pour lire/auditer/créer le **contenu** d'un cas (description en gabarit Persona/Écran/Préconditions/Étapes/Résultat/Automatisation/Cadre) ; GraphQL Xray seulement pour le **rangement folder** `/Tests PlayWright`. Décider la dépendance exigée par `kp-test`.
> - **Lien story + conventions (spike FX3/FX4)** : « lié à la story » = warn/configurable (référentiel actuel `issuelinks: []`) ; label réel `pest-browser` ; steps en prose markdown dans la description (pas de Manual Steps natifs).
> **Recommandation de séquence** : (1) ~~spike DoD+détection~~ **fait le 2026-06-04** (cf. § Spike — partie filesystem validée ; reste la partie Xray live quand MCP Atlassian dispo) ⟶ (2) design architect ⟶ (3) implémentation developer.
> **Fichiers de référence** :
> - `docs/ideas/e2e-orchestrator.md` (ce fichier)
> - `agents/kp-xray.md`, `agents/kp-e2e.md` (à remplacer par `agents/kp-test.md`)
> - `agents/kp-setup.md` (modèle orchestrateur + refs) ; `includes/sources-config*.md` (modèle dimension `testing`)
> - `/Users/vincent/GIT/keyprod/docs/architect.md` ADR-011/012/013
> - `/Users/vincent/GIT/keyprod/apps/kpweb/docs/e2e/*` (skill, conventions, xray-sync, xray-test-authoring-guide, local-env, test-axes, keyprod-overview, navigation-patterns, kpweb-recommendations)
> - `/Users/vincent/GIT/keyprod/apps/kpweb/database/seeds/Browser/BrowserTestSeeder.php`

---
