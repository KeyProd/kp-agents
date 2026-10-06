# Plugin jpb-platform

Skills pour amener une application sur **JPB-Platform**, la plateforme d'hébergement des
applications internes de JPB.

| Skill (Claude Code) | Skill (Codex) | Quand |
|---|---|---|
| `/jpb-platform:app-kickstart` | `$jpb-app-kickstart` | **Nouvelle app** : à lancer dès la première session. Pose les règles, propose un brainstorm, crée le dépôt `KeyProd/<app>`, rédige la demande de raccordement, fait le point de conformité au fil des décisions. Ré-invocable. |
| `/jpb-platform:app-conformite-audit` | `$jpb-app-conformite-audit` | **État des lieux** d'une app, en lecture seule : 13 points de contrôle. Joué par le créateur, rejoué par l'équipe DevOps (contre-audit) avant la PROD. |
| `/jpb-platform:app-conformite-transformation` | `$jpb-app-conformite-transformation` | **App existante** : mise en conformité écart par écart, à partir de l'audit. |

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

Codex : `./sync.sh` depuis un clone de kp-agents copie `jpb-platform/codex/jpb-*` dans
`~/.codex/skills/`.

## Documentation côté plateforme (dépôt jpb-platform)

- Guide de démarrage d'une application : `docs/onboarding/index.html`
- Référentiel de conformité : `docs/features/plateforme-vxrail/standards/conformite-app.md`
- Procédure : `docs/features/plateforme-vxrail/runbooks/mise-en-conformite-app.md`
- Règles inscrites dans une nouvelle app : `docs/features/plateforme-vxrail/standards/section-claude-app.md`
