---
title: Flags --minor et --major + respect du bump manuel
date: 2026-04-18
status: TODO
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

*à compléter par l'agent Developer*

- Fichiers créés / modifiés : `sync.sh`, `plugins/kp-agents/.claude-plugin/plugin.json`, `CLAUDE.md`, `README.md`
- Commandes de test :
  - `./sync.sh --minor` avec contenu inchangé → 0.x.y → 0.(x+1).0
  - `./sync.sh --major` → 0.x.y → 1.0.0
  - `./sync.sh --minor --major` → erreur
  - Éditer `plugin.json` à la main (`version: "0.5.0"`), lancer `./sync.sh` → respect de la version
- Notes de review : à compléter

## Validation par critère

*à compléter lors de la review*
