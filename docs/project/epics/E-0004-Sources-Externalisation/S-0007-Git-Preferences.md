---
title: Préférences Git dans setup
date: 2026-04-21
status: DONE
author: product-agent
story-id: S-0007
epic-id: E-0004
---

# S-0007 - Préférences Git dans setup

## Résumé

Étendre l'agent `setup` (créé en S-0002) pour qu'il collecte et persiste des **préférences Git au niveau du projet** : règles de nommage des branches, commit automatique oui/non, push automatique oui/non. Ces préférences sont ensuite lues par les agents qui manipulent git (`developer`, `review`) pour aligner leur comportement.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux pouvoir définir les règles Git de mon projet une seule fois, afin que les agents qui touchent git (developer, review) respectent ma convention sans que je doive leur rappeler à chaque fois.

## Contexte

- Livraison progressive de l'agent `setup` : S-0002 couvre les sources, cette story étend au périmètre Git.
- Périmètre volontairement restreint à 3 préférences (branches, commit auto, push auto) — évite le sur-design.
- La persistance utilise la même mécanique que les sources : `.kp-agents.yml` (commité, car ces préférences sont spécifiques au projet et partagées en équipe).

## Règles métier

- Les 3 préférences gérées en V1 :
  1. **Convention de nommage de branches** : pattern texte, exemples `feat/{slug}`, `feature/KP-{ticket}-{slug}`, `feature/{slug}`. Libre, mais l'agent doit valider que c'est un pattern utilisable.
  2. **Commit automatique par l'agent** : oui / non / demander. Si `non`, l'agent annonce les modifications mais ne commit pas. Si `demander`, l'agent demande confirmation avant chaque commit.
  3. **Push automatique par l'agent** : oui / non / demander. Même sémantique que commit.
- Les préférences sont écrites dans `.kp-agents.yml` sous une clé `git:` dédiée :
  ```yaml
  git:
    branch_pattern: "feat/{slug}"
    auto_commit: ask        # yes | no | ask
    auto_push: no           # yes | no | ask
  ```
- **Par défaut (absence de config)** : `auto_commit: ask`, `auto_push: no`, `branch_pattern` non renseigné (l'agent ne force rien).
- Les agents `developer` et `review` lisent cette section en début de session et adaptent leur comportement.
- **Non-régression** : un projet sans section `git:` dans `.kp-agents.yml` garde exactement le comportement actuel (demande de confirmation avant commit/push).

## Scénarios

### Nominal
- Étant donné un projet avec déjà une config sources
- Quand l'utilisateur invoque `/kp-agents:setup` et demande à configurer les préférences Git
- Alors l'agent pose 3 questions (pattern de branche, auto_commit, auto_push), valide les réponses, et ajoute la section `git:` au `.kp-agents.yml`.

### Alternatif
- Étant donné un projet avec `git.auto_commit: no`
- Quand `/kp-agents:developer` termine l'implémentation d'une story
- Alors l'agent staged les changements mais **ne crée pas de commit** — il annonce à l'utilisateur ce qui est prêt et laisse la main.

### Erreur / refus
- Étant donné un `branch_pattern` mal formé (ex: `{slug` sans accolade fermante)
- Quand l'agent `setup` tente de le valider
- Alors il refuse l'entrée, explique le problème, et re-prompt.

## Cas limites

- [ ] `branch_pattern` avec un placeholder inconnu (ex: `{unknown}`) → warn mais accepter (l'utilisateur décide)
- [ ] Utilisateur invoque `setup` alors que `.kp-agents.yml` n'existe pas → `setup` crée le fichier avec la section `git:` uniquement (sources par défaut à `local`)
- [ ] Préférences présentes mais incomplètes (seulement `branch_pattern`, pas d'`auto_commit`) → utiliser valeurs par défaut pour les manquants, ne pas bloquer
- [ ] Agent `developer` ou `review` en mode `auto_commit: yes` mais la signature GPG échoue → **toujours** annoncer l'erreur à l'utilisateur, ne pas sauter silencieusement la signature

## Critères d'acceptation

- [ ] L'agent `setup` propose un flow dédié « configurer les préférences Git » distinct du flow « configurer les sources »
- [ ] Les 3 préférences sont écrites proprement sous la clé `git:` de `.kp-agents.yml`
- [ ] L'agent `setup` valide le `branch_pattern` (syntaxe parseable) avant d'enregistrer
- [ ] Les agents `developer` et `review` lisent la section `git:` et adaptent leur comportement :
  - `auto_commit: ask` (défaut) → demande avant de commit
  - `auto_commit: yes` → commit sans demander
  - `auto_commit: no` → ne commit jamais
- [ ] Même logique appliquée pour `auto_push`
- [ ] Le `branch_pattern` est respecté par `developer` lors de la création d'une branche feature
- [ ] Test manuel : configurer `auto_commit: no`, lancer une story, vérifier qu'aucun commit n'est créé
- [ ] Test manuel : configurer `auto_push: yes`, vérifier qu'après commit l'agent push sans demander
- [ ] Non-régression : projet sans section `git:` = comportement actuel (demande confirmation)

## Dépendances

- **S-0002** (agent setup existe) — bloquant
- **S-0003** (agents existants lisent la config) — souhaité pour cohérence

## Notes techniques

- La préférence `auto_commit: yes` **doit** respecter les règles globales de CLAUDE.md (jamais `--no-verify`, jamais skip hooks). Les préférences projet ne surchargent pas les règles de sécurité globales.
- Garder le périmètre strict : ne pas ajouter de convention de commit message (Conventional Commits, etc.) dans cette story — trop de choix subjectifs, candidat pour une future story.
- Le `branch_pattern` peut faire référence à des variables futures (numéro de ticket JIRA si `tickets.mode: mcp`). Documenter les placeholders supportés.

## Instrumentation / mesure

- Compter le nombre de projets qui activent `auto_commit: yes` vs `no` vs `ask` (anecdotique, pour calibrer les défauts)

## Questions ouvertes

- Faut-il supporter un `branch_pattern` différent selon le type de story (`feat/`, `fix/`, `chore/`) ? → **Décision V1 : non**, un seul pattern. Évolution candidate si le besoin se confirme.

## Implémentation

### Nature

Extension descriptive des règles de configuration, cohérent avec le pattern des stories précédentes. Les préférences `git:` sont une 3ème dimension indépendante, découplée de `product:` et `tickets:`.

### Fichiers modifiés

| Fichier | Avant | Après | Δ |
|---|---:|---:|---:|
| `includes/sources-config.md` | 247 | 273 | +26 |
| `agents/setup.md` | 180 | 196 | +16 |
| `agents/developer.md` | 261 | 274 | +13 |
| `agents/review.md` | 250 | 261 | +11 |

### Détail des modifications

1. **`includes/sources-config.md`** :
   - Bloc `git:` ajouté au schéma `.kp-agents.yml` en tête de document.
   - Nouvelle section `### Préférences Git (git:)` avec tableau sémantique (3 champs : `branch_pattern`, `auto_commit`, `auto_push`), règles d'application (priorité règles sécurité, échec silencieux interdit, validation pattern, partialité, découplage des dimensions).

2. **`agents/setup.md`** :
   - Étape 3 « Questions ciblées » — mention explicite que 3 dimensions indépendantes sont gérées (product / tickets / git).
   - Bloc « Dimension `git` » avec les 3 questions formulées (pattern, auto_commit, auto_push) et leurs défauts explicites.
   - Règles : validation `branch_pattern` avant écriture, YAML clairsemé (ne pas écrire les défauts).
   - 2 cas limites ajoutés : `auto_commit: yes` ne débloque pas les règles de sécurité, changement de pattern en cours de projet non rétroactif.
   - Commande CLI `« configure git »` ajoutée aux available commands.

3. **`agents/developer.md`** :
   - Nouvelle sous-section `### Préférences Git (git:)` après le bloc `tickets.mode: mcp`.
   - Application des 3 préférences : pattern pour le nom de branche, auto_commit 3 valeurs, auto_push 3 valeurs.
   - Règle de sécurité : jamais de skip hook / bypass signature, même en `yes`.

4. **`agents/review.md`** :
   - Nouvelle sous-section `### Préférences Git (git:)` (périmètre plus étroit — pas de branch_pattern, review ne crée pas de branche).
   - Message de commit standardisé pour les GO/NO-GO.
   - Même règle de sécurité.

### Mesures SKILL.md générés

| Agent | Avant (S-0006) | Après S-0007 | Δ |
|---|---:|---:|---:|
| architect | 516 | 545 | +29 |
| brainstorm | 516 | 545 | +29 |
| developer | 598 | **635** | +37 |
| documentation | 550 | 579 | +29 |
| product | 506 | 535 | +29 |
| review | 587 | 622 | +35 |
| setup | 503 | 548 | +45 |
| ux-ui | 549 | 578 | +29 |

**developer** à 635 lignes — plus gros agent, bien au-dessus du seuil de 500 mais toujours sous 700. Acceptable pour une epic complète. À mesurer après S-0008 pour décider si refactoring nécessaire.

### Vérifications techniques

- `grep '{{include' plugins/kp-agents/skills/*/SKILL.md` → **0 résidu**.
- `grep -l 'git.auto_commit' plugins/kp-agents/skills/*/SKILL.md` → **8 matches** (include inliné partout).
- `./sync.sh --dist-only` : 8 agents syncés dans 3 cibles sans erreur, auto-bump patch déclenché.

### Commandes de test (pour l'utilisateur)

Test manuel sur un projet kp-agents :

1. **Test `auto_commit: no`** :
   ```yaml
   # .kp-agents.yml
   git:
     auto_commit: no
   ```
   Invoquer `/kp-agents:developer` sur une story → vérifier qu'aucun commit n'est créé en fin (seulement `git add`).

2. **Test `auto_push: yes`** :
   ```yaml
   git:
     auto_commit: yes
     auto_push: yes
   ```
   Vérifier qu'après le commit, l'agent push sans demander.

3. **Test `branch_pattern`** :
   ```yaml
   git:
     branch_pattern: "feat/{slug}"
   ```
   Demander à `developer` d'implémenter une story nommée « Login Form » → vérifier que la branche `feat/login-form` est créée sans prompt.

4. **Test non-régression** :
   Projet sans `.kp-agents.yml` (ou sans bloc `git:`) → `/kp-agents:developer` demande confirmation avant commit, `/kp-agents:review` idem, pas de push automatique. Comportement identique à avant.

5. **Test sécurité** :
   `auto_commit: yes` + un hook pre-commit qui échoue → vérifier que l'agent annonce l'erreur et laisse la main, ne réessaie **jamais** avec `--no-verify`.

### Limites

- **Test E2E pas automatisé** : l'implémentation est descriptive, la vérification repose sur un test manuel par l'utilisateur.
- **Placeholders `{ticket}` / `{epic}`** : supportés seulement si la story implémentée provient de `tickets.mode: mcp` ou a un ID kp-agents. En cas d'invocation adhoc sans ticket identifié, fallback sur `{slug}` seul ou prompt.
- **Pas de convention de message de commit** : la story exclut explicitement cela pour éviter les choix subjectifs. Un message par défaut simple est utilisé.
- **Pas de support multi-pattern par type de story** (`feat/` vs `fix/` vs `chore/`) : décision V1 assumée dans la story.

## Validation par critère

- **L'agent `setup` propose un flow dédié « configurer les préférences Git » distinct du flow sources** : ✅ bloc « Dimension `git` » ajouté dans l'étape 3 de `agents/setup.md`, commande `« configure git »` dans available commands, orientation en début de flow qui mentionne les 3 dimensions indépendantes.
- **Les 3 préférences sont écrites proprement sous la clé `git:` de `.kp-agents.yml`** : ✅ schéma YAML documenté en tête de l'include, cohérent avec le pattern `product:` et `tickets:`.
- **L'agent `setup` valide le `branch_pattern` (syntaxe parseable) avant d'enregistrer** : ✅ règle explicite dans la section « Questions ciblées » de setup + rappel dans « Règles d'application » de l'include (accolades fermées, placeholders connus warn si inconnus).
- **Les agents `developer` et `review` lisent la section `git:` et adaptent leur comportement** : ✅ sous-sections `### Préférences Git` ajoutées aux 2 agents, sémantique `yes/no/ask` documentée pour `auto_commit` et `auto_push`.
- **Même logique appliquée pour `auto_push`** : ✅ dans developer et review, avec défaut `no` (push reste une décision explicite).
- **Le `branch_pattern` est respecté par `developer` lors de la création d'une branche feature** : ✅ documenté dans la section dédiée de developer — pattern appliqué au moment de proposer la branche, sans prompt si le pattern est présent.
- **Test manuel `auto_commit: no`** : ⚠️ **à exécuter par l'utilisateur** — protocole documenté.
- **Test manuel `auto_push: yes`** : ⚠️ **à exécuter par l'utilisateur** — protocole documenté.
- **Non-régression : projet sans section `git:` = comportement actuel** : ✅ règle explicite dans l'include (« Non-régression absolue : si la clé `git:` est absente, les agents se comportent comme aujourd'hui »). À confirmer par test manuel utilisateur sur `kp-agents` lui-même (pas de `.kp-agents.yml`).
