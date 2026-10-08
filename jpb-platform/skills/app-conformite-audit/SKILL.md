---
name: app-conformite-audit
description: "Audite une application (dépôt local ou distant) contre le référentiel de conformité de JPB-Platform et produit un rapport d'écarts avec l'effort estimé. Joué par le créateur de l'app pour se mettre en conformité, puis rejoué par l'équipe DevOps (contre-audit) avant toute mise en PROD. Déclencheurs : « audite cette app », « est-ce que cette app est conforme », « qu'est-ce qui manque pour déployer X sur la plateforme », « check conformité », « contre-audit ». Lecture seule — ne modifie rien (pour corriger : app-conformite-transformation ; pour une nouvelle app : app-kickstart). S'adapte au mode de communication de l'utilisateur (débutant, connaisseur, développeur)."
---

# Audit de conformité JPB-Platform

Tu audites une application contre le référentiel de conformité de JPB-Platform. Tu ne
modifies rien : tu constates, tu prouves, tu classes. Ton utilisateur est souvent le créateur
de l'app, un métier outillé par l'IA : en plus du rapport détaillé, dis-lui en clair par quoi
commencer.

Les règles ne sont pas dans cette skill : elles vivent dans le dépôt privé
`KeyProd/jpb-platform`, et c'est lui qui fait foi.

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
4. Garde le mode dans `CLAUDE.local.md` (format du standard, § 5) si le dépôt de l'app est
   sur ce poste — la seule écriture que s'autorise cet audit, dans un fichier personnel non
   versionné ; sinon, il vit dans la conversation.
5. **Contre-audit** (équipe DevOps) : mode développeur d'office, sans poser la question.

## 0. Charger le référentiel — toujours en premier

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/jpb-platform-ref.sh"
```

Le script affiche le chemin d'une copie à jour de jpb-platform : c'est `$JPB` dans la suite
(réécris-le en clair dans chaque commande). S'il échoue, explique son message à l'utilisateur
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
- **Lecture seule absolue** : aucune écriture dans le dépôt (hors le bloc du mode dans
  `CLAUDE.local.md`), aucun réglage de dépôt, aucun force-push, aucune commande qui modifie un
  cluster ou un service.

## 2. Dérouler les points du référentiel

Un verdict ✅ / ⚠️ / ❌ par point, chacun avec sa preuve : fichier et ligne, ou sortie de
commande. Une vérification impossible faute de droits ou d'outil (`kubectl`, administration
du dépôt) se note **« non vérifié (droits) »** — jamais devinée. Adapte le verdict au stade du
projet comme le prévoit le référentiel : une app qui n'a pas encore demandé la PROD n'a pas à
avoir sa branche `main` protégée.

## 3. Rendre le rapport

Au format « Sortie attendue » du référentiel : tableau de tous ses points, écarts classés
(bloquant / important / cosmétique), effort estimé (S/M/L), points « non vérifié (droits) » à
part, recommandation. Termine par trois lignes en clair : les trois premières choses à faire.

La forme suit le mode. Débutant : quelques phrases et « ce qu'il faut faire », sans jargon ;
propose d'enregistrer le rapport complet dans un fichier hors du dépôt, à envoyer à l'équipe
DevOps, sinon donne-le en fin de message sous un titre « Pour l'équipe DevOps ». Connaisseur :
le tableau, les écarts expliqués simplement, par quoi commencer. Développeur : le rapport
complet.

Joins le **journal des écarts** : ce que le référentiel ou les skills n'ont pas su traiter,
même vide. Le rapport reste dans la conversation ; ne l'écris dans un fichier que si
l'utilisateur le demande.

- **Mode créateur** : s'il reste des écarts, propose `/jpb-platform:app-conformite-transformation`
  (app existante) ou `/jpb-platform:app-kickstart` (nouvelle app). Sinon, l'utilisateur envoie
  rapport et journal à l'équipe DevOps : c'est le contre-audit, exigé avant la PROD.
- **Mode contre-audit** : compare point par point au rapport du créateur et liste (a) les
  écarts confirmés, (b) les écarts que le créateur n'a pas vus — à verser au référentiel, pour
  que l'outil progresse —, (c) les faux écarts. Conclus : conformité confirmée (prérequis de
  la PROD levé) ou non, avec ce qui reste à corriger.
