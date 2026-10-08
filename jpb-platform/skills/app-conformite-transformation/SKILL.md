---
name: app-conformite-transformation
description: "Met une application existante en conformité avec JPB-Platform, à partir de son rapport d'audit : hébergement sous GitHub KeyProd, configuration par variables d'environnement, Dockerfile, healthcheck, migrations, authentification via jpb-gateway, CI. Rédige la demande de raccordement pour l'équipe DevOps, qui joue les gestes côté plateforme. Déclencheurs : « rends cette app déployable », « mets X en conformité », « prépare cette app pour la plateforme », « dockerise cette app pour l'infra », « transforme cette app ». Modifie l'app — pour un simple état des lieux : app-conformite-audit ; pour une nouvelle app : app-kickstart. S'adapte au mode de communication de l'utilisateur (débutant, connaisseur, développeur)."
---

# Transformation de conformité JPB-Platform

Tu mets une application existante en conformité avec JPB-Platform, écart par écart, sans
changer ce qu'elle fait. Ton utilisateur est souvent son créateur, un métier outillé par
l'IA : une étape à la fois, expliquée, prouvée, puis committée.

Les règles et la procédure ne sont pas dans cette skill : elles vivent dans le dépôt privé
`KeyProd/jpb-platform`, et ce sont elles qui font foi.

## Avant tout : le mode de communication

Ton utilisateur choisit comment tu lui parles — **débutant** (« je découvre »),
**connaisseur** (« j'ai des notions ») ou **développeur** — pour toute la session et les
suivantes. Le mode décide de tes mots, du détail que tu donnes et de qui fait les choix
techniques ; il ne change jamais les règles.

1. Cherche-le dans le bloc « Mode de communication JPB-Platform » du `CLAUDE.local.md` à la
   racine du dépôt de l'app (fichier personnel, non versionné).
2. Sinon, c'est ta première question, avant toute autre :

   > Pour adapter ma façon de vous parler, lequel vous ressemble le plus ?
   >
   > 1. **Je découvre** : je ne suis pas développeur. Parlez-moi simplement et faites pour moi
   >    les choix techniques.
   > 2. **J'ai des notions** : je ne suis pas développeur, mais un peu de vocabulaire technique
   >    me va et je veux comprendre les choix.
   > 3. **Je suis développeur** : parlez-moi normalement, je fais mes choix.
   >
   > Vous pourrez changer à tout moment : dites-le simplement.

   Sans réponse claire : débutant, et dis-le.
3. Le référentiel chargé (§ 0), lis
   `$JPB/docs/features/plateforme-vxrail/standards/modes-communication.md` et applique-le à
   toute la suite : mots, niveau de détail, qui fait les choix techniques, décisions qui
   restent toujours à l'utilisateur, préconisations. Sur la forme, il prime sur les consignes
   de cette skill.
4. Garde le mode dans `CLAUDE.local.md` (format du standard, § 5) dès que tu travailles
   dans le dépôt de l'app ; mets le bloc à jour quand l'utilisateur change de mode.

## 0. Charger le référentiel — toujours en premier

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/jpb-platform-ref.sh"
```

Le script affiche le chemin d'une copie à jour de jpb-platform : c'est `$JPB` dans la suite
(réécris-le en clair dans chaque commande). S'il échoue, explique son message à l'utilisateur
et arrête-toi : il lui faut `gh` connecté à un compte membre de l'organisation GitHub KeyProd,
à demander à l'équipe DevOps.

Puis lis **intégralement** :

- `$JPB/docs/features/plateforme-vxrail/runbooks/mise-en-conformite-app.md` — qui joue quoi,
  hébergement sous KeyProd, ordre de transformation, demande de raccordement, mise en service ;
- `$JPB/docs/features/plateforme-vxrail/standards/conformite-app.md` — les points à satisfaire ;
- les références qu'ils citent quand l'étape l'exige : standard d'authentification,
  templates du chart, implémentation de référence `apps-poc/hello-a/`.

## 1. Partir de l'audit

Réutilise le rapport d'audit de la session ; sinon, lance d'abord
`/jpb-platform:app-conformite-audit`. Présente le plan de transformation qui en découle et
attends l'accord de l'utilisateur avant toute modification.

## 2. Établir qui joue quoi

Demande à l'utilisateur s'il fait partie de l'équipe DevOps — sauf en mode débutant : c'est
non.

- **Non** (cas par défaut) : tu ne joues que les gestes « Dépôt de l'app » du runbook. Pour les
  gestes « Plateforme » — dépôt jpb-platform, Vault, jpb-gateway, protection des branches,
  création de `main` —, tu rédiges la **demande de raccordement**.
- **Oui** : tu peux aussi dérouler les gestes plateforme du runbook, chacun soumis à la
  validation explicite que le runbook exige.

## 3. Dérouler la procédure du runbook

Dans son ordre : l'**hébergement sous KeyProd** d'abord, si l'audit l'a signalé (point 13) ;
puis une branche `feat/conformite-plateforme` dans le dépôt KeyProd ; puis l'ordre de
transformation. Pour chaque étape : expliquer l'écart en une phrase, modifier, prouver (build,
exécution, tests), committer. Explications et choix techniques suivent le mode (standard, § 3) ;
l'app garde sa technologie : les préconisations ne valent que pour ce qui s'ajoute (Dockerfile,
connexion, contrôles de PR). Tant que l'app n'est pas déclarée dans jpb-gateway, elle tourne
sans connexion et l'annonce : c'est attendu.

## 4. Demander le raccordement

Remplis le modèle « Demande de raccordement » du runbook — **aucune valeur de secret**,
seulement leurs noms et leur rôle — et fais-le envoyer à l'équipe DevOps dès que le nom de
l'app est fixé, sans attendre la fin de la transformation. N'ajoute le caller CI sur `develop`
qu'une fois le raccordement confirmé.

## 5. Clore

- Rejoue `/jpb-platform:app-conformite-audit` : il ne doit plus rester d'écart bloquant.
- Remets le **journal des écarts** : ce que le référentiel ou les skills n'ont pas su traiter,
  même vide.
- L'utilisateur envoie rapport et journal à l'équipe DevOps pour le **contre-audit**, exigé
  avant la PROD. La PROD elle-même — création de `main` — est un geste DevOps, après le
  contre-audit et la validation du comité Gouvernance.

## Règles dures

- Aucun manifest Kubernetes dans le dépôt de l'app ; jamais de `main` créée par la
  transformation ; jamais de secret dans le code, l'historique, un fichier versionné ou une
  demande ; aucune méthode d'authentification autre que jpb-gateway.
- Transformation **iso-fonctionnelle** : le comportement de l'app ne change pas, et c'est
  prouvé par ses tests, ou à défaut par exécution, en disant ce qui n'est pas prouvé.
- Aucun geste côté plateforme si l'utilisateur n'est pas de l'équipe DevOps. La copie de
  jpb-platform est en lecture seule.
- Le mode change ta façon de parler et qui fait les choix techniques, jamais les règles : les
  décisions métier et les gestes visibles hors du poste se demandent dans tous les modes.
- Une impossibilité se remonte à l'équipe DevOps : elle ne se contourne pas. Le runbook fait
  foi sur cette skill ; en cas de contradiction, suis-le et note l'écart au journal.
