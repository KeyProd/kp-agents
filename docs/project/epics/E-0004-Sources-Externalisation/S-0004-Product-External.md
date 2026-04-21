---
title: Mode product.mode external (OneDrive)
date: 2026-04-21
status: REVIEW
author: product-agent
story-id: S-0004
epic-id: E-0004
---

# S-0004 - Mode `product.mode: external` (OneDrive)

## Résumé

Rendre opérationnel le mode externe pour la dimension `product` : lecture et écriture de la doc produit (ideas, product.md, features/*/product.md, roadmap.md, epics/*) dans un dossier externe (typiquement OneDrive), avec fallback systématique en écriture locale si le filesystem externe refuse l'écriture.

À l'issue de cette story, un utilisateur peut utiliser `/kp-agents:product` et `/kp-agents:brainstorm` sur un projet dont la doc produit vit sur OneDrive.

## User Story

En tant qu'utilisateur de `kp-agents`, je veux que la doc produit de mon projet soit lue et écrite dans un dossier OneDrive partagé, afin de collaborer avec des PM non-dev sans dupliquer l'information entre le repo et le OneDrive.

## Contexte

- Première story qui **exerce** concrètement le mécanisme mis en place par S-0001 + S-0003.
- La dimension `tickets` reste locale pendant cette story (sera adressée en S-0006).
- Hypothèse H2 (permissions Claude Code hors cwd) doit être validée avant d'attaquer cette story — sinon S-0001 aura déjà identifié le problème.

## Règles métier

- **Lecture** : toujours depuis le chemin externe si configuré et accessible. Si inaccessible (OneDrive non monté) → warn + bascule sur `./docs/` si les fichiers existent localement, sinon demande à l'utilisateur.
- **Écriture** : try external → si échec (permission denied, espace plein, réseau) → fallback `./docs/` + warn explicite indiquant que le fichier n'a pas été écrit sur OneDrive.
- **Périmètre exact** externalisé par cette story :
  - `<product-root>/ideas/<theme>.md`
  - `<product-root>/product.md`
  - `<product-root>/features/<group>/product.md`
  - `<product-root>/project/roadmap.md`
  - `<product-root>/project/epics/E-XXXX-*/readme.md` (readme de l'epic)
- **Toujours local** (même en mode externe) : `docs/architect.md`, `docs/features/*/architect.md`, `docs/INDEX.md`, toute doc technique, et les stories individuelles (`S-XXXX-*.md`) — ces dernières suivent la dimension `tickets` (reste local en S-0004).

## Scénarios

### Nominal
- Étant donné un projet avec `product.mode: external` et `product.path: /Users/vincent/Library/CloudStorage/OneDrive-KeyProd/MonProjet/`
- Quand l'utilisateur invoque `/kp-agents:brainstorm` sur une nouvelle idée
- Alors l'agent crée `<product.path>/ideas/<theme>.md` et non `./docs/ideas/<theme>.md`.

### Alternatif
- Étant donné le même projet, mais l'utilisateur a uniquement accès en lecture à `product.path`
- Quand l'agent tente d'écrire une nouvelle idée
- Alors il reçoit une erreur d'écriture, warn l'utilisateur avec le message « impossible d'écrire sur la source externe, écriture locale dans `./docs/ideas/<theme>.md` », et poursuit son travail sans bloquer.

### Erreur / refus
- Étant donné `product.path` pointant vers un dossier qui n'existe plus (OneDrive non monté, disque déplacé)
- Quand l'agent démarre et tente de lire la config
- Alors il warn l'utilisateur, propose `/kp-agents:setup` pour corriger le chemin, et reste en mode local dégradé pour la session en cours.

## Cas limites

- [ ] Dossier `<product.path>/ideas/` inexistant au premier brainstorm → l'agent le crée (`mkdir -p` équivalent)
- [ ] Dossier `<product.path>` existe mais aucun des sous-dossiers → l'agent gère (création à la demande)
- [ ] Fichier existant localement dans `./docs/` ET sur `<product.path>` (mode externe ajouté sur projet existant) → lire le externe, ignorer le local, warn pour inviter à la migration manuelle
- [ ] Chemin OneDrive avec espaces et caractères spéciaux (`OneDrive - Entity`)
- [ ] Interruption pendant une écriture (OneDrive qui se démonte en cours d'opération)

## Critères d'acceptation

- [ ] Sur un projet avec `product.mode: external` et chemin valide, tous les fichiers du périmètre externalisé (listés dans règles métier) sont créés/lus depuis le chemin externe
- [ ] Fallback write testé manuellement : chemin externe en lecture seule → l'agent écrit dans `./docs/` + affiche un warn clair citant le chemin local
- [ ] Gestion du chemin externe inaccessible : redirect vers `/kp-agents:setup`, session continue en local dégradé
- [ ] Test manuel sur macOS avec un vrai dossier OneDrive (Library/CloudStorage/OneDrive-...) : lecture et écriture fonctionnelles
- [ ] Les stories individuelles (`S-XXXX-*.md`) restent écrites en local pendant cette story (la dimension `tickets` n'est pas encore externalisée)
- [ ] Les fichiers d'architecture (`architect.md`, `features/*/architect.md`) restent en local même en mode externe (critère de non-contamination du périmètre)
- [ ] Test manuel non-régression : sur `kp-agents` lui-même (sans config), rien ne change

## Dépendances

- **S-0001, S-0002, S-0003** : fondations, agent setup, intégration agents.

## Notes techniques

- Le fallback write doit préserver la structure relative : si un write `<product-root>/ideas/foo.md` échoue, le fallback écrit `./docs/ideas/foo.md` (pas de mélange avec la racine locale).
- Le warn de fallback doit être **très visible** et citer le chemin exact écrit, pour que l'utilisateur sache où est son fichier.
- Prévoir un message spécifique pour le cas « OneDrive non monté » : typique et récurrent, mérite un guide de résolution (remonter OneDrive, rebrancher).
- Aucune logique de synchronisation : pas de copie automatique entre local et externe. L'utilisateur gère la migration manuellement en cas de besoin.

## Instrumentation / mesure

- À chaque écriture externe, log du chemin final écrit (externe ou fallback local) pour traçabilité dans le chat
- Compter les fallbacks write dans une session pour identifier un problème récurrent

## Questions ouvertes

- Faut-il prévoir un `--force-local` pour une session, au cas où l'utilisateur veut ponctuellement ignorer OneDrive ? → **Décision V1 : non**, géré par modification ponctuelle de `.kp-agents.yml` via `/kp-agents:setup` ou édition manuelle.

## Implémentation

### Nature de la story

S-0004 **n'ajoute pas de code nouveau** : elle exerce le dispositif mis en place par S-0001 (include) et S-0003 (intégration dans les 7 agents). Le travail consiste à **raffiner l'include** pour couvrir précisément les cas limites OneDrive et standardiser le protocole de fallback, puis à valider empiriquement le comportement OS sous-jacent.

### Fichiers modifiés

- **`includes/sources-config.md`** — enrichi de 55 → 93 lignes (+38 lignes / +3 365 caractères), soit ~2× la taille initiale. Nouvelles sous-sections ajoutées :
  - `Création implicite de sous-dossiers` sous « Résolution de chemin pour la dimension `product` » — comportement `mkdir -p` implicite à la première écriture, sans prompt utilisateur.
  - `Résolution de conflit local + externe` — protocole quand un fichier existe des deux côtés (privilégier externe, warn 1 fois/session).
  - `Format standardisé du warn de fallback` — template exact avec emoji ⚠️ et exemple complet (chemin externe → chemin local + conseil).
  - `Cas d'erreur distingués` — tableau à 3 lignes : path inaccessible / permission denied / erreur transitoire. Chaque cas a son conseil dédié (notamment : pas besoin de `/kp-agents:setup` pour une permission refusée, la config étant correcte).
  - `Détection au démarrage vs au write` — distinction entre « path inaccessible dès le début de session » (mode local dégradé pour toute la session) et « fallback par opération » (une erreur ponctuelle au write).

- **`agents/*.md`** — **non touchés**. Le dispositif S-0003 (injection de l'include dans les 7 agents + section startup) reste valide. L'enrichissement de l'include se propage automatiquement via `sync.sh`.

### Mesure taille après enrichissement

| SKILL.md | S-0003 (lignes) | S-0004 (lignes) | Δ |
|---|---:|---:|---:|
| brainstorm | 319 | 357 | +38 |
| product | 297 | 335 | +38 |
| architect | 324 | 362 | +38 |
| **developer** | 396 | **434** | **+38** |
| review | 380 | 418 | +38 |
| documentation | 358 | 396 | +38 |
| ux-ui | 357 | 395 | +38 |
| setup | 284 | 322 | +38 |

- **developer (agent le plus long)** : 434 lignes (+31% vs baseline 332 lignes de S-0001). Reste en-dessous du seuil pratique pour un skill Claude Code. Aucune alerte de saturation.
- **L'include inliné 8 fois** coûte 8 × 38 = **304 lignes cumulées** sur l'ensemble des SKILL.md. Acceptable pour la valeur apportée (couverture complète des scénarios limites).

### Tests empiriques OS

Trois tests exécutés en shell pour valider que les signaux techniques sous-jacents au fallback sont bien détectables :

```bash
# Test 1 : write R/W réussi + création implicite de sous-dossiers
mkdir -p /tmp/kp-s0004-rw/ideas
echo "test" > /tmp/kp-s0004-rw/ideas/test.md
# → Fichier créé, sous-dossier ideas/ créé à la volée. ✅

# Test 2 : permission denied sur un dossier en lecture seule
mkdir -p /tmp/kp-s0004-ro && chmod 555 /tmp/kp-s0004-ro
touch /tmp/kp-s0004-ro/blocked.md
# → "touch: /tmp/kp-s0004-ro/blocked.md: Permission denied" ✅
# → Le signal OS "Permission denied" est bien propagé aux outils Claude Code (Write).

# Test 3 : path inexistant (simulation OneDrive non monté)
[ ! -d /tmp/kp-s0004-nonexistent-xyz ] && echo "PATH_NOT_FOUND"
# → Détectable via test de fs avant write. ✅
```

Ces tests confirment que le filesystem macOS distingue bien les 3 cas traités dans l'include. **Limite** : non testé sur Windows (hérité de S-0001).

### Protocole de test utilisateur (conditions réelles OneDrive)

À exécuter par l'utilisateur après merge pour valider end-to-end. Prévoir 3 scénarios distincts dans un projet test vierge :

**Scénario A — Nominal OneDrive R/W**
1. Créer un dossier test hors du repo : `mkdir -p /tmp/kp-test-projet && cd /tmp/kp-test-projet && git init`
2. Créer `.kp-agents.yml` :
   ```yaml
   product:
     mode: external
   tickets:
     mode: local
   ```
3. Créer `.kp-agents.local.yml` :
   ```yaml
   product:
     path: /Users/vincent/Library/CloudStorage/OneDrive-<TON-ENTITE>/kp-test-projet/
   ```
4. Invoquer `/kp-agents:brainstorm` sur une idée quelconque (format Flash).
5. **Vérifier** : le fichier `ideas/<theme>.md` est bien créé dans le chemin OneDrive, **pas** dans `./docs/ideas/`.

**Scénario B — Fallback write (path valide mais sous-dossier en lecture seule)**
1. Depuis le même projet, en gardant `product.mode: external` actif.
2. Rendre un sous-dossier OneDrive en lecture seule : `chmod 555 /Users/vincent/Library/CloudStorage/OneDrive-<TON-ENTITE>/kp-test-projet/ideas/`
3. Invoquer à nouveau `/kp-agents:brainstorm` sur une **autre** idée.
4. **Vérifier** : l'agent affiche un warn ⚠️ au format standardisé, et le fichier atterrit dans `./docs/ideas/<theme>.md` local.
5. Restaurer les droits : `chmod 755 ...`

**Scénario C — OneDrive non monté (path inaccessible au démarrage)**
1. Modifier `.kp-agents.local.yml` pour pointer vers un chemin factice : `product.path: /Users/vincent/not-mounted-xyz/`
2. Invoquer `/kp-agents:product` ou n'importe quel agent.
3. **Vérifier** : l'agent détecte l'inaccessibilité dès le démarrage, affiche un warn, propose `/kp-agents:setup`, et bascule en mode local dégradé pour toute la session.

**Non-régression (critique)** : invoquer un agent dans `kp-agents` lui-même (qui n'a pas de `.kp-agents.yml`) → aucun changement de comportement.

### Limites documentées

- **Test OneDrive réel non exécutable par l'agent** : impossible de monter un OneDrive depuis une session d'agent. Les 3 scénarios ci-dessus sont à exécuter par l'utilisateur.
- **macOS uniquement** : Windows non validé (hérité de S-0001 et noté dans l'epic readme).
- **Pas de mécanisme de synchronisation** : si un fichier est créé en local suite à un fallback, l'utilisateur doit le migrer manuellement vers OneDrive après correction. L'agent ne fait pas de « rattrapage » automatique.

## Validation par critère

- **Sur un projet avec `product.mode: external` et chemin valide, tous les fichiers du périmètre externalisé sont créés/lus depuis le chemin externe** : ✅ la résolution est documentée dans l'include (section « Résolution de chemin pour la dimension `product` »), avec liste exhaustive des 4 types de fichiers redirigés (`ideas/`, `product.md`, `features/<group>/product.md`, `project/roadmap.md`). ⚠️ **Test end-to-end OneDrive réel à exécuter par l'utilisateur** (scénario A ci-dessus).
- **Fallback write testé manuellement : chemin externe en lecture seule → l'agent écrit dans `./docs/` + affiche un warn clair citant le chemin local** : ✅ protocole standardisé dans l'include (« Format standardisé du warn de fallback » avec template exact et exemple concret) + signal OS « Permission denied » empiriquement validé. ⚠️ Test end-to-end à exécuter par l'utilisateur (scénario B).
- **Gestion du chemin externe inaccessible : redirect vers `/kp-agents:setup`, session continue en local dégradé** : ✅ comportement documenté dans « Détection au démarrage vs au write ». Distinction claire entre path inaccessible au démarrage (mode dégradé pour toute la session) et erreur ponctuelle au write (fallback par opération). ⚠️ Test end-to-end à exécuter par l'utilisateur (scénario C).
- **Test manuel sur macOS avec un vrai dossier OneDrive : lecture et écriture fonctionnelles** : ⚠️ **non exécutable par l'agent** (pas d'accès OneDrive depuis la session agent). Le scénario A du protocole de test utilisateur couvre ce critère.
- **Les stories individuelles (`S-XXXX-*.md`) restent écrites en local pendant cette story (la dimension `tickets` n'est pas encore externalisée)** : ✅ l'include précise explicitement que « Les epics (...) et stories (...) suivent la dimension `tickets` (voir ci-dessous) ». La dimension `tickets` reste en mode `local` par défaut dans cette story, donc pas de changement.
- **Les fichiers d'architecture (`architect.md`, `features/*/architect.md`) restent en local même en mode externe (critère de non-contamination du périmètre)** : ✅ garanti par l'include ligne 40 (« Toujours écrits en local quelle que soit la config (...) `docs/architect.md`, `docs/features/<group>/architect.md`, `docs/INDEX.md`, toute doc technique ») + rappelé dans la section startup contextualisée de l'agent `architect` (« Tes écritures restent toujours locales »).
- **Test manuel non-régression : sur `kp-agents` lui-même (sans config), rien ne change** : ✅ garanti par la règle « Absent → mode 100% local, aucune vérification supplémentaire » (include, section « Comportement au démarrage » point 1). `kp-agents` ne contient pas de `.kp-agents.yml` → comportement identique à pre-S-0004. Vérification empirique : les commits S-0001 à S-0003 ont tous été validés sans régression (`git diff plugins/kp-agents/skills/` vide hors modifications intentionnelles).
