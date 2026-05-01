---
title: Adapter kp-agents au partage d'agents OpenAI par équipe
date: 2026-04-23
status: draft
brainstorm-format: essentiel
author: brainstorm-agent
---

# Adapter kp-agents au partage d'agents OpenAI par équipe

## Problème

`kp-agents` sait déjà compiler une source unique `agents/*.md` vers trois sorties distinctes :

- un plugin marketplace pour Claude Code dans `plugins/kp-agents/`
- des règles Cursor dans `dist/cursor/`
- des skills Codex dans `dist/codex/`

Le besoin exploré ici est de savoir s'il est possible d'adapter ce compilateur pour produire aussi un artefact compatible avec la nouvelle solution OpenAI de partage d'agents par équipe, annoncée le 2026-04-22 autour de **ChatGPT workspace agents** et des **skills partagées**.

## Reformulation du besoin

- **Problème utilisateur** : éviter de maintenir un pipeline spécifique à chaque outil si OpenAI propose désormais un mécanisme natif de partage d'agents ou de skills entre membres d'une équipe.
- **Solution imaginée** : faire évoluer `sync.sh` pour générer un format importable dans Codex / ChatGPT, voire un "plugin" OpenAI partageable.
- **Hypothèse à tester** : le format déjà produit pour Codex (`SKILL.md` + `agents/openai.yaml`) est assez proche du standard OpenAI actuel pour servir de base à une distribution d'équipe.

## Observations établies

### Côté projet

- `sync.sh` est déjà structuré comme un **générateur multi-cibles**.
- La cible Codex génère un dossier par skill avec :
  - `SKILL.md`
  - `agents/openai.yaml`
- Les directives `{{include:...}}` et `{{ref:...}}` sont résolues à la compilation, ce qui est favorable à une exportabilité vers d'autres surfaces.
- Le projet dissocie déjà :
  - le **contenu métier** des agents (`agents/*.md`)
  - les **adaptateurs de distribution** (`generate_plugin`, `generate_cursor`, `generate_codex`)

### Côté OpenAI / ChatGPT / Codex

- Le 2026-04-22, OpenAI a annoncé **Workspace Agents in ChatGPT**, "powered by Codex", partageables à l'échelle d'un workspace, utilisables dans ChatGPT et Slack.
- La doc officielle indique qu'un workspace agent peut intégrer :
  - des outils / apps
  - des custom MCPs
  - des files
  - des **skills**
- La doc officielle indique aussi que les **skills** sont :
  - partageables dans un workspace
  - uploadables depuis un fichier
  - supportées dans **ChatGPT**, **Codex** et **API**
  - basées sur l'**Agent Skills open standard**
- La doc officielle précise toutefois que les skills **"don't sync across products yet"** : elles sont portables, mais pas synchronisées automatiquement entre surfaces.

## Première lecture de faisabilité

### Ce qui semble faisable

- **Oui** pour adapter `kp-agents` afin de produire des **skills OpenAI partageables** dans un workspace.
- **Oui** pour viser une compatibilité plus forte entre la cible `dist/codex/` actuelle et un paquet importable côté ChatGPT Skills.
- **Oui** pour produire un **artefact de seed** pour workspace agents (instructions, skills, métadonnées, mapping outils/app connections) afin de réduire le travail manuel dans le builder.

### Ce qui reste incertain

- À ce stade, je n'ai trouvé **aucun format de "plugin OpenAI" ou manifeste git-installable** équivalent au marketplace Claude.
- Je n'ai pas trouvé non plus de doc officielle exposant un **import/export complet de workspace agent** ni une **API de publication** pour créer/pousser un agent partagé depuis `sync.sh`.
- En l'état, la création des workspace agents semble documentée **via l'UI ChatGPT Agent Builder**, avec partage dans le workspace ensuite.

## Hypothèses critiques

- **H1** : le dossier `dist/codex/kp-*/` est déjà très proche du format accepté par ChatGPT Skills.
- **H2** : il faudra distinguer deux cibles OpenAI :
  - une cible **skill portable** (probablement automatisable)
  - une cible **workspace agent** (probablement semi-automatisable seulement)
- **H3** : la notion de "plugin" dans ton besoin correspond en réalité soit à :
  - une **skill partageable** dans ChatGPT/Codex
  - un **workspace agent** construit à partir de skills et de connexions
  - mais pas à un plugin git-installable comparable à Claude Code

## Questions ouvertes pour la suite

1. Quand tu dis "plugin Codex / GPT compatible", tu vises surtout :
   - un **fichier/pack de skills** importable et partageable dans ChatGPT/Codex
   - ou un **workspace agent complet** prêt à publier dans le répertoire d'équipe ChatGPT ?
2. Tu veux préserver la logique actuelle "source unique -> plusieurs cibles", même si la cible OpenAI agents reste partiellement manuelle au début ?
3. Le besoin principal est plutôt :
   - **standardiser les workflows** via des skills partagées
   - ou **orchestrer des agents complets** avec apps, MCP, Slack, scheduling et approvals ?
4. Est-ce que ton équipe cible dispose déjà d'un workspace **ChatGPT Business / Enterprise / Edu** avec :
   - skills activées
   - workspace agents activés
   - les droits de publication ?

## Sources

- Projet local :
  - `sync.sh`
  - `README.md`
  - `docs/architect.md`
- OpenAI :
  - https://openai.com/index/introducing-workspace-agents-in-chatgpt/
  - https://help.openai.com/en/articles/20001143-chatgpt-workspace-agents-for-enterprise-and-business
  - https://help.openai.com/articles/20001066-skills-in-chatgpt
  - https://academy.openai.com/public/resources/skills
