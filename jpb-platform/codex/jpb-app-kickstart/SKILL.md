---
name: "jpb-app-kickstart"
description: "Point d'entrée d'une NOUVELLE application destinée à JPB-Platform (plateforme d'hébergement des applications internes de JPB). À lancer dès la première session, avant tout brainstorm ou code : vérifie le poste et les accès (outils, compte GitHub, organisation KeyProd), charge les règles de la plateforme, crée tout de suite le dépôt KeyProd/<app>, branches develop et main comprises, avec ses règles et ses garde-fous (CLAUDE.md, AGENTS.md, hooks git et Claude Code, .gitignore), installe le travail par branches feat/ et fix/ avec PR vers develop, propose un brainstorm si le besoin n'est pas cadré, rédige la demande de raccordement pour l'équipe DevOps, puis fait le point de conformité à chaque décision structurante (technologie, connexion des utilisateurs, données, première livraison). Ré-invocable : reprend là où en est le projet et remet les garde-fous à jour. Déclencheurs : « je démarre une nouvelle app », « nouvelle application pour la plateforme », « kickstart », « créer une app JPB-Platform », « où en est la conformité de mon app », « qu'est-ce qui manque avant de livrer ». Pour une application qui existe déjà : jpb-app-conformite-audit puis jpb-app-conformite-transformation."
metadata:
  short-description: "JPB-Platform — démarrer une nouvelle application"
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

Ordre d'une première session : poste vérifié → dépôt créé et protégé → besoin cadré →
raccordement demandé. Le dépôt vient **avant** le brainstorm : même vierge de code, il porte
déjà les règles et les garde-fous, et le cadrage s'y écrit.

## 0. Vérifier le poste et charger le référentiel — toujours en premier

```bash
echo "git|$(git --version 2>&1)"
echo "gh|$(gh --version 2>&1 | head -1)"
echo "Compte GitHub|$(gh api user --jq .login 2>&1)"
echo "Organisation KeyProd|$(gh api user/memberships/orgs/KeyProd --jq '.state + " " + .role' 2>&1)"
echo "Double authentification (2FA)|$(gh api user --jq .two_factor_authentication 2>&1)"
echo "Skills kp-agents|$(ls -d ~/.codex/skills/kp-brainstorm 2>&1)"
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
echo "Référentiel|$JPB — $(git -C "$JPB" rev-parse --abbrev-ref HEAD 2>&1) @ $(git -C "$JPB" log -1 --format='%h du %cs' 2>&1)"
```

Une ligne par contrôle (`contrôle|constat`). **Montre le résultat à l'utilisateur en tableau
✅ / ⚠️ / ❌**, au premier appel d'une session — c'est sa preuve que le poste est prêt ; aux
appels suivants, une ligne suffit si tout est ✅. Lecture :

| Contrôle | ✅ | ❌ et geste à indiquer |
|---|---|---|
| git, gh | une version | absent : git → `xcode-select --install` (macOS) ; gh → https://cli.github.com ; installation bloquée : ticket à support@jpb-systeme.com |
| Compte GitHub | un identifiant | erreur : `gh auth login` |
| Organisation KeyProd | `active …` | `pending` : accepter l'invitation (https://github.com/orgs/KeyProd/invitation) ; erreur : demander l'invitation à l'équipe DevOps |
| Double authentification | `true` | `false` : l'activer (github.com → Settings → Password and authentication) ; vide ou `null` : ⚠️ non vérifiable depuis le poste (GitHub ne l'expose pas au jeton de gh), la rappeler sans bloquer |
| Skills kp-agents | le dossier existe | absent : `./sync.sh` depuis un clone de `KeyProd/kp-agents` |
| Référentiel | un chemin, une branche, un commit | erreur d'accès : voir « Organisation KeyProd » |

- Un **❌** : explique le geste indiqué, dis qui contacter (équipe DevOps pour l'organisation
  GitHub, support@jpb-systeme.com pour le poste), et **arrête-toi**. Ne continue jamais de
  mémoire.
- Le chemin de la ligne « Référentiel » est `$JPB` dans la suite (réécris-le en clair dans
  chaque commande, le shell repart de zéro à chaque appel). C'est une copie en lecture seule,
  ou le clone de travail désigné par `$JPB_PLATFORM_DIR`.

Puis lis :

- `$JPB/docs/features/plateforme-vxrail/standards/section-claude-app.md` — les règles à
  inscrire dans le dépôt de l'app ;
- `$JPB/docs/features/plateforme-vxrail/standards/gabarit-app/README.md` — les garde-fous à
  installer ;
- `$JPB/docs/features/plateforme-vxrail/standards/protection-branches.md`, BR-13 — le travail
  par branches ;
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
| `develop` et `main` sur GitHub ? | `git ls-remote --heads origin develop main` |
| Garde-fous installés et à jour ? | commandes du point 14 du référentiel (section `## JPB-Platform` de `CLAUDE.md` et `AGENTS.md`, fichiers du gabarit, `git config core.hooksPath`) |
| Sur quelle branche ? | `git branch --show-current` — sur `develop` ou `main` avec des modifications en cours : § 3, « Travailler par branches » |
| Besoin cadré ? | `docs/ideas/*.md` au statut `qualified` (kp-brainstorm), ou besoin clairement décrit par l'utilisateur |
| Raccordement demandé ? | `docs/raccordement.md` et sa date d'envoi |
| Caller CI préparé ? fusionné ? | `.github/workflows/ci.yml` sur `develop` ; sinon `gh pr list --head feat/ci-plateforme --state all` |
| Technologie choisie ? | manifestes : `package.json`, `pyproject.toml`, `requirements.txt`, `composer.json`, `go.mod`, `pom.xml`… |
| Conteneur, santé, configuration ? | `Dockerfile`, route `/healthz`, lecture de `PORT` et des variables d'environnement |
| Utilisateurs connectés ? | code ou dépendances OIDC ; sinon, demander si le besoin l'implique |
| Données ? | base de données, fichiers écrits |
| Raccordée ? | `ls -d "$JPB"/envs/dev/<app>` |

Présente l'état en un court tableau (✅ fait · ⏳ à faire maintenant · — pas encore
pertinent), dis quelle est la prochaine étape, puis enchaîne sur la section correspondante.
Des garde-fous absents ou différents du gabarit passent avant tout le reste (§ 3).

## 2. Nommer l'app et créer le dépôt — dès la première session

- **Nom** : minuscules, chiffres et tirets ; court et parlant. Il sert au dépôt, à l'image, à
  l'adresse web et au client de connexion. C'est un **nom de travail** jusqu'à l'envoi de la
  demande de raccordement (§ 5) : il reste renommable d'ici là, il est **définitif** ensuite.
  Si le besoin n'est pas encore cadré, un nom provisoire suffit. Demande d'abord si l'équipe
  DevOps a déjà déclaré l'app dans jpb-gateway (elle le fait souvent dès l'ouverture des
  accès) : si oui, reprends ce nom-là, il est déjà définitif.
- Annonce ce que tu vas créer (dépôt privé `KeyProd/<app>`, branches `develop` et `main`,
  fichiers du § 3, PR en brouillon du caller CI) et attends **un** accord de l'utilisateur.
- Crée le dépôt :

  ```bash
  gh repo create KeyProd/<app> --private --description "<une phrase>"
  ```

  - Refus « name already exists » : le nom est pris — peut-être par un dépôt que l'équipe
    DevOps a déjà créé pour l'app. Demande à l'utilisateur ; si c'est le sien,
    `gh repo view KeyProd/<app>` doit le montrer.
  - Refus de droits : l'utilisateur demande la création du dépôt à l'équipe DevOps ; tu
    continues en local en attendant (§ 3), sans publier.
- Rattache le dossier du projet :
  - pas encore de dépôt git : `git init -b develop` ;
  - dépôt local sans `develop` (souvent `main` ou `master` créé par défaut) :
    `git branch -m develop` s'il a des commits, `git symbolic-ref HEAD refs/heads/develop`
    s'il n'en a pas — `main` ne se crée que sur GitHub, à l'amorçage (§ 3) ;
  - puis `git remote add origin https://github.com/KeyProd/<app>.git`.
- Dépôt déjà créé par l'équipe DevOps, avec une branche `develop` publiée : clone-le (ou
  ajoute-le comme `origin`) et installe les garde-fous par une branche de travail (§ 3).

### Renommer — seulement avant l'envoi de la demande, et si l'app n'est pas déjà déclarée

```bash
gh repo rename <nouveau-nom> -R KeyProd/<ancien-nom> --yes
git remote set-url origin https://github.com/KeyProd/<nouveau-nom>.git
```

Puis mets à jour le nom dans la section `## JPB-Platform` de `CLAUDE.md` et `AGENTS.md`, sur
une branche de travail. Après l'envoi de la demande : plus de renommage — l'équipe DevOps a
pu déclarer l'app sous ce nom ; un changement passe par elle.

## 3. Installer les règles et les garde-fous

Ce qui fait tenir les règles par **toute** session suivante — `kp-developer`, `kp-review`,
Codex, l'utilisateur dans un terminal.

1. **Garde-fous** : suis le README du gabarit, § « Installer » — copie des hooks,
   `chmod +x`, `git config core.hooksPath .githooks`, puis `.gitignore` et
   `.claude/settings.json` **sans rien écraser** (fusion décrite dans le README).
2. **Règles** : insère le bloc de `section-claude-app.md`, nom de l'app remplacé, dans
   `CLAUDE.md` **et** `AGENTS.md` à la racine : ajoute la section si elle manque, mets-la à
   jour si elle diffère, ne touche pas au reste du fichier.
3. **`README.md`** s'il manque : le nom de l'app et une phrase.
4. **Commit et publication** :
   - **amorçage** — `develop` n'a jamais été publiée : un seul commit sur `develop`
     (`chore: amorçage JPB-Platform — règles et garde-fous`), puis les deux branches sur
     GitHub, sur ce même commit :

     ```bash
     git push -u origin develop
     git push origin develop:main
     gh repo edit KeyProd/<app> --default-branch develop
     ```

     Le `pre-commit` accepte ce commit sur `develop` et le `pre-push` la création de `main` :
     le commit ne porte aucun workflow, GitHub n'y lance aucune CI (BR-02, exception ; BR-13).
     Ensuite, même si `develop` attend encore d'être publiée (dépôt pas encore créé), tout
     travail se fait sur une branche ;
   - **mise à jour** — `develop` existe déjà sur GitHub : branche
     `fix/garde-fous-jpb-platform`, commit, PR vers `develop` (§ « Travailler par branches »).
     Si `main` manque (dépôt créé avant cette version de la skill, ou par DevOps), propose
     de la créer sur le premier commit de `develop` — accolades obligatoires, zsh lirait
     `$racine:r` comme un modificateur :

     ```bash
     racine="$(git rev-list --max-parents=0 origin/develop)"
     git push origin "${racine}:refs/heads/main"
     ```

     Refus du `pre-push` (ce commit porte un workflow) : n'insiste pas, `main` se créera à la
     mise en PROD, par l'équipe DevOps.
5. **Caller CI, préparé tout de suite** : README du gabarit, § « Le caller CI » — branche
   `feat/ci-plateforme`, `.github/workflows/ci.yml` copié du gabarit, PR **en brouillon** vers
   `develop`. Le fichier existe dès le premier jour, il ne s'oubliera pas, et rien ne part :
   la PR attend le raccordement (§ 6). Dépôt pas encore créé : prépare la branche en local et
   publie-la avec `develop`.
6. **Codex n'a pas de hook de session** : à chaque appel, vérifie `git config core.hooksPath`
   (attendu : `.githooks`) et, sinon, pose-le. Les fichiers `.claude/` ne servent qu'aux
   sessions Claude Code ; installe-les quand même, le dépôt est partagé.
7. **Explique à l'utilisateur** ce qui vient d'être posé, une ligne par fichier, et ce que ça
   change pour lui : désormais, un commit sur `develop`, un secret, un manifest Kubernetes ou
   un push vers `develop` sont refusés sur son poste ; le travail passe par des branches ; la
   PR en brouillon du caller CI attend le raccordement — on ne la ferme pas.

À chaque nouvel appel, revérifie le point 14 : un générateur de projet (`npm create`,
`django-admin startproject`…) réécrit souvent `.gitignore`, et le gabarit évolue.

### Travailler par branches (BR-13)

À expliquer simplement à l'utilisateur dès l'amorçage, puis à appliquer à chaque étape :

- `develop`, c'est la DEV ; on n'y travaille jamais directement. Chaque sujet a sa branche,
  partie de `develop` à jour : `feat/<sujet>` pour une évolution, `fix/<sujet>` pour une
  correction (`feat/cadrage`, `feat/export-pdf`, `fix/calcul-heures`).

  ```bash
  git switch develop && git pull
  git switch -c feat/<sujet>
  ```

- Le travail fini revient sur `develop` par une **PR**, que l'utilisateur fusionne lui-même
  (aucune relecture exigée sur `develop`) — avec son accord explicite à chaque fois :

  ```bash
  git push -u origin feat/<sujet>
  gh pr create --base develop --fill
  gh pr merge --merge --delete-branch
  ```

  Une fois l'app raccordée, cette fusion **est** la livraison en DEV.
- Modifications faites par erreur sur `develop` : `git switch -c feat/<sujet>` — elles
  suivent la nouvelle branche, rien n'est perdu.
- Un correctif urgent de PROD suit le même chemin (`fix/…` → `develop` → promotion par
  l'équipe DevOps) : jamais de branche partie de `main`.
- Un refus d'un hook se lit et se corrige ; il ne se contourne jamais (`--no-verify`).

## 4. Cadrer le besoin — s'il ne l'est pas

Sur une branche `feat/cadrage`, recommande `$kp-brainstorm` (skills kp-agents)
avant d'aller plus loin. Les règles de la plateforme sont déjà dans la conversation et dans
`AGENTS.md` : le brainstorm en tiendra compte. Rappelle les trois qui pèsent sur le cadrage :

- la connexion des utilisateurs passe par jpb-gateway, jamais par un écran de connexion maison ;
- les données d'un autre service ou d'un système existant (ERP, pointage…) demandent l'accord
  de leur propriétaire ;
- le **responsable métier** du projet sera le propriétaire de l'app et décidera de ses accès :
  qui est-ce ?

C'est une recommandation, pas une porte : l'utilisateur peut la décliner. Le cadrage fini
(`docs/ideas/…`), PR vers `develop`. Si le cadrage a fait évoluer le nom, renomme maintenant
(§ 2) : c'est la dernière occasion.

## 5. Demander le raccordement — dès que le nom est confirmé

Remplis le modèle « Demande de raccordement » du runbook avec ce que tu sais ; écris « à
préciser » pour ce qui ne l'est pas encore (mode d'accès, base, secrets…). **Aucune valeur de
secret** dans la demande, seulement leurs noms et leur rôle. Enregistre-la dans
`docs/raccordement.md`, sur la branche de travail en cours ; l'utilisateur l'envoie à l'équipe
DevOps (mail, Teams ou en direct) et tu notes en tête du fichier « Envoyée le <date> ».

Préviens avant l'envoi : **à partir de là, le nom ne change plus**.

Explique ce que le raccordement débloque : la connexion des utilisateurs (avant, l'app tourne
sans connexion et l'annonce à l'écran), la saisie des variables et secrets dans jpb-gateway,
et la livraison en DEV. Inutile d'attendre la fin du développement pour le demander.

## 6. Faire le point de conformité au fil des décisions

Quand une décision structurante tombe — et à chaque nouvel appel —, confronte le dépôt aux
points du référentiel **qui s'appliquent à ce stade**, et à eux seuls :

| Décision ou stade | Points du référentiel |
|---|---|
| Toujours | 14 garde-fous du dépôt (à jour avec le gabarit) |
| Technologie choisie | 1 Dockerfile · 2 `/healthz` · 3 configuration · 4 port · 10 portabilité — vérifie alors que Docker est installé (`docker version`) pour éprouver l'image en local. Modèle : `$JPB/apps-poc/hello-a/` (`Dockerfile`, `.env.example`, et `qa.yml`, les contrôles de PR exigés avant la PROD, à ajouter par une branche de travail) |
| Utilisateurs connectés | 8 authentification — lire `standards/authentification-oidc.md`, modèle `apps-poc/hello-a/` |
| Données | 5 secrets · 6 état · 7 migrations |
| Raccordement confirmé par DevOps | 9 CI : sortir la PR du caller du brouillon (`gh pr ready`) et la fusionner, avec l'accord de l'utilisateur — c'est la première livraison en DEV · 12 cohérence du nom · 13 hébergement |
| Avant la PROD | 11 protection des branches (DevOps) · contre-audit |

Pour chaque écart : explique-le en une phrase, propose la correction ; avec l'accord de
l'utilisateur, fais-la sur une branche de travail, ou laisse `kp-developer` la faire — les
règles sont dans `AGENTS.md`. N'exige pas un point qui ne s'applique pas encore : pas d'OIDC
tant que le besoin de connexion n'est pas établi.

⚠️ Ne fusionne la PR du caller CI qu'une fois le raccordement confirmé par DevOps
(`envs/dev/<app>/` présent dans `$JPB`) : fusionnée avant, elle fait échouer la CI. Ne la ferme
pas pour autant : c'est le pense-bête de la première livraison.

## 7. Passer la main

- **Livrer en DEV** : une fois l'app raccordée et la PR du caller CI fusionnée, chaque PR
  fusionnée sur `develop` est une livraison ; l'app est en ligne quelques minutes plus tard, son état se suit dans jpb-gateway (*Administration →
  l'app*).
- **Contre-audit** : dès que le code est sur GitHub, lancer `$jpb-app-conformite-audit`
  puis envoyer le rapport et le journal des écarts à l'équipe DevOps. Il se déroule en
  parallèle de la DEV et il est exigé avant la PROD.

## Règles dures

- Jamais de commit ni de push vers `main` : elle n'est créée qu'à l'amorçage, sur un commit
  sans workflow, puis ne reçoit que les promotions de l'équipe DevOps. Jamais de commit sur
  `develop` hors amorçage, jamais de push vers `develop` : le travail y arrive par une PR. Jamais de `--no-verify`, jamais de
  `core.hooksPath` détourné, jamais de garde-fou retiré pour « débloquer ».
- Jamais de manifest Kubernetes dans le dépôt. Jamais de secret dans le code, l'historique,
  un fichier versionné ou une demande. Jamais d'écran de connexion maison.
- Aucun geste côté plateforme — dépôt jpb-platform, Vault, jpb-gateway, protection des
  branches : tu prépares la demande, l'équipe DevOps la joue. La copie de jpb-platform est en
  lecture seule.
- Créer le dépôt, fusionner une PR, renommer : chaque fois avec l'accord explicite de
  l'utilisateur. La PR du caller CI ne se fusionne jamais avant la confirmation du
  raccordement.
- Une règle qui bloque le besoin se remonte à l'équipe DevOps : tu ne la contournes pas et tu
  n'inventes pas d'exception.
- Le référentiel fait foi sur cette skill : en cas de contradiction, suis-le et note l'écart
  au journal des écarts.
