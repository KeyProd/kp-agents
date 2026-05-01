---
title: Mémoire projet
date: 2026-05-01
status: active
author: documentation-agent
---

# Mémoire projet

> Décisions et contexte persistants entre sessions — maintenu par l'agent `documentation`.
> Complément léger aux ADR formelles (`docs/architect.md`) pour les décisions informelles et les contextes établis en cours de travail.
> Mettre à jour après toute décision significative non déjà capturée dans une ADR ou une story.

---

## Décisions techniques

| Date | Décision | Contexte |
|------|----------|----------|
| 2026-04-18 | `python3` retenu pour manipuler `plugin.json` (vs `jq`) | `jq` = dépendance externe. `python3` standard macOS/Linux. Voir ADR dans `docs/architect.md`. |
| 2026-04-20 | Scaffolding `agents/_evals/` retiré | Aucun runner disponible — non directement utilisable. Cf. `docs/agents-review.md`. |
| 2026-05-01 | `short_description` utilisé comme `description` dans SKILL.md | Fix autocomplete : `description` = texte court discriminant, texte long trigger en commentaire HTML. |

## Conventions établies en cours de projet

| Convention | Détail |
|------------|--------|
| Bump version plugin | Auto-patch via SHA256 à chaque `sync.sh`. `--minor` pour ajout d'agent. `--major` pour retrait/renommage. |
| Nommage branches | Non fixé globalement — à définir par projet via `.kp-agents.yml#git.branch_pattern` |
| Relais inter-agents | Toujours via bloc handoff structuré (`includes/handoff.md`) — jamais de contexte verbal uniquement |
| Stories repartent à S-0001 | Numérotation locale à chaque epic (pas globale) |

## Points à surveiller

| Point | Statut |
|-------|--------|
| Merge concurrent sur `plugin.json` | Peut produire incohérence `version` ↔ `_contentHash` → arbitrage manuel |
| `dist/` non commité | Généré par `sync.sh --dist-only`, gitignoré. Ne jamais commiter. |
| `plugins/kp-agents/skills/` | Généré par `sync.sh`. Commiter après chaque sync. Ne jamais écrire manuellement. |

---

*Format d'entrée : `| YYYY-MM-DD | Décision courte | Contexte / raison |`*
*Ajouter uniquement ce qui n'est pas déductible des fichiers existants.*
