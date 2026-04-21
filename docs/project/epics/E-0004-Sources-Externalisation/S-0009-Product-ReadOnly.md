---
title: Mode product.access read-only (doc produit externe figée)
date: 2026-04-21
status: REVIEW
author: product-agent
story-id: S-0009
epic-id: E-0004
---

# S-0009 - Mode `product.access: read-only` (doc produit externe figée)

## Résumé

Introduire une dimension supplémentaire `product.access` (valeurs `read-write` | `read-only`, défaut `read-write`, pertinente uniquement si `product.mode: external`). En `read-only`, les agents peuvent **lire** la doc produit externe mais **n'y écrivent jamais** — ni en externe, ni en fallback local. Les epics / stories restent pilotées par `tickets.mode` sans changement.

## User Story

En tant qu'utilisateur dont la doc produit vit sur un OneDrive partagé maintenu par un PM humain (ou un espace Notion exporté), je veux pouvoir brancher `kp-agents` dessus **en lecture seule**, afin de consommer la vision produit comme source de vérité figée sans risque de la corrompre depuis les agents.

## Contexte

- Story ajoutée après S-0004 sur retour utilisateur (2026-04-21).
- Le cas d'usage : OneDrive partagé entre PM humain et équipes dev. Le PM écrit, les agents lisent.
- Actuellement, `product.mode: external` implique lecture **et** écriture. Il n'existe aucun moyen de protéger la doc produit externe contre des writes d'agents.
- Solution descriptive (pas de code) : nouvelle dimension de config + règle de comportement dans `sources-config` + gotchas contextualisés dans `product` et `brainstorm`.

## Règles métier

- `product.access` n'est pertinent que si `product.mode: external`. En `mode: local`, le champ est ignoré (l'utilisateur a déjà le contrôle total local).
- Défaut : `read-write` (rétro-compatible avec S-0004).
- En `read-only`, les outputs de la dimension `product` (`product.md`, `ideas/*.md`, `features/<g>/product.md`, `roadmap.md`) sont **refusés en écriture**, externe comme local.
- Pas de fallback local en read-only — le contenu rédigé reste en chat, jamais écrit sur disque.
- Les outputs de la dimension `tickets` (epics / stories) suivent indépendamment `tickets.mode` — `product.access: read-only` ne les bloque pas.
- Les agents `architect`, `developer`, `review`, `documentation` ne sont pas affectés (pas d'écritures produit).
- L'agent `ux-ui` n'est **pas** concerné — ses outputs `ux.md` / `ui.md` relèvent du design, pas de la dimension produit au sens de cette story.

## Scénarios

### Nominal (read-only actif)
- Étant donné un projet avec `product.mode: external`, `product.access: read-only`, `product.path` valide
- Quand l'utilisateur invoque `/kp-agents:product` pour cadrer la vision
- Alors l'agent lit la doc produit externe, cadre la vision en chat, mais **n'écrit pas** `product.md`. Il propose le contenu rédigé dans un bloc markdown pour copy-paste manuel, et suggère `/kp-agents:setup` pour basculer en `read-write` si souhaité.

### Création de tickets en read-only
- Étant donné `product.mode: external`, `product.access: read-only`, `tickets.mode: local`
- Quand l'utilisateur invoque `/kp-agents:product` pour créer une epic
- Alors l'agent **crée l'epic localement** (`docs/project/epics/E-XXXX.../readme.md`) — l'epic relève de la dimension tickets, pas produit.

### Alternatif (brainstorm en read-only)
- Étant donné `product.mode: external`, `product.access: read-only`
- Quand l'utilisateur invoque `/kp-agents:brainstorm` sur un nouveau thème
- Alors l'agent déroule la conversation interactive normalement, mais **ne persiste pas** `ideas/<theme>.md`. Il propose le contenu final en chat pour copy-paste.

### Valeur par défaut
- Étant donné un projet avec `product.mode: external` sans champ `access`
- Quand un agent lit la config
- Alors `access: read-write` est appliqué (rétro-compatibilité S-0004).

### Mode local (neutre)
- Étant donné un projet avec `product.mode: local` et `product.access: read-only` (cas illogique)
- Quand un agent lit la config
- Alors le champ `access` est **ignoré** (mode local implique contrôle total).

## Cas limites

- [ ] Utilisateur tente de forcer un write en read-only (« écris quand même ») → l'agent refuse explicitement, redirige vers `/kp-agents:setup` pour bascule. Jamais de contournement silencieux.
- [ ] Config incohérente `mode: local` + `access: read-only` → warn au démarrage (« `access` ignoré en mode local »), pas de blocage.
- [ ] Bascule read-write → read-only via setup alors qu'une session d'écriture est en cours → aucune protection au runtime, l'utilisateur doit relancer les agents pour appliquer la nouvelle config (comportement standard pour tous les champs de config).

## Critères d'acceptation

- [ ] Schéma `.kp-agents.yml` documenté dans `includes/sources-config.md` inclut `product.access: read-write | read-only` avec défaut `read-write` et note « pertinent uniquement si `mode: external` ».
- [ ] Matrice comportementale présente dans l'include : par output produit, quel comportement en `local` / `external read-write` / `external read-only`.
- [ ] Format standardisé du warn read-only documenté dans l'include (réutilisable par tous les agents concernés).
- [ ] Agent `setup` pose la question `access` **uniquement** quand `product.mode: external` est retenu. Jamais en mode local.
- [ ] Agent `setup` écrit le champ `product.access` dans `.kp-agents.yml` si renseigné (et uniquement dans ce cas — pas de pollution en mode local).
- [ ] Agent `product` détecte `access: read-only` au démarrage et l'annonce dans son préambule de session.
- [ ] Agent `product` refuse explicitement d'écrire les 4 outputs produit en read-only, propose le contenu en chat pour copy-paste.
- [ ] Agent `brainstorm` détecte `access: read-only` et bascule sur un mode 100% conversationnel (pas de write de `ideas/*.md`).
- [ ] `architect`, `developer`, `review`, `documentation`, `ux-ui` **ne sont pas modifiés** (hors périmètre).
- [ ] Test manuel : projet avec `product.mode: external` + `product.access: read-only` → `/kp-agents:product` tente de créer une epic → epic créée (tickets), `product.md` non touché.
- [ ] Test manuel non-régression : projet sans `access` ou avec `access: read-write` → comportement identique à S-0004.
- [ ] `./sync.sh --dist-only` produit les 8 SKILL.md sans erreur, auto-bump patch déclenché.

## Dépendances

- **S-0001** (schéma config existant, étendu par cette story)
- **S-0002** (agent setup existant, étendu par cette story)
- **S-0003** (intégration dans les 7 agents, 2 agents modifiés ici)
- **S-0004** (mode external fonctionnel, cette story le raffine)

## Notes techniques

- Solution 100% descriptive (markdown dans l'include), cohérente avec S-0001/S-0003/S-0004. Aucun code exécutable ajouté.
- Le warn read-only doit avoir son propre format (🔒) distinct du warn de fallback (⚠️) pour que l'utilisateur distingue « refus volontaire » de « erreur technique ».
- Pas de variante « log to file » — si l'utilisateur veut persister, il bascule en read-write via setup.

## Instrumentation / mesure

- Taille `includes/sources-config.md` avant / après (attendu : +15 à +25 lignes).
- Taille source des 2 agents modifiés avant / après (attendu : +3 à +5 lignes chacun).
- Taille SKILL.md finale des 8 agents (doit rester < 450 lignes, developer reste l'agent le plus dense).

## Questions ouvertes

- Aucune à ce stade — le user a tranché les 3 points ouverts (ux-ui non concerné, story immédiate, pas de fallback local).

## Implémentation

### Nature

Solution 100% descriptive (markdown dans `includes/sources-config.md` + sections contextualisées dans 3 agents). Aucun code exécutable ajouté — conforme à la mécanique S-0001/S-0003/S-0004.

### Fichiers modifiés

| Fichier | Avant (lignes) | Après (lignes) | Δ |
|---|---:|---:|---:|
| `includes/sources-config.md` | 93 | 130 | +37 |
| `agents/setup.md` | 154 | 157 | +3 |
| `agents/product.md` | 167 | 171 | +4 |
| `agents/brainstorm.md` | 190 | 195 | +5 |

### Détail des modifications

1. **`includes/sources-config.md`** :
   - Schéma `.kp-agents.yml` étendu avec `product.access: read-write | read-only` (défaut `read-write`, ignoré en mode local).
   - Nouvelle section `### Mode product.access: read-only` avec matrice comportementale (6 outputs × 3 combinaisons de config).
   - Format 🔒 standardisé du refus read-only (distinct du warn ⚠️ de fallback technique), avec bloc markdown de rendu en chat.
   - Règles spécifiques : refus absolu, pas de fallback, découplage avec `tickets.mode`.

2. **`agents/setup.md`** :
   - Étape 3 « Questions ciblées » — ajout d'une question conditionnelle sur `access` **uniquement** si `product.mode: external` est retenu (formulation longue qui explique le cas d'usage PM humain).
   - Nouveau cas limite : `access` omis → ne pas écrire le champ. `access` en mode local → warn et proposer de retirer.

3. **`agents/product.md`** :
   - Nouvelle sous-section `### Mode product.access: read-only` après la section `Configuration du projet` — annonce dans préambule de session, refus d'écriture sur les 4 outputs produit, rendu en chat au format 🔒.
   - Nouveau gotcha : « pas de write, même en fallback local ».

4. **`agents/brainstorm.md`** :
   - Nouvelle sous-section `### Mode product.access: read-only` — bascule 100% conversationnel, `ideas/<theme>.md` jamais persisté.
   - Nouveau gotcha : format 🔒 pour rendu du fichier idée en chat.

### Mesures SKILL.md générés

| Agent | SKILL.md avant S-0009 (S-0004) | SKILL.md après S-0009 | Δ |
|---|---:|---:|---:|
| brainstorm | ~357 | **399** | +42 |
| product | ~335 | **377** | +42 |
| setup | ~328 | **363** | +35 |
| architect | 362 | **399** | +37 |
| developer | 434 | **471** | +37 |
| documentation | ~396 | **433** | +37 |
| review | ~418 | **455** | +37 |
| ux-ui | ~395 | **432** | +37 |

**developer** (plus gros agent) : 471 lignes SKILL.md — reste sous la barre des 500, OK.

### Vérifications techniques

- `grep '{{include' plugins/kp-agents/skills/*/SKILL.md` → **0 résidu** sur les 8 agents.
- `grep -l 'product.access: read-only' plugins/kp-agents/skills/*/SKILL.md` → **8 matches** (include inliné dans tous les agents, cohérent).
- `./sync.sh --dist-only` : 8 agents syncés sans erreur, auto-bump patch `1.0.4 → 1.0.5`.

### Limites

- **Pas de test end-to-end** : ajouter `.kp-agents.yml` avec `product.access: read-only` dans un projet test, invoquer `/kp-agents:product` → vérifier que l'agent refuse d'écrire `product.md` mais crée l'epic. À exécuter par l'utilisateur avec S-0004.
- **Comportement dépendant de l'agent** : le refus d'écriture repose sur la lecture de la config par l'agent au démarrage et sur son respect de la règle documentée. Pas de garde-fou technique externe (cohérent avec la stratégie descriptive de l'epic).

## Validation par critère

- **Schéma `.kp-agents.yml` documenté avec `product.access`** : ✅ dans `includes/sources-config.md`, commentaire « défaut: read-write, ignoré si mode: local ».
- **Matrice comportementale présente** : ✅ 6 lignes × 3 colonnes (local / external read-write / external read-only) dans la section read-only de l'include.
- **Format standardisé du warn read-only** : ✅ format 🔒 documenté, distinct du ⚠️ de fallback technique, avec bloc markdown de rendu.
- **Setup pose la question `access` uniquement si `mode: external`** : ✅ bullet conditionnel dans étape 3 de `agents/setup.md`, avec formulation longue et cas d'usage.
- **Setup écrit `access` uniquement si pertinent** : ✅ documenté dans les cas limites (omis → ne pas écrire ; en mode local → warn et proposer de retirer).
- **Agent `product` détecte read-only et l'annonce dans préambule** : ✅ directive dans la section `### Mode product.access: read-only` de `agents/product.md`.
- **Agent `product` refuse les 4 outputs produit en read-only** : ✅ listés explicitement (`product.md`, `ideas/*.md`, `features/<g>/product.md`, `project/roadmap.md`).
- **Agent `brainstorm` détecte read-only et bascule conversationnel** : ✅ directive dans la section dédiée de `agents/brainstorm.md`.
- **Agents non concernés non modifiés** : ✅ `git diff` sur `agents/architect.md`, `agents/developer.md`, `agents/review.md`, `agents/documentation.md`, `agents/ux-ui.md` → aucune modif source. Les SKILL.md ont changé car l'include a été enrichi, mais le comportement décrit ne s'applique qu'à product/brainstorm.
- **Test manuel read-only + création d'epic** : ⚠️ **à exécuter par l'utilisateur** — protocole : créer `.kp-agents.yml` avec `product.mode: external` + `product.access: read-only` + `tickets.mode: local`, invoquer `/kp-agents:product` → demander « crée l'epic Auth » → vérifier que l'epic est créée mais que le cadrage produit reste en chat.
- **Test manuel non-régression** : ⚠️ **à exécuter par l'utilisateur** — projet sans `access` ou avec `access: read-write` → comportement identique à S-0004.
- **Sync sans erreur + auto-bump** : ✅ bump `1.0.4 → 1.0.5`, 8 agents syncés dans 3 cibles.
