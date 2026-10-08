# Plugin jpb-platform

Skills pour amener une application sur **JPB-Platform**, la plateforme d'hébergement des
applications internes de JPB.

| Skill (Claude Code) | Skill (Codex) | Quand |
|---|---|---|
| `/jpb-platform:app-kickstart` | `$jpb-platform:app-kickstart` | **Nouvelle app** : à lancer dès la première session. Vérifie le poste et les accès, crée tout de suite le dépôt `KeyProd/<app>` avec ses règles et ses garde-fous (hooks git et Claude Code, travail par branches `feat/` et `fix/`), prépare le caller CI dans une PR en brouillon, propose un brainstorm, rédige la demande de raccordement, fait le point de conformité au fil des décisions. Ré-invocable. |
| `/jpb-platform:app-conformite-audit` | `$jpb-platform:app-conformite-audit` | **État des lieux** d'une app, en lecture seule, sur tous les points de contrôle du référentiel. Joué par le créateur, rejoué par l'équipe DevOps (contre-audit) avant la PROD. |
| `/jpb-platform:app-conformite-transformation` | `$jpb-platform:app-conformite-transformation` | **App existante** : mise en conformité écart par écart, à partir de l'audit. |

## Trois modes de communication

Au premier appel, les skills demandent comment parler à l'utilisateur : **débutant** (« je
découvre » — mots simples, choix techniques faits pour lui selon les préconisations de la
plateforme), **connaisseur** (« j'ai des notions ») ou **développeur** (communication
habituelle, il fait ses choix). Le mode est gardé dans son `CLAUDE.local.md`, fichier personnel
non versionné, et vaut pour toutes les sessions sur le dépôt de l'app. Règle et préconisations :
`docs/features/plateforme-vxrail/standards/modes-communication.md` du dépôt jpb-platform.

## Un plugin « mince »

Ce dépôt est public : les skills ne portent que la **démarche**. Les **règles** — référentiel
de conformité, procédure de mise en service, standards, chart, implémentation de référence —
vivent dans le dépôt privé `KeyProd/jpb-platform`, que les skills relisent à chaque appel par
[`scripts/jpb-platform-ref.sh`](scripts/jpb-platform-ref.sh) :

1. `$JPB_PLATFORM_DIR` s'il est défini (clone de travail, équipe DevOps) ;
2. sinon une copie peu profonde en cache, `~/.cache/jpb-platform`, rafraîchie à chaque appel.

Conséquence : une règle qui change se modifie dans jpb-platform, **sans republier ce plugin**.

## Prérequis

- Un compte GitHub membre de l'organisation **KeyProd** (à demander à l'équipe DevOps).
- L'outil GitHub en ligne de commande `gh`, connecté : `gh auth login`.

## Installation

Claude Code, en terminal :

```
/plugin marketplace add KeyProd/kp-agents
/plugin install jpb-platform@kp-agents
```

Application de bureau Claude (onglet Code) : bouton **+** à côté de la zone de saisie →
**Plugins** → **Ajouter un plugin**, marketplace `KeyProd/kp-agents`, plugin `jpb-platform`.
Les deux partagent la même installation.

Codex, en terminal — la même marketplace git, avec son catalogue natif
`.agents/plugins/marketplace.json` à la racine du dépôt :

```bash
codex plugin marketplace add KeyProd/kp-agents
codex plugin add jpb-platform@kp-agents
```

Redémarrer Codex. Mise à jour : `codex plugin marketplace upgrade kp-agents`. Le plugin porte
deux manifestes à la même version : `.claude-plugin/plugin.json` (Claude Code, skills de
`skills/`) et `.codex-plugin/plugin.json` (Codex, variantes de `codex/`).

## Documentation côté plateforme (dépôt jpb-platform)

- Guide de démarrage d'une application : `docs/onboarding/index.html`
- Référentiel de conformité : `docs/features/plateforme-vxrail/standards/conformite-app.md`
- Procédure : `docs/features/plateforme-vxrail/runbooks/mise-en-conformite-app.md`
- Règles inscrites dans une nouvelle app : `docs/features/plateforme-vxrail/standards/section-claude-app.md`
- Garde-fous et caller CI d'une app : `docs/features/plateforme-vxrail/standards/gabarit-app/`
