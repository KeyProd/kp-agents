---
name: "jpb-app-conformite-transformation"
description: "Met une application existante en conformité avec JPB-Platform, à partir de son rapport d'audit : hébergement sous GitHub KeyProd, configuration par variables d'environnement, Dockerfile, healthcheck, migrations, authentification via jpb-gateway, CI. Rédige la demande de raccordement pour l'équipe DevOps, qui joue les gestes côté plateforme. Déclencheurs : « rends cette app déployable », « mets X en conformité », « prépare cette app pour la plateforme », « dockerise cette app pour l'infra », « transforme cette app ». Modifie l'app — pour un simple état des lieux : jpb-app-conformite-audit ; pour une nouvelle app : jpb-app-kickstart."
metadata:
  short-description: "JPB-Platform — mise en conformité d'une application existante"
---

# Transformation de conformité JPB-Platform

Tu mets une application existante en conformité avec JPB-Platform, écart par écart, sans
changer ce qu'elle fait. Ton utilisateur est souvent son créateur, un métier outillé par
l'IA : une étape à la fois, expliquée, prouvée, puis committée.

Les règles et la procédure ne sont pas dans cette skill : elles vivent dans le dépôt privé
`KeyProd/jpb-platform`, et ce sont elles qui font foi.

## 0. Charger le référentiel — toujours en premier

```bash
if [ -n "${JPB_PLATFORM_DIR:-}" ]; then
  JPB="$JPB_PLATFORM_DIR"
else
  JPB="${XDG_CACHE_HOME:-$HOME/.cache}/jpb-platform"
  if [ -d "$JPB/.git" ]; then
    git -c credential.helper= -c 'credential.helper=!gh auth git-credential' -C "$JPB" \
      fetch --quiet --depth 1 origin main && git -C "$JPB" reset --quiet --hard FETCH_HEAD
  else
    gh repo clone KeyProd/jpb-platform "$JPB" -- --quiet --depth 1
  fi
fi
echo "$JPB"
```

Ces commandes affichent le chemin d'une copie à jour de jpb-platform : c'est `$JPB` dans la suite
(réécris-le en clair dans chaque commande). Si elles échouent, explique le message à l'utilisateur
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
`$jpb-app-conformite-audit`. Présente le plan de transformation qui en découle et
attends l'accord de l'utilisateur avant toute modification.

## 2. Établir qui joue quoi

Demande à l'utilisateur s'il fait partie de l'équipe DevOps.

- **Non** (cas par défaut) : tu ne joues que les gestes « Dépôt de l'app » du runbook. Pour les
  gestes « Plateforme » — dépôt jpb-platform, Vault, jpb-gateway, protection des branches,
  création de `main` —, tu rédiges la **demande de raccordement**.
- **Oui** : tu peux aussi dérouler les gestes plateforme du runbook, chacun soumis à la
  validation explicite que le runbook exige.

## 3. Dérouler la procédure du runbook

Dans son ordre : l'**hébergement sous KeyProd** d'abord, si l'audit l'a signalé (point 13) ;
puis une branche `feat/conformite-plateforme` dans le dépôt KeyProd ; puis l'ordre de
transformation. Pour chaque étape : expliquer l'écart en une phrase, modifier, prouver (build,
exécution, tests), committer. Tant que l'app n'est pas déclarée dans jpb-gateway, elle tourne
sans connexion et l'annonce : c'est attendu.

## 4. Demander le raccordement

Remplis le modèle « Demande de raccordement » du runbook — **aucune valeur de secret**,
seulement leurs noms et leur rôle — et fais-le envoyer à l'équipe DevOps dès que le nom de
l'app est fixé, sans attendre la fin de la transformation. N'ajoute le caller CI sur `develop`
qu'une fois le raccordement confirmé.

## 5. Clore

- Rejoue `$jpb-app-conformite-audit` : il ne doit plus rester d'écart bloquant.
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
- Une impossibilité se remonte à l'équipe DevOps : elle ne se contourne pas. Le runbook fait
  foi sur cette skill ; en cas de contradiction, suis-le et note l'écart au journal.
