---
title: Mode product.mode external (OneDrive)
date: 2026-04-21
status: TODO
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

- Fichiers modifiés : logique dans `includes/sources-config.md` affinée ; tous les agents du périmètre product utilisent les chemins résolus
- Commandes de test : projet test avec chemin OneDrive réel + projet test avec chemin factice (`/tmp/fake-onedrive`) en mode lecture seule (`chmod -w`)
- Notes de review : à remplir

## Validation par critère

_À remplir lors de l'implémentation et de la review_
