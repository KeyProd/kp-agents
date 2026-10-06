---
name: "jpb-app-conformite-audit"
description: "Audite une application (dépôt local ou distant) contre le référentiel de conformité de JPB-Platform et produit un rapport d'écarts avec l'effort estimé. Joué par le créateur de l'app pour se mettre en conformité, puis rejoué par l'équipe DevOps (contre-audit) avant toute mise en PROD. Déclencheurs : « audite cette app », « est-ce que cette app est conforme », « qu'est-ce qui manque pour déployer X sur la plateforme », « check conformité », « contre-audit ». Lecture seule — ne modifie rien (pour corriger : jpb-app-conformite-transformation ; pour une nouvelle app : jpb-app-kickstart)."
metadata:
  short-description: "JPB-Platform — audit de conformité d'une application"
---

# Audit de conformité JPB-Platform

Tu audites une application contre le référentiel de conformité de JPB-Platform. Tu ne
modifies rien : tu constates, tu prouves, tu classes. Ton utilisateur est souvent le créateur
de l'app, un métier outillé par l'IA : en plus du rapport détaillé, dis-lui en clair par quoi
commencer.

Les règles ne sont pas dans cette skill : elles vivent dans le dépôt privé
`KeyProd/jpb-platform`, et c'est lui qui fait foi.

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
à demander à l'équipe DevOps. Ne jamais auditer de mémoire.

Puis lis **intégralement** `$JPB/docs/features/plateforme-vxrail/standards/conformite-app.md`
— points de contrôle, « Qui vérifie quoi », « Sortie attendue » — et les références qu'il
liste : standards d'authentification et de protection des branches, templates du chart,
implémentation de référence.

## 1. Cadrer

- Identifie l'app : son nom (minuscules et tirets) et son dépôt.
- Fixe le mode :
  - **créateur** (par défaut) : l'utilisateur audite sa propre app pour la mettre en conformité ;
  - **contre-audit** : l'utilisateur fait partie de l'équipe DevOps et rejoue l'audit d'un
    créateur — demande-lui le rapport et le journal des écarts du créateur.
- **Lecture seule absolue** : aucune écriture dans le dépôt, aucun réglage de dépôt, aucun
  force-push, aucune commande qui modifie un cluster ou un service.

## 2. Dérouler les 13 points

Un verdict ✅ / ⚠️ / ❌ par point, chacun avec sa preuve : fichier et ligne, ou sortie de
commande. Une vérification impossible faute de droits ou d'outil (`kubectl`, administration
du dépôt) se note **« non vérifié (droits) »** — jamais devinée. Adapte le verdict au stade du
projet comme le prévoit le référentiel : une app qui n'a pas encore demandé la PROD n'a pas à
avoir sa branche `main` protégée.

## 3. Rendre le rapport

Au format « Sortie attendue » du référentiel : tableau des 13 points, écarts classés
(bloquant / important / cosmétique), effort estimé (S/M/L), points « non vérifié (droits) » à
part, recommandation. Termine par trois lignes en clair : les trois premières choses à faire.

Joins le **journal des écarts** : ce que le référentiel ou les skills n'ont pas su traiter,
même vide. Le rapport reste dans la conversation ; ne l'écris dans un fichier que si
l'utilisateur le demande.

- **Mode créateur** : s'il reste des écarts, propose `$jpb-app-conformite-transformation`
  (app existante) ou `$jpb-app-kickstart` (nouvelle app). Sinon, l'utilisateur envoie
  rapport et journal à l'équipe DevOps : c'est le contre-audit, exigé avant la PROD.
- **Mode contre-audit** : compare point par point au rapport du créateur et liste (a) les
  écarts confirmés, (b) les écarts que le créateur n'a pas vus — à verser au référentiel, pour
  que l'outil progresse —, (c) les faux écarts. Conclus : conformité confirmée (prérequis de
  la PROD levé) ou non, avec ce qui reste à corriger.
