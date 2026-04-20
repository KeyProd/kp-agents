---
title: Externalisation des sources de documentation et tickets
date: 2026-04-21
status: qualified
brainstorm-format: flash
author: brainstorm-agent
---

# Externalisation des sources de documentation et tickets

**Problème**: Les agents `kp-agents` fonctionnent aujourd'hui en mode 100% local (tout dans `docs/` du projet courant). Certains contextes nécessitent des sources externalisées : doc produit centralisée sur OneDrive (partagée entre projets), suivi de tickets dans un système externe type JIRA via MCP. Les agents doivent pouvoir détecter / demander / mémoriser ces sources au démarrage, sans casser le mode local par défaut.

**Hypothèses critiques**:
- À valider : granularité (un seul switch vs. dimensions indépendantes doc produit / tickets)
- À valider : emplacement et format du fichier de configuration
- À valider : comportement quand la source externe est indisponible (OneDrive non monté, MCP JIRA down)

## Décisions acquises

- **Granularité** : dimensions indépendantes `product` et `tickets`, chacune avec son propre switch
- **Périmètre externalisable** :
  - `product` couvre : `docs/ideas/`, `docs/product.md`, `docs/features/*/product.md`, `docs/project/roadmap.md`
  - `tickets` couvre : `docs/project/epics/` (epics + stories)
  - **Toujours local** : `docs/architect.md`, `docs/features/*/architect.md`, doc technique
- **Approche retenue** : 🅰 Config split — `.kp-agents.yml` (commité, politique) + `.kp-agents.local.yml` (gitignoré, chemins machine)
- **Fallback** : dégradation gracieuse — si source externe indisponible, l'agent continue sans, l'utilisateur fournit les éléments manuellement

## Approches envisagées

### 🅰 Config split (retenue)
- `.kp-agents.yml` commité : politique (`product.mode`, `tickets.mode`, `mcp_server`, `project_key`)
- `.kp-agents.local.yml` gitignoré : chemins machine-spécifiques (`product.path`)
- Include `sources-config` injecté dans les 7 agents par `sync.sh`
- Chaque agent lit la config au démarrage, prompt utilisateur si mode externe mais chemin manquant
- Si source indisponible : warn + continue sans

### 🅱 Tout dans CLAUDE.md (rejetée)
- Risque de leak des chemins OneDrive dans git
- Fragile pour multi-machines / futur plugin marketplace

## Décisions complémentaires (phase 3-4)

- **Mapping JIRA** : traité dans la même epic (pas de découpe), avec un spike story en tête.
- **Écriture OneDrive dégradée** : en lecture, source externe privilégiée ; en écriture, **try external → fallback local avec warn** (utile quand l'utilisateur n'a qu'un accès en lecture à OneDrive).
- **Nouvel agent `setup`** : 8ᵉ agent dédié à la configuration projet et aux préférences utilisateur. Rôle : auditer l'état de config, prompter l'utilisateur, écrire `.kp-agents.yml` / `.kp-agents.local.yml` / `.gitignore`. Périmètre large (sources, préférences Git, et autres à venir).
- **Comportement au 1er appel** : si un agent détecte l'absence de config alors qu'une dimension externe est nécessaire, il **redirige vers `/kp-agents:setup`** via un handoff structuré (ne pas bloquer l'utilisateur — proposer la redirection, pas l'imposer).

## Recommandation

**Avancer en une seule epic** `E-XXXX-Sources-Externalisation`, décomposée en stories priorisées :

1. **S-0001 — Schéma de config** : définir `.kp-agents.yml` + `.kp-agents.local.yml`, include `sources-config` (lecture + résolution de chemin + fallback write local), entrée `.gitignore`.
2. **S-0002 — Agent `setup`** : création de l'agent (frontmatter, sync.sh, marketplace.json, CLAUDE.md, handoffs). Périmètre initial : sources. Préférences Git = story ultérieure.
3. **S-0003 — Intégration agents existants** : injection de l'include dans les 7 agents, section « Convention de sortie » rendue conditionnelle, auto-redirect vers setup si config manquante.
4. **S-0004 — Mode `product.mode: external`** (OneDrive) : lecture + écriture avec fallback local + tests multi-OS.
5. **S-0005 — Spike mapping JIRA** : prouver le round-trip story-markdown ↔ ticket JIRA via MCP (**hypothèse H1 à valider avant S-0006**).
6. **S-0006 — Mode `tickets.mode: mcp`** : implémentation du mapping validé en S-0005.
7. **S-0007 — Préférences Git dans setup** : branches, commits, PR (à cadrer avec product).
8. **S-0008 — Doc + release** : mise à jour README, CLAUDE.md, tag `kp-agents-v1.1.0` (minor bump car ajout d'agent).

**Point d'attention** : S-0005 (spike) est bloquant pour S-0006. Si le mapping JIRA s'avère plus lourd que prévu, on pourra **scinder** en E-A (product externe + setup) et E-B (tickets MCP) à ce moment-là — pas besoin de trancher maintenant.

## Décision / Next steps

**Recommandation prioritaire** : passer la main à `/kp-agents:product` pour cadrer l'epic et écrire les stories dans `docs/project/epics/E-XXXX-Sources-Externalisation/`.

**Type de next step** : cadrage produit (pas de prototype avant le spike JIRA de S-0005).

**Ordre de travail suggéré** : S-0001 → S-0002 → S-0003 → S-0004 (livrable partiel utilisable : `product` externe OK, `tickets` encore local) → S-0005 (spike) → S-0006 → S-0007 → S-0008.

## Handoff → /kp-agents:product

**Depuis** : brainstorm-agent
**Contexte** : créer une epic pour rendre les agents `kp-agents` configurables avec sources externes (doc produit sur OneDrive, tickets sur JIRA via MCP) + nouvel agent `setup` dédié à la config projet.

**Acquis** :
- Deux dimensions indépendantes : `product` (local | external) et `tickets` (local | mcp)
- Config split : `.kp-agents.yml` commité (politique) + `.kp-agents.local.yml` gitignoré (chemins machine)
- Périmètre `product` externe : `docs/ideas/`, `docs/product.md`, `docs/features/*/product.md`, `docs/project/roadmap.md`
- Périmètre `tickets` externe : `docs/project/epics/` (epics + stories via MCP)
- Architecture + doc technique **toujours locales**
- Fallback write : try external → fallback local + warn si permission denied
- Nouvel agent `setup` (8ᵉ agent)
- Injection via include `sources-config` dans les 7 agents existants + le nouveau

**Questions résolues** :
- Granularité (indépendante), emplacement config (split), périmètre (partiel), fallback (gracieux), 1er appel (redirect vers setup), inclusion mapping JIRA dans la même epic (oui, avec spike).

**À traiter** :
- Rédiger `readme.md` de l'epic (motivation, portée, critères d'acceptation globaux)
- Détailler les 8 stories proposées ci-dessus (critères d'acceptation Gherkin, définition de done)
- Définir le périmètre de S-0007 (quelles préférences Git exactement)
- Évaluer la nécessité d'un passage `/kp-agents:architect` pour trancher le mapping JIRA avant S-0005

**Fichiers de référence** :
- `docs/ideas/sources-externalisation.md` (ce fichier)
- `CLAUDE.md` (structure projet, règles sync.sh)
- `agents/*.md` (les 7 agents à modifier)
- `includes/` (où ajouter `sources-config.md`)
