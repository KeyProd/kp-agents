---
title: Réécriture des descriptions en phrasing impératif
date: 2026-04-18
status: DONE
author: product-agent
story-id: S-0002
epic-id: E-0003
---

# S-0002 - Réécriture des descriptions en phrasing impératif

## Résumé

Réécrire le champ `description` du frontmatter des 7 agents en suivant les best practices d'agentskills.io : phrasing impératif, triggers explicites, near-miss exclusions, < 1024 caractères.

## User Story

En tant qu'utilisateur de Claude Code avec le plugin kp-agents installé, je veux que les agents se déclenchent automatiquement quand le contexte s'y prête — même si je n'emploie pas le vocabulaire exact de l'agent — afin de ne pas avoir à invoquer explicitement `/kp-agents:<nom>` à chaque fois.

## Contexte

- Recommandation couverte : **B1** dans `docs/agents-review.md` (annexe, section A).
- Priorité : **P1**.
- Source des descriptions proposées : tableau dans `docs/agents-review.md#a-optimisation-du-champ-description-trigger-reliability`.
- Les descriptions proposées sont en **anglais** pour maximiser le trigger matching multi-langues (pratique recommandée par agentskills.io). **Décision actée le 2026-04-18** : les descriptions (frontmatter) sont en anglais, mais les agents doivent converser **exclusivement dans la langue de l'utilisateur** — cette règle est portée par l'include `activation.md` créé en S-0001.

## Règles métier

- Chaque description doit respecter : < 1024 caractères, phrasing impératif ("Use this skill when…"), au moins un déclencheur implicite ("even if they don't say…"), au moins un near-miss exclu ("Skip if…" ou "Do NOT use…").
- Le `name`, `short_description`, `default_prompt` restent inchangés.
- La description doit mentionner les artefacts projet concrets (`docs/ideas/`, `docs/project/epics/`, ADR, story, INDEX.md…) pour ancrer la décision d'activation.

## Scénarios

### Nominal

- **Étant donné** les 7 `description` actuelles sont descriptives ("KeyProd X: do Y and Z")
- **Quand** je remplace chaque description par la version proposée dans le tableau de review et lance `./sync.sh`
- **Alors** les 7 frontmatter `plugins/kp-agents/skills/*/SKILL.md` contiennent la nouvelle description, chacune < 1024 caractères, toutes impératives.

### Alternatif

- **Étant donné** une description proposée dépasse 1024 caractères après affinement
- **Quand** je la raccourcis
- **Alors** je conserve a minima le phrasing impératif + 1 trigger explicite + 1 near-miss, même si j'élague les exemples.

### Erreur / refus

- **Étant donné** une description ne respecte pas le patron (oubli du "Use this skill when…")
- **Quand** la story est reviewée
- **Alors** elle est marquée NO-GO et retournée pour ajustement.

## Cas limites

- [ ] Caractères spéciaux (apostrophes, backticks) dans la description : vérifier le parsing YAML correct après compilation.
- [ ] Description multi-lignes : utiliser le format YAML `>` ou `|` si nécessaire, vérifier que le rendu Cursor/Codex reste correct.
- [ ] Vérifier que `.claude-plugin/marketplace.json` (catalogue statique) n'a pas d'entrée `description` qui dupliquerait celle du frontmatter agent — sinon harmoniser ou documenter la divergence.

## Critères d'acceptation

- [ ] Les 7 champs `description` des frontmatter `agents/*.md` commencent par "Use this skill when..." (ou formulation impérative équivalente).
- [ ] Chaque description contient au moins un trigger implicite ("even if they don't explicitly...").
- [ ] Chaque description contient au moins une clause near-miss (au choix : "Skip if...", "Do NOT use...", "Use ... instead for...").
- [ ] Aucune description ne dépasse 1024 caractères (vérifier avec un `wc -c` ou équivalent).
- [ ] `./sync.sh` passe sans erreur ; les descriptions sont propagées aux 3 cibles.
- [ ] Les 7 SKILL.md générés parse correctement (YAML valide) — à vérifier via `head -n 10 plugins/kp-agents/skills/*/SKILL.md`.
- [ ] `short_description`, `default_prompt`, `name` restent inchangés dans les 7 frontmatter.

## Dépendances

- Peut être réalisée en parallèle de S-0001 (zones de fichier distinctes : frontmatter vs corps).
- Recommandation : faire S-0001 d'abord pour minimiser les conflits de merge si les stories sont traitées par deux branches.

## Notes techniques

- Langue : descriptions en **anglais** (décision 2026-04-18). La consigne de réponse dans la langue de l'utilisateur est portée côté corps via l'include `activation.md` (cf. S-0001) — ne pas dupliquer ici.
- Fichiers impactés : les 7 `agents/*.md` (uniquement frontmatter, ligne `description:`), régénération plugin + dist.
- Attention au format YAML : si la description est longue, utiliser `description: >` suivi d'une indentation pour les multi-lignes.

## Instrumentation / mesure

- Aucune mesure empirique possible dans cette story (voir S-0007 pour la structure d'évaluation).
- Check simple post-story : lancer `/kp-agents:product` depuis un prompt comme "j'aimerais structurer mes idées en epics" (sans mentionner "product") et vérifier que le skill est proposé/activé — validation manuelle.

## Questions ouvertes

- ~~Préfixe "KeyProd"~~ **Résolu 2026-04-18** : supprimé des 7 `description` (le patron impératif prime). `short_description` conserve "KeyProd" pour l'identité marketplace.
- ~~Variante francophone à prévoir ?~~ **Résolu 2026-04-18** : descriptions en anglais, conversation en langue utilisateur (via include `activation.md`).

## Implémentation

- Fichiers modifiés (frontmatter `description` uniquement) : les 7 `agents/*.md`.
- Source des nouvelles descriptions : tableau `docs/agents-review.md#a-optimisation-du-champ-description-trigger-reliability`.
- Régénérés via `./sync.sh --dist-only` : plugin + cursor + codex.
- Vérifications :
  - Toutes les descriptions commencent par "Use this skill when/whenever".
  - Longueurs comprises entre 480 et 530 caractères (< 1024).
  - Toutes contiennent une clause near-miss ("Do NOT use…", "Skip if…", "NEVER").
  - YAML parse correctement (test via `head -7 plugins/kp-agents/skills/*/SKILL.md`).
  - `name`, `short_description`, `default_prompt` inchangés.

## Validation par critère

- **Toutes commencent par "Use this skill when…"** : ✅ 6 sur 7 avec "Use this skill when", 1 ("documentation") avec "Use this skill whenever" — formulation impérative équivalente.
- **Au moins un trigger implicite** : ✅ chaque description contient "even if they don't…" ou "Triggers on: '…'" listant des formulations utilisateur non-verbatim.
- **Au moins une clause near-miss** : ✅ "Do NOT use…" (brainstorm, developer), "Skip if…" (product, architect, review, documentation), "NEVER modifies source code" (review), "Anti-generic — never defaults to…" (ux-ui).
- **< 1024 caractères** : ✅ max 530 (architect).
- **`./sync.sh` passe** : ✅ 7 agents syncés.
- **YAML valide** : ✅ parsing OK sur tous les SKILL.md (aucun caractère `"` dans les descriptions, seulement des `'` compatibles YAML double-quoted).
- **`short_description`, `default_prompt`, `name` inchangés** : ✅ seule la ligne `description:` a été modifiée.
