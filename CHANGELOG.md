# Changelog

Toutes les modifications notables de kp-agents sont listées ici. Format inspiré de [Keep a Changelog](https://keepachangelog.com/), versioning semver.

Chaque plugin de la marketplace est versionné indépendamment (`plugin.json` → champ `version`). Les tags git suivent le format `<plugin-name>-v<X.Y.Z>`.

> **Note sur l'auto-bump** : depuis la release v0.3.0, `sync.sh` bumpe automatiquement le composant `patch` de la version quand le contenu des skills change (hash SHA256 stocké dans `plugin.json._contentHash`). Les flags `--minor` et `--major` permettent de forcer un bump de niveau supérieur. Voir ADR-005 dans [`docs/architect.md`](docs/architect.md).

---

## [kp-agents-v0.3.0] — à venir (épic E-0002 terminée)

Introduction de l'auto-bump de version du plugin `kp-agents` — le composant `patch` est désormais incrémenté automatiquement à chaque modification du contenu des skills, sans action manuelle du contributeur.

### Ajouté

- **Auto-bump patch** (S-0001) : `sync.sh` calcule un hash SHA256 stable sur `plugins/kp-agents/skills/**/SKILL.md` et incrémente le composant `patch` de la version si le hash a changé depuis le précédent sync.
- **Champs custom `_contentHash` et `_lastAutoVersion`** dans `plugin.json` (préfixés `_`, acceptés par `claude plugin validate`). Servent respectivement à détecter les changements de contenu et à repérer les bumps manuels.
- **Flags `--minor` et `--major`** (S-0002) : bump explicite des composantes semver supérieures avec reset des composantes inférieures (ex: `0.3.5 --minor` → `0.4.0`). Flags mutuellement exclusifs, incompatibles avec `--clean` / `--clean-all`.
- **Détection du bump manuel** (S-0002) : un édit direct de `version` dans `plugin.json` est respecté — `sync.sh` ne re-bumpe jamais par-dessus une saisie humaine.
- **ADR-005** (S-0003) : `docs/architect.md` documente la décision, les 5 alternatives rejetées et les conséquences. ADR-004 (versioning manuel) passée en `deprecated`.
- **Section Troubleshooting versioning** (S-0003) dans `README.md` : 3 cas couverts (version ne bouge pas, conflit merge Git sur `plugin.json`, rollback d'une release).

### Modifié

- `README.md` et `CLAUDE.md` : l'étape de bump manuel dans "Publier une mise à jour" a été remplacée par une description du bump automatique + des flags `--minor`/`--major`.
- `CLAUDE.md` : tableau "Flags disponibles" enrichi de `--minor` et `--major` avec règles d'exclusivité.

### Notes

- Aucun changement breaking pour les consommateurs du plugin (le flow d'installation et d'utilisation reste identique).
- Pour les contributeurs : l'étape "bumper `plugin.json` à la main" disparaît du workflow standard. Elle reste possible en cas de besoin explicite (et est respectée par le mécanisme).
- Dépendances : `shasum` (ou fallback `openssl`) + `python3` — tous standard macOS/Linux.

---

## [kp-agents-v0.2.0] — 2026-04-18

Optimisation transverse des 7 agents selon les best practices agentskills.io, clôture de l'epic **E-0003 Optimisation-Agents-Best-Practices**.

### Cohérence (S-0001, S-0003)

- **Bloc Activation factorisé** dans `includes/activation.md` et inclus via `{{include:activation}}` dans les 7 agents — suppression de la duplication mot-à-mot.
- **Include `includes/dependency-versions.md`** créé et inclus dans `architect`, `developer`, `review` (seuls agents qui installent / mettent à jour des dépendances).
- **Section `## Gotchas`** ajoutée à chaque agent, placée **avant** `## Règles`. 4 items communs factorisés dans `includes/gotchas-transverses.md` (`plugins/` + `dist/` générés, INDEX.md propriété de documentation, numérotation locale des stories, archives en lecture seule) + 4 à 6 items spécifiques par agent.

### Descriptions (S-0002)

- **Toutes les descriptions `description:` du frontmatter réécrites** en impératif : "Use this skill when…" + verbes déclencheurs + cas de non-usage explicite. Longueur < 530 caractères par description (bien sous la limite Claude 1024).
- Objectif : améliorer le trigger matching côté Claude Code (skill selection) sans rupture fonctionnelle.

### Refactoring (S-0004, S-0005, S-0006)

- **product** : document raccourci (243 → 127 lignes). Mode `init` déplacé en étape 1, 3 templates inline remplacés par des `{{include:*-template}}`, exemples de calibrage extraits dans leur propre section.
- **developer** : étapes 6 (Bilan) + 7 (Mise à jour doc) fusionnées en `### 6. Bilan et relais documentaire` (7 sous-points numérotés couvrant testable → mise à jour epic). Étape 5 (Simplification) rendue portable multi-cibles (`/simplify` Claude Code / équivalent Cursor / Codex / passe manuelle). Ajout d'un exemple pédagogique `## Validation par critère` (✅ bon / ❌ trop vague).
- **brainstorm** : « Choix de méthode » simplifié en 1 défaut explicite (**Starbursting**) + 2 alternatives contextuelles, autres méthodes sur demande. `STOP` ajouté à l'étape 4.
- **architect** : « Processus » et « Format recommandé » fusionnés en une checklist unique à 9 points. 4 règles génériques élaguées.
- **review** : étape « Revue automatisée » condensée de 17 → 4 lignes ; 7 règles → 4, déduplication avec les Gotchas.
- **documentation** : bloc « Format de l'index » (52 lignes) extrait en `includes/index-template.md`. 12 règles → 6 (déduplication avec le processus et les Gotchas).
- **ux-ui** : mini-template de specs Developer ajouté (tokens CSS custom properties + états de composant + breakpoints). Slogan « belle mais confuse » remplacé par une consigne actionnable (hésitation > 2s).

### Outillage (S-0007)

- Structure d'évaluation mise en place dans `agents/_evals/` (mainteneurs uniquement, **ignorée par `sync.sh`**) pour les 2 agents pilotes **developer** et **review**.
- Chaque agent pilote a :
  - `trigger_queries.json` : 20 prompts annotés (10 positifs + 10 négatifs avec `reason` de near-miss), ~30 % EN / 70 % FR.
  - `output_evals.json` : 3 cas de bout en bout avec assertions objectives (`file_contains`, `frontmatter_field_equals`, `section_order`, `file_absent`, `git_files_unchanged`, `response_contains_any`).
- `agents/_evals/README.md` documente le protocole et le format prévu pour un futur `benchmark.json`.
- Exécution des evals hors périmètre de cette release — structure en place, exécution à planifier.

### Notes

- Aucun changement breaking. Les utilisateurs installés en v0.1.0 reçoivent la v0.2.0 via `/plugin marketplace update` + `/plugin install kp-agents@kp-agents`.
- Gain de lisibilité mesurable : les 7 sources `agents/*.md` perdent ~400 lignes cumulées (extraction d'includes + dédoublonnage), aucun contenu fonctionnel supprimé.

---

## [kp-agents-v0.1.0] — 2026-04-17

Première release officielle du plugin `kp-agents`, distribué via la marketplace Claude Code `kp-agents` (hébergée sur GitHub `KeyProd/kp-agents`).

### Ajouté

- Plugin `kp-agents` au format Claude Code natif : 7 skills (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`) dans `plugins/kp-agents/skills/`
- Marketplace catalogue `.claude-plugin/marketplace.json` à la racine du repo, distribué via GitHub
- Namespaces d'invocation : `/kp-agents:brainstorm`, `/kp-agents:product`, etc. (7 commandes)
- Nouvelle section `Troubleshooting` dans `README.md` documentant :
  - Purge du cache plugin en cas d'anomalie `0 skills`
  - Migration des anciens `/kp-brainstorm` vers `/kp-agents:brainstorm`
  - Installation depuis une branche feature
- `docs/product.md` — vision produit, personas, KPIs
- `docs/architect.md` — architecture complète avec 4 ADR et diagrammes Mermaid
- `docs/project/roadmap.md` — Phase 1 (migration plugin) + Phase 2 (ouverture publique)
- Epic `E-0001 Plugin-Marketplace` avec 3 stories (S-0001, S-0002, S-0003)

### Modifié

- **Plugin renommé** : `kp-core` → `kp-agents` pour aligner le nom du plugin sur celui de la marketplace et du projet
- `sync.sh` refactoré :
  - Retrait complet de la génération et installation vers `~/.claude/commands/` (fonctions `generate_claude*` supprimées)
  - Nouvelle fonction `generate_plugin` produisant `plugins/kp-agents/skills/<name>/SKILL.md` avec frontmatter Claude plugin minimal
  - Nouvelle fonction `cleanup_legacy_claude` idempotente qui purge les résidus d'installations Claude locales antérieures
  - Flags `--clean` et `--clean-all` adaptés : préservent `plugin.json` (statique) mais purgent `plugins/kp-agents/skills/`
  - Messages d'aide (`--help`) et logs finaux mis à jour
- Documentation entièrement réalignée sur l'architecture plugin marketplace :
  - `README.md` : installation scindée entre plugin Claude et `sync.sh` (Cursor/Codex), suppression section RecetteMoi
  - `CLAUDE.md` : section Distribution, structure du projet, workflow inter-agents avec namespaces `/kp-agents:<nom>`
  - `docs/agents.md` : retrait complet de la section Pipeline RecetteMoi, namespaces mis à jour dans 8 diagrammes Mermaid

### Supprimé

- **Agents RecetteMoi** (`recettemoi-support`, `recettemoi-dev`, `recettemoi-review`) — hors périmètre du plugin
- Plugin temporaire `kp-agents-spike` (anciennement `kp-core-spike`) utilisé pour le spike de faisabilité
- Cible d'installation Claude locale dans `sync.sh` et `dist/claude/` (désormais distribué via plugin marketplace)

### Architecture

Migration achevée vers une architecture marketplace + plugin natif :
- **Claude Code** : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
- **Cursor** : `./sync.sh` installe les règles dans `~/.cursor/rules/`
- **Codex** : `./sync.sh` installe les skills dans `~/.codex/skills/`

Source unique : `agents/*.md` avec directives `{{include:xxx}}` résolues par `sync.sh`.

### Notes de migration pour utilisateurs existants

Si tu avais installé kp-agents avec une version antérieure de `sync.sh` :

1. Lance `./sync.sh` une fois — les anciens `~/.claude/commands/kp-*.md` seront automatiquement purgés (cleanup idempotent)
2. Installe le plugin via `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
3. Les anciens noms `/kp-brainstorm` deviennent `/kp-agents:brainstorm` (namespace imposé par Claude Code)

Si tu avais installé le spike `kp-agents-spike` :

1. `/plugin uninstall kp-agents-spike@kp-agents`
2. `/plugin marketplace update kp-agents`
3. `/plugin install kp-agents@kp-agents`
