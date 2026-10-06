---
name: app-kickstart
description: "Point d'entrée d'une NOUVELLE application destinée à JPB-Platform (plateforme d'hébergement des applications internes de JPB). À lancer dès la première session, avant tout brainstorm ou code : charge les règles de la plateforme, propose un brainstorm si le besoin n'est pas cadré, crée le dépôt KeyProd/<app>, y inscrit les règles pour toutes les sessions suivantes, rédige la demande de raccordement pour l'équipe DevOps, puis fait le point de conformité à chaque décision structurante (technologie, connexion des utilisateurs, données, première livraison). Ré-invocable : reprend là où en est le projet. Déclencheurs : « je démarre une nouvelle app », « nouvelle application pour la plateforme », « kickstart », « créer une app JPB-Platform », « où en est la conformité de mon app », « qu'est-ce qui manque avant de livrer ». Pour une application qui existe déjà : app-conformite-audit puis app-conformite-transformation."
---

# Kickstart d'une application JPB-Platform

Tu accompagnes le créateur d'une nouvelle application destinée à JPB-Platform. C'est souvent
un métier outillé par l'IA, pas un développeur : explique simplement, une décision à la fois,
sans jargon inutile. Ton travail : que l'app respecte les règles de la plateforme **dès la
première ligne**, sans imposer trop tôt des choix que le projet ne peut pas encore faire
(technologie, connexion des utilisateurs, données).

Tu ne portes pas les règles : elles vivent dans le dépôt privé `KeyProd/jpb-platform`, et tu
les relis à chaque invocation. Tu es **ré-invocable** : à chaque appel, tu détectes où en est
le projet et tu reprends là. Tu ne refais jamais ce qui est fait.

## 0. Charger le référentiel — toujours en premier

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/jpb-platform-ref.sh"
```

Le script affiche le chemin d'une copie à jour de jpb-platform : c'est `$JPB` dans la suite
(réécris-le en clair dans chaque commande, le shell repart de zéro à chaque appel). Il prend
`$JPB_PLATFORM_DIR` s'il est défini, sinon une copie en cache, en lecture seule. S'il échoue,
lis son message, explique-le à l'utilisateur et arrête-toi : il lui faut l'outil `gh`
connecté (`gh auth login`) à un compte membre de l'organisation GitHub KeyProd, à demander à
l'équipe DevOps. Ne continue jamais de mémoire.

Puis lis :

- `$JPB/docs/features/plateforme-vxrail/standards/section-claude-app.md` — les règles à
  inscrire dans le dépôt de l'app ;
- `$JPB/docs/features/plateforme-vxrail/standards/conformite-app.md` — les points de contrôle
  (la liste d'abord ; le détail d'un point quand il devient pertinent) ;
- `$JPB/docs/features/plateforme-vxrail/runbooks/mise-en-conformite-app.md`, § « Qui joue
  quoi » et « Demande de raccordement ».

Au premier appel d'une session, résume les règles à l'utilisateur en cinq lignes au plus.

## 1. Détecter l'état du projet

Relève, sans rien modifier :

| Question | Comment |
|---|---|
| Dépôt git ? hébergé sous `KeyProd/<app>` ? | `git rev-parse --show-toplevel`, `git remote -v` |
| Règles inscrites ? | section `## JPB-Platform` dans `CLAUDE.md` et `AGENTS.md` |
| Besoin cadré ? | `docs/ideas/*.md` au statut `qualified` (kp-brainstorm), ou besoin clairement décrit par l'utilisateur |
| Technologie choisie ? | manifestes : `package.json`, `pyproject.toml`, `requirements.txt`, `composer.json`, `go.mod`, `pom.xml`… |
| Conteneur, santé, configuration ? | `Dockerfile`, route `/healthz`, lecture de `PORT` et des variables d'environnement |
| Utilisateurs connectés ? | code ou dépendances OIDC ; sinon, demander si le besoin l'implique |
| Données ? | base de données, fichiers écrits |
| Raccordée ? prête à livrer ? | `ls -d "$JPB"/envs/dev/<app>`, `.github/workflows/ci.yml`, branche `develop` |

Présente l'état en un court tableau (✅ fait · ⏳ à faire maintenant · — pas encore
pertinent), dis quelle est la prochaine étape, puis enchaîne sur la section correspondante.

## 2. Cadrer le besoin — s'il ne l'est pas

Recommande `/kp-agents:kp-brainstorm` (plugin kp-agents) avant d'aller plus loin. Les règles de
la plateforme sont déjà dans la conversation : le brainstorm en tiendra compte. Rappelle les
trois qui pèsent sur le cadrage :

- la connexion des utilisateurs passe par jpb-gateway, jamais par un écran de connexion maison ;
- les données d'un autre service ou d'un système existant (ERP, pointage…) demandent l'accord
  de leur propriétaire ;
- le **responsable métier** du projet sera le propriétaire de l'app et décidera de ses accès :
  qui est-ce ?

C'est une recommandation, pas une porte : l'utilisateur peut la décliner.

## 3. Nommer l'app et créer le dépôt

- **Nom** : minuscules, chiffres et tirets ; court et parlant ; **définitif** — il sert au
  dépôt, à l'image, à l'adresse web et au client de connexion. Vérifie qu'il est libre :
  `gh repo view KeyProd/<app>` doit échouer.
- Annonce ce que tu vas créer et attends l'accord de l'utilisateur.
- Dans le dossier du projet (`git init -b develop` s'il n'est pas encore un dépôt) : un premier
  commit sur `develop` — au minimum un `README.md` d'une phrase et les règles (§ 4) —, puis :

  ```bash
  gh repo create KeyProd/<app> --private --description "<une phrase>"
  git remote add origin https://github.com/KeyProd/<app>.git
  git push -u origin develop
  gh repo edit KeyProd/<app> --default-branch develop
  ```

- ⛔ Ne crée **jamais** `main` : c'est la mise en PROD, faite par l'équipe DevOps.
- `gh repo create` refusé (droits) : l'utilisateur demande la création du dépôt à l'équipe
  DevOps ; tu continues en local en attendant.

## 4. Inscrire les règles dans le dépôt

Insère le bloc de `section-claude-app.md`, nom de l'app remplacé, dans `CLAUDE.md` **et**
`AGENTS.md` à la racine : ajoute la section si elle manque, mets-la à jour si elle diffère, ne
touche pas au reste du fichier. Commit sur `develop` (`docs: règles JPB-Platform`). Explique à
l'utilisateur ce que ça change : toute session suivante — `kp-developer`, `kp-review`… —
travaillera selon ces règles.

## 5. Demander le raccordement — dès que le nom est fixé

Remplis le modèle « Demande de raccordement » du runbook avec ce que tu sais ; écris « à
préciser » pour ce qui ne l'est pas encore (mode d'accès, base, secrets…). L'utilisateur
l'envoie à l'équipe DevOps (mail, Teams ou en direct). **Aucune valeur de secret** dans la
demande, seulement leurs noms et leur rôle.

Explique ce que le raccordement débloque : la connexion des utilisateurs (avant, l'app tourne
sans connexion et l'annonce à l'écran), la saisie des variables et secrets dans jpb-gateway,
et la livraison en DEV. Inutile d'attendre la fin du développement pour le demander.

## 6. Faire le point de conformité au fil des décisions

Quand une décision structurante tombe — et à chaque nouvel appel —, confronte le dépôt aux
points du référentiel **qui s'appliquent à ce stade**, et à eux seuls :

| Décision ou stade | Points du référentiel |
|---|---|
| Technologie choisie | 1 Dockerfile · 2 `/healthz` · 3 configuration · 4 port · 10 portabilité |
| Utilisateurs connectés | 8 authentification — lire `standards/authentification-oidc.md`, modèle `apps-poc/hello-a/` |
| Données | 5 secrets · 6 état · 7 migrations |
| Prête à livrer, raccordement confirmé par DevOps | 9 CI (caller sur `develop`) · 12 cohérence du nom · 13 hébergement |
| Avant la PROD | 11 protection des branches (DevOps) · contre-audit |

Pour chaque écart : explique-le en une phrase, propose la correction ; avec l'accord de
l'utilisateur, fais-la, ou laisse `kp-developer` la faire — les règles sont désormais dans
`CLAUDE.md`. N'exige pas un point qui ne s'applique pas encore : pas d'OIDC tant que le
besoin de connexion n'est pas établi.

⚠️ N'ajoute le caller CI qu'une fois le raccordement confirmé par DevOps : poussé avant, il
fait échouer la CI.

## 7. Passer la main

- **Livrer en DEV** : fusionner le travail sur `develop` ; l'app est en ligne quelques minutes
  plus tard, son état se suit dans jpb-gateway (*Administration → l'app*).
- **Contre-audit** : dès que le code est sur GitHub, lancer `/jpb-platform:app-conformite-audit`
  puis envoyer le rapport et le journal des écarts à l'équipe DevOps. Il se déroule en
  parallèle de la DEV et il est exigé avant la PROD.

## Règles dures

- Jamais de `main`. Jamais de manifest Kubernetes dans le dépôt. Jamais de secret dans le
  code, l'historique, un fichier versionné ou une demande. Jamais d'écran de connexion maison.
- Aucun geste côté plateforme — dépôt jpb-platform, Vault, jpb-gateway, protection des
  branches : tu prépares la demande, l'équipe DevOps la joue. La copie de jpb-platform est en
  lecture seule.
- Une règle qui bloque le besoin se remonte à l'équipe DevOps : tu ne la contournes pas et tu
  n'inventes pas d'exception.
- Le référentiel fait foi sur cette skill : en cas de contradiction, suis-le et note l'écart
  au journal des écarts.
