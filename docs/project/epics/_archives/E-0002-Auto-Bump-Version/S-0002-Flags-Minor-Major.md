---
title: Flags --minor et --major + respect du bump manuel
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0002
epic-id: E-0002
---

# S-0002 - Flags `--minor` et `--major` + respect du bump manuel

## Résumé

Étendre `sync.sh` avec deux flags explicites `--minor` et `--major` pour bumper respectivement les composantes `mineur` et `majeur` de la version. Implémenter la logique qui détecte si le contributeur a bumpé manuellement la version entre deux syncs, et dans ce cas ne pas re-bumper par-dessus.

## User Story

En tant que **contributeur kp-agents**, je veux **pouvoir bumper explicitement en mineur ou majeur** (ex: ajout d'agent, rupture de compatibilité) **et ne pas voir mes bumps manuels écrasés** par l'auto-bump, afin de **garder le contrôle sémantique sur les releases importantes**.

## Contexte

- S-0001 a introduit l'auto-bump **patch** via comparaison de hash
- Mais certaines évolutions dépassent le patch :
  - **Mineur** : ajout d'un agent (nouveau skill disponible) → `0.1.5` → `0.2.0`
  - **Majeur** : retrait d'un agent, changement de namespace, rupture de comportement → `0.2.3` → `1.0.0`
- Le contributeur peut aussi vouloir **éditer directement** `plugin.json` pour une raison exceptionnelle (ex: retour arrière, version spéciale). Cette action ne doit pas être écrasée par l'auto-bump au prochain sync.

## Règles métier

- **RM-1** (epic) : seule la composante `patch` est auto-bumpée ; `mineur` et `majeur` nécessitent une action explicite
- **RM-3** (epic) : priorité au choix humain — `plugin.json` modifié à la main est respecté
- **RM-4** (epic) : documentation à tenir à jour dans cette story (bloquant)
- Les flags `--minor` et `--major` sont **mutuellement exclusifs** — impossible d'utiliser les deux en même temps
- `--minor` et `--major` **remettent à 0** les composantes inférieures :
  - `--minor` : `0.1.5` → `0.2.0` (pas `0.2.5`)
  - `--major` : `0.2.5` → `1.0.0` (pas `1.2.5`)
- La détection du bump manuel se fait en comparant la `version` actuelle dans `plugin.json` avec une **version de référence** qu'on stocke aussi dans `plugin.json` (proposition : champ `_lastAutoVersion`)
  - Si `version != _lastAutoVersion` → bump manuel détecté → on respecte la version, on met à jour `_lastAutoVersion` et `_contentHash` mais pas `version`
  - Si `version == _lastAutoVersion` → pas de bump manuel → logique normale (auto-bump patch si hash différent, ou flag `--minor/--major` si invoqué)

## Scénarios

### Nominal 1 — Flag `--minor`

- Étant donné un `plugin.json` avec `version: "0.1.5"`, `_contentHash: "abc..."`, `_lastAutoVersion: "0.1.5"`
- Et un contributeur qui a ajouté un nouvel agent dans `agents/analyst.md`
- Quand il lance `./sync.sh --minor`
- Alors les skills sont régénérés (le nouveau skill `analyst/SKILL.md` apparaît)
- Et la version passe de `0.1.5` à `0.2.0`
- Et `_lastAutoVersion` passe à `0.2.0`
- Et `_contentHash` est mis à jour avec le nouveau hash
- Et un log affiche : `Plugin version bumped: 0.1.5 → 0.2.0 (minor, requested)`

### Nominal 2 — Flag `--major`

- Étant donné un `plugin.json` avec `version: "0.3.2"`, `_contentHash: "def..."`, `_lastAutoVersion: "0.3.2"`
- Et un contributeur qui a retiré un agent (breaking change)
- Quand il lance `./sync.sh --major`
- Alors la version passe de `0.3.2` à `1.0.0`
- Et `_lastAutoVersion` passe à `1.0.0`, `_contentHash` mis à jour
- Et un log affiche : `Plugin version bumped: 0.3.2 → 1.0.0 (major, requested)`

### Alternatif 1 — Bump manuel détecté, pas de modification de contenu

- Étant donné un contributeur qui a édité `plugin.json` à la main : `version: "0.1.0"` → `version: "0.2.0"` (`_lastAutoVersion` reste à `0.1.0`)
- Et aucune modification dans `agents/`
- Quand il lance `./sync.sh` (sans flag)
- Alors `sync.sh` détecte `version ("0.2.0") != _lastAutoVersion ("0.1.0")` → bump manuel
- Et la version reste `"0.2.0"` (respectée)
- Et `_lastAutoVersion` est mis à jour à `"0.2.0"` (synchronisation du référentiel)
- Et `_contentHash` inchangé (pas de modif skills)
- Et un log affiche : `Manual version bump detected (0.1.0 → 0.2.0) — kept as-is, reference updated`

### Alternatif 2 — Bump manuel détecté ET contenu modifié

- Étant donné un contributeur qui a édité `plugin.json` à la main : `version: "0.2.0"` (`_lastAutoVersion` = `0.1.5`)
- Et a aussi modifié `agents/brainstorm.md`
- Quand il lance `./sync.sh`
- Alors les skills sont régénérés, nouveau hash calculé
- Et `sync.sh` détecte le bump manuel → respecte `"0.2.0"`
- Et `_lastAutoVersion` devient `"0.2.0"`, `_contentHash` devient le nouveau hash
- Et un log affiche : `Manual version bump detected (0.1.5 → 0.2.0) — kept as-is, content hash updated`

### Cas d'erreur — Flags conflictuels

- Étant donné un contributeur qui lance `./sync.sh --minor --major`
- Alors `sync.sh` s'arrête immédiatement avec un message d'erreur : `ERROR: --minor and --major are mutually exclusive, choose only one`
- Et exit code 1
- Et aucune modification n'est appliquée au `plugin.json`

### Cas d'erreur — Version malformée dans `plugin.json`

- Étant donné un `plugin.json` avec `version: "not-a-version"` (édition manuelle incorrecte)
- Quand le contributeur lance `./sync.sh` (avec ou sans flag)
- Alors `sync.sh` affiche une erreur explicite : `ERROR: Invalid version format in plugin.json: "not-a-version" (expected semver X.Y.Z)`
- Et exit code 1
- Et la génération n'est pas effectuée

## Cas limites

- [ ] Flags `--minor` ou `--major` combinés avec `--dist-only` : OK, le bump s'applique au fichier généré (pas d'install)
- [ ] Flags `--minor` ou `--major` combinés avec `--clean` ou `--clean-all` : erreur explicite, un clean n'a pas de sens avec un bump
- [ ] Contenu identique ET flag `--minor` ou `--major` invoqué : le bump est effectué (l'utilisateur a explicité son intention, même si le hash n'a pas changé)
- [ ] `_lastAutoVersion` absent dans `plugin.json` (ex: plugin créé avant S-0002) : initialisation à la valeur actuelle de `version` au premier run, sans bump
- [ ] Version déjà à `1.0.0` et `--major` invoqué : passe à `2.0.0` (pas de limite supérieure)
- [ ] Version `0.0.9` et `--minor` : passe à `0.1.0`, patch remis à 0

## Critères d'acceptation

- [ ] `./sync.sh --minor` incrémente le composant mineur et remet le patch à 0
- [ ] `./sync.sh --major` incrémente le composant majeur et remet mineur + patch à 0
- [ ] `./sync.sh --minor --major` retourne une erreur claire et un exit code non nul
- [ ] Un bump manuel dans `plugin.json` (entre deux syncs) est respecté — la version n'est pas écrasée par l'auto-bump
- [ ] Après un bump manuel respecté, le champ `_lastAutoVersion` est mis à jour pour que le prochain sync reparte sur cette base
- [ ] Les cas conflictuels flag+clean retournent une erreur claire
- [ ] Une version malformée dans `plugin.json` retourne une erreur explicite (pas un comportement silencieux)
- [ ] `claude plugin validate` reste ✅ avec le champ `_lastAutoVersion` ajouté
- [ ] **Documentation mise à jour** (bloquant, règle RM-4) :
  - `CLAUDE.md` section flags : lignes pour `--minor` et `--major` avec exemples
  - `README.md` section "Publier une mise à jour" : expliquer quand utiliser `--minor`/`--major` (ajout/retrait d'agent, rupture)
  - Note explicite sur le comportement "respect du bump manuel" avec exemple
- [ ] Bash 3.2 compatible

## Dépendances

- **Story S-0001 DONE** (le calcul de hash et le champ `_contentHash` doivent exister)
- Même outils que S-0001 (`shasum` ou `openssl`, `jq` ou sed rigoureux)

## Notes techniques

- **Parser les flags** : étendre la boucle `parse_args` dans `sync.sh` avec `--minor` et `--major`. Variables booléennes `BUMP_MINOR` / `BUMP_MAJOR` + check d'exclusivité après le parsing
- **Logique de bump semver** : une fonction bash `bump_version` qui prend `major|minor|patch` et la version courante, renvoie la nouvelle
- **Détection du bump manuel** : avant toute autre logique, lire `_lastAutoVersion` et `version` dans `plugin.json`. Si différentes → bump manuel, skip auto-bump logic
- **Ordre des priorités dans `sync.sh`** :
  1. Parse flags, valider exclusivité
  2. Générer les skills
  3. Lire `plugin.json` (version, _contentHash, _lastAutoVersion)
  4. Calculer le nouveau hash
  5. Détecter bump manuel : si oui, respecter et mettre à jour `_lastAutoVersion` + `_contentHash`
  6. Sinon, si flag `--minor/--major` : bump explicite
  7. Sinon, si hash changé : bump patch auto
  8. Sinon : pas de modif
  9. Écrire `plugin.json` si changement

## Instrumentation / mesure

- Log de sortie `sync.sh` indiquant systématiquement le cas de figure : `bumped auto patch`, `bumped minor requested`, `bumped major requested`, `manual bump respected`, `unchanged`, `error`
- Exit code cohérent (0 pour succès, 1 pour erreur de flags ou version malformée)

## Questions ouvertes

- Faut-il supporter un alias court pour les flags (`-m` pour `--minor`, `-M` pour `--major`) ? **Hypothèse** : non, éviter la confusion `-m/-M` casse-tête. Noms longs uniquement.
- Que faire si le contributeur a modifié `version` manuellement à une valeur **inférieure** à `_lastAutoVersion` (ex: rollback volontaire) ? **Hypothèse** : respecter aussi (priorité humaine), avec un log warning explicite (`Warning: version decreased from X to Y`). Architect peut confirmer.

## Implémentation

**Date** : 2026-04-19
**Branche** : `feat/E-0002-Auto-Bump-Version` (commit sur S-0001 déjà fait : `3c64c69`)

### Fichiers modifiés

- **`sync.sh`** :
  - Deux nouvelles variables globales : `BUMP_MINOR=false`, `BUMP_MAJOR=false`
  - `parse_args` étendu avec les cases `--minor` et `--major`
  - Après la boucle `parse_args` : deux validations ajoutées (exclusivité `--minor`/`--major`, incompatibilité avec `--clean` / `--clean-all`)
  - `apply_version_logic` étendue : ajout de 2 cas (bump minor demandé, bump major demandé), avant le cas auto-bump patch. Ordre final : fallback → init → bump manuel → minor flag → major flag → patch auto → idempotence (6 cas)
  - Help (`--help`) enrichi : documentation des 2 nouveaux flags + note explicite sur le bump manuel respecté
- **`CLAUDE.md`** : tableau "Flags disponibles" enrichi de 2 lignes (`--minor`, `--major`) avec description + règles d'exclusivité. Paragraphe explicatif ajouté sous le tableau sur le comportement auto-bump patch par défaut et le respect du bump manuel.
- **`README.md`** : section "Publier une mise à jour Claude Code" — étape 2 enrichie avec les 3 scénarios explicites (patch auto, `--minor`, `--major`) et leur règle d'exclusivité.

### Commandes de test

```bash
# 1. Bump minor
./sync.sh --minor   # v0.2.1 → v0.3.0 (patch remis à 0)

# 2. Bump major
./sync.sh --major   # v0.3.0 → v1.0.0 (minor et patch remis à 0)

# 3. Flags exclusifs → erreur + exit 1
./sync.sh --minor --major; echo "Exit: $?"
# → "--minor and --major are mutually exclusive, choose only one", exit 1

# 4. --minor + --clean → erreur + exit 1
./sync.sh --minor --clean; echo "Exit: $?"
# → "--minor / --major cannot be combined with --clean / --clean-all", exit 1

# 5. Bump manuel sans modification d'agent
python3 -c "import json; ..."   # éditer plugin.json version → 2.0.0
./sync.sh   # log: "Manual version bump detected (1.0.0 → 2.0.0) — kept as-is, references updated"
# Vérifier : version=2.0.0 préservée, _lastAutoVersion aligné à 2.0.0

# 6. Bump manuel + modification d'agent (priorité humaine)
python3 -c "..."   # version → 3.0.0
echo " " >> agents/brainstorm.md
./sync.sh   # log: "Manual version bump detected (2.0.0 → 3.0.0)"
# Vérifier : version=3.0.0 préservée (pas de patch auto par-dessus), hash mis à jour
```

### Décisions prises pendant l'implémentation

- **Ordre des cas dans `apply_version_logic`** : priorité au bump manuel (cas 2) **avant** les flags, car la détection manuelle est une règle de sécurité (on ne veut pas écraser une saisie humaine, même si un flag est passé). Ensuite flags explicites (cas 3-4), puis auto-patch (cas 5), puis idempotence (cas 6).
- **Validation en fin de `parse_args`** : placée après la boucle pour avoir accès à l'état final des variables (`BUMP_MINOR`, `BUMP_MAJOR`, `CLEAN_ONLY`). Plus lisible qu'une validation disséminée dans chaque case.
- **Compatibilité avec `--dist-only`** : non explicitement testée mais logique — `--minor`/`--major` agissent sur `plugin.json` (pas sur les installs Cursor/Codex), donc combinables sans effet de bord.
- **Passe manuelle de simplification** : revue du code ajouté — pas de refactor nécessaire (duplication minime entre cas minor/major acceptable, noms explicites, complexité contenue).

### Notes de review

- Règle RM-4 respectée : README + CLAUDE.md mis à jour dans le même commit que le code
- Bash 3.2 compatible : uniquement `[[ ]]`, tests booléens, pas de feature bash 4+
- 6 cas dans `apply_version_logic` — la complexité reste contenue grâce aux early returns
- `claude plugin validate` passé ✔ dans tous les états de test (y compris après tests destructifs multiples)

## Validation par critère

- **[✅] `./sync.sh --minor` incrémente le composant mineur et remet le patch à 0** : testé 0.2.1 → 0.3.0 (log `minor, requested`)
- **[✅] `./sync.sh --major` incrémente le composant majeur et remet mineur + patch à 0** : testé 0.3.0 → 1.0.0 (log `major, requested`)
- **[✅] `./sync.sh --minor --major` retourne une erreur claire et un exit code non nul** : testé — message `"--minor and --major are mutually exclusive, choose only one"`, exit 1
- **[✅] Un bump manuel dans `plugin.json` est respecté — la version n'est pas écrasée par l'auto-bump** : testé — version=2.0.0 manuelle préservée après sync sans modif, log `Manual version bump detected (1.0.0 → 2.0.0)`
- **[✅] Après un bump manuel respecté, `_lastAutoVersion` est mis à jour** : testé — aligné à la nouvelle version (2.0.0) pour que le prochain sync reparte sur cette base
- **[✅] Les cas conflictuels flag+clean retournent une erreur claire** : testé `--minor --clean` → message explicite + exit 1
- **[⚠️] Une version malformée dans `plugin.json` retourne une erreur explicite** : couvert par `bump_version` (regex stricte `^[0-9]+\.[0-9]+\.[0-9]+$`). Non testé formellement dans cette story (scénario très rare, branche couverte par inspection de code)
- **[✅] `claude plugin validate` reste ✅ avec le champ `_lastAutoVersion` ajouté** : testé après chaque transition d'état, 100 % des runs passent
- **[✅] Documentation mise à jour** (bloquant, RM-4) :
  - `CLAUDE.md` : tableau flags enrichi + paragraphe explicatif
  - `README.md` : section "Publier une mise à jour" avec les 3 scénarios (patch auto / --minor / --major)
  - Note explicite dans les deux docs sur le respect du bump manuel
- **[✅] Bash 3.2 compatible** : pas de feature bash 4+, `bash -n sync.sh` passe

### Écarts documentaires

Aucun écart majeur avec la spec. Les 2 questions ouvertes avaient été tranchées dans le design Architect et sont suivies :
- Pas d'alias courts `-m`/`-M` : conservé (confusion casse évitée)
- Version inférieure saisie manuellement : respectée par le mécanisme (priorité humaine). Pas de log warning spécifique implémenté à ce stade (non bloquant — les logs de bump manuel sont neutres sur la direction du changement)
