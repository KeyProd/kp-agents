---
title: Refonte de l'agent developer
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0005
epic-id: E-0003
---

# S-0005 - Refonte de l'agent developer

## Résumé

Refactoriser `agents/developer.md` : fusionner les étapes 6 (Bilan) et 7 (Mise à jour doc) qui se recouvrent, rendre l'étape 5 (Simplification) portable multi-cibles, et ajouter un exemple de section "Validation par critère" bien remplie vs. mal remplie.

## User Story

En tant que developer-agent, je veux un processus plus concis où le bilan post-implémentation intègre déjà le relais documentaire sans doublon, et où ma consigne de simplification fonctionne indépendamment de la plateforme d'exécution (Claude Code, Cursor, Codex).

## Contexte

- Recommandations couvertes : **O4.1** (fusion 6/7, **P1**), **O4.2** (portabilité simplify, **P2**), **B5** (exemple Validation, **P3**).
- L'étape 6 actuelle recommande déjà `/kp-documentation` puis l'étape 7 re-énumère les mêmes actions → ~15 lignes de redondance.
- L'étape 5 appelle `/simplify` (commande Claude Code) sans équivalent Cursor/Codex.

## Règles métier

- Aucun pivot fonctionnel : developer continue d'implémenter story/epic, valider, faire un bilan, recommander suite.
- La fusion doit conserver les informations utiles des deux étapes (liste des écarts détectés, mise à jour des statuts, suggestion `/kp-documentation`).
- La simplification multi-cibles doit : proposer la commande native si elle existe, sinon une passe manuelle définie.

## Scénarios

### Nominal

- **Étant donné** `agents/developer.md` contient une étape 6 "Bilan" et une étape 7 "Mise à jour de la documentation" partiellement redondantes
- **Quand** je fusionne les deux en une étape unique "6. Bilan et relais documentaire"
- **Alors** le SKILL.md compilé ne perd aucune consigne utile mais gagne en lisibilité (~15 lignes en moins).

### Alternatif

- **Étant donné** l'utilisateur travaille sur Cursor et déclenche la phase "Simplification"
- **Quand** l'agent lit la consigne reformulée
- **Alors** l'agent comprend qu'il doit : (a) tenter la commande native équivalente si elle existe, (b) sinon faire une passe manuelle sur le code modifié avec les critères définis (lisibilité, duplication, complexité).

### Erreur / refus

- **Étant donné** la fusion a oublié une consigne présente dans l'étape 7 (ex: "mettre à jour le feature architect.md si déviation")
- **Quand** l'agent exécute le nouveau flux
- **Alors** un écart de comportement est détecté en review → NO-GO, correction et recommit.

## Cas limites

- [ ] Un utilisateur a une préférence mémorisée "toujours lancer /simplify" : la reformulation multi-cibles doit continuer à honorer cette préférence (ne pas casser la mémoire).
- [ ] Exemple "Validation par critère" mal rempli : doit être suffisamment proche d'erreurs réelles observées pour être pédagogique, sans être caricatural.

## Critères d'acceptation

- [ ] Les étapes 6 et 7 de `agents/developer.md` sont fusionnées en une seule étape "6. Bilan et relais documentaire" (ou titre équivalent).
- [ ] L'étape fusionnée contient : les 3 options de recommandation (Review / Test poussé / Continuer), la mise à jour du statut, la suggestion `/kp-documentation` avec liste d'écarts, la note sur la mise à jour `docs/features/<group>/architect.md` si déviation.
- [ ] L'étape "Simplification" est reformulée pour fonctionner sans supposer `/simplify` : consigne "lance l'outil de simplification disponible sur la plateforme courante, sinon fais une passe manuelle sur [critères]".
- [ ] Une section `### Exemple de section "Validation par critère"` est ajoutée avec un exemple **bien rempli** (critère ↔ implémentation ↔ preuve ↔ limites) et un exemple **trop vague** à éviter.
- [ ] Ligne finale de developer : `wc -l` inférieur d'au moins 10 lignes à la version actuelle.
- [ ] `./sync.sh` passe ; SKILL.md compilé vérifié.

## Dépendances

- Recommandé après S-0001 (le bloc Activation sera déjà factorisé).
- Indépendant de S-0002 (frontmatter) et S-0003 (gotchas).

## Notes techniques

- Fichiers impactés : `agents/developer.md` uniquement (+ artefacts régénérés).
- Ordre des sous-points dans l'étape fusionnée : 1) checklist testable, 2) recommandation (Review/Test/Continuer), 3) mise à jour statut, 4) écarts documentaires + relais `/kp-documentation`, 5) cas spécial feature architect si déviation.
- Pour la simplification, conserver le système de mémoire utilisateur (lancer auto / proposer / skip).

## Instrumentation / mesure

- Avant/après : diff de longueur de `agents/developer.md`.
- Validation qualitative : exécuter `/kp-agents:developer` sur une story fictive et vérifier que le bilan produit couvre toujours les éléments attendus.

## Questions ouvertes

- La règle "Pas de worktree" sera déplacée en `## Gotchas` par S-0003 — vérifier la coordination pour éviter le doublon. Proposition : S-0003 passe en premier, S-0005 nettoie le résidu si nécessaire.
- Faut-il aussi fusionner les étapes 3 (Implémentation) et 4 (Validation) qui se suivent logiquement ? Décision : **non**, elles ont des outputs distincts (code vs section `## Validation par critère`) — à conserver séparément.

## Implémentation

- Fichier modifié : `agents/developer.md` uniquement.
- Étape 5 (Simplification) : `/simplify` présenté comme l'outil natif Claude Code, avec fallback « équivalent Cursor ou Codex » et passe manuelle sur 5 critères (lisibilité, duplication, complexité cyclomatique, noms explicites, early return vs nested). La mémoire utilisateur est conservée (auto / proposer / skip).
- Étapes 6 + 7 fusionnées en `### 6. Bilan et relais documentaire` avec 7 sous-points numérotés : testable, recommandation, mise à jour statut, écarts documentaires, relais `/kp-agents:documentation`, cas spécial `features/<group>/architect.md`, mise à jour de l'epic.
- Section pédagogique ajoutée : `#### Exemple de section \`## Validation par critère\`` avec un ✅ bon exemple (expiration token + ref `token.test.ts:15-28`) et un ❌ contre-exemple trop vague.
- Résidu nettoyé : règle « Pas de worktree » supprimée de `## Règles` (déjà présente dans `## Gotchas` via S-0003), évite le doublon.
- Régénéré via `./sync.sh --dist-only` ; aucun `{{include:` résiduel dans `plugins/kp-agents/skills/developer/SKILL.md`.

## Validation par critère

- **Fusion étapes 6 + 7** : ✅ `agents/developer.md:132` expose `### 6. Bilan et relais documentaire`, plus d'étape 7 séparée.
- **Contenu fusionné complet (3 options, statut, relais doc, feature architect)** : ✅ les 7 sous-points numérotés couvrent les 3 options Review/Test/Continuer (point 2), la mise à jour du statut (point 3), la suggestion `/kp-agents:documentation` avec liste d'écarts (points 4-5), et le cas `docs/features/<group>/architect.md` (point 6).
- **Simplification portable multi-cibles** : ✅ mention explicite « `/simplify` sur Claude Code ; équivalent Cursor ou Codex ; à défaut, passe manuelle » avec critères objectifs.
- **Exemple Validation par critère (bon + mauvais)** : ✅ section `#### Exemple de section` avec bloc ✅ bien rempli (3 critères traçables) et ❌ trop vague (3 lignes caricaturales mais pédagogiques), plus une note finale expliquant la différence.
- **Réduction ≥ 10 lignes** : ✅ 371 → 198 lignes (-173 lignes), dépasse largement le seuil. La réduction provient principalement du fait que les includes factorisaient déjà activation/gotchas et que la fusion 6+7 a éliminé la redondance structurelle.
- **`./sync.sh` OK + SKILL.md compilé vérifié** : ✅ sync ré-exécuté, 0 `{{include:` résiduel dans le SKILL.md compilé.
- **Mémoire utilisateur `/simplify` préservée** (cas limite) : ✅ le bloc « Comportement adaptatif (basé sur la mémoire) » conserve les 3 branches (auto / skip / proposer).
