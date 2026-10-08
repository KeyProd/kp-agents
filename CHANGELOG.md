# Changelog

Toutes les modifications notables de kp-agents sont listées ici. Format inspiré de [Keep a Changelog](https://keepachangelog.com/), versioning semver.

Chaque plugin de la marketplace est versionné indépendamment (`plugin.json` → champ `version`). Les tags git suivent le format `<plugin-name>-v<X.Y.Z>`.

> **Note sur le versioning** : depuis la refonte « dossiers plats par outil », le bump de version est **manuel** (`.claude-plugin/plugin.json` → `version`). Un hook de pré-commit (`.githooks/pre-commit`) bloque tout commit modifiant un skill sans bump de version. L'auto-bump par `sync.sh` (hash SHA256 / `_contentHash`) a été supprimé.

---

## [kp-agents-v4.2.1] et [jpb-platform-v0.4.1] — Catalogue Codex natif — 2026-10-08

### Corrigé

- Ajout de `.agents/plugins/marketplace.json` : les deux plugins sont déclarés dans le
  catalogue natif Codex, avec leurs chemins, politiques d'installation et catégorie.
  La découverte ne dépend plus du seul catalogue Claude de compatibilité.
- Conservation des plugins à plat : `kp-agents` à la racine, `jpb-platform` dans son
  dossier ; manifestes Claude et Codex à la même version pour chacun.
- Instructions d'installation corrigées : même dépôt git, un catalogue natif par outil.
  Retrait des affirmations selon lesquelles Codex doit lire le seul catalogue Claude.

Les modifications existantes ont été intégrées dans `main`. Aucun contenu d'agent,
référence, règle Cursor ou script de plateforme n'est modifié par cette correction.

---

## [jpb-platform-v0.4.0] — Modes de communication

Demande de Vincent (2026-10-08) : la session s'adapte à son utilisateur. La règle vit dans
jpb-platform (`standards/modes-communication.md`) : ce plugin ne porte que la démarche.

### Ajouté

- Les trois skills posent d'abord une question : débutant (« je découvre »), connaisseur
  (« j'ai des notions ») ou développeur ; sans réponse claire, débutant. Le mode est lu dans le
  bloc « Mode de communication JPB-Platform » du `CLAUDE.local.md` de la personne, et écrit
  dès que le dépôt de l'app existe. Codex, qui ne charge pas ce fichier tout seul, le lit.
- `app-kickstart` : vérification du poste, état du projet, nom, garde-fous, branches et PR,
  demande de raccordement et choix de la technologie suivent le mode. En débutant, les choix
  techniques appliquent les préconisations (TypeScript, application web, Nuxt/Vue) sans
  question ; les décisions métier et les gestes visibles se demandent dans tous les modes.
- `app-conformite-audit` : rapport selon le mode (en débutant, l'essentiel ; le rapport
  complet à part pour l'équipe DevOps) ; contre-audit en mode développeur d'office ; seule
  écriture permise, le bloc du mode dans `CLAUDE.local.md`.
- `app-conformite-transformation` : explications et choix selon le mode ; l'app garde sa
  technologie, les préconisations ne valent que pour ce qui s'ajoute.

---

## [kp-agents-v4.2.0] et [jpb-platform-v0.3.0] — Codex par la marketplace, sans script

Les deux plugins s'installent dans Codex comme dans Claude Code, par la même marketplace git.
Codex lit `.claude-plugin/marketplace.json` ; chaque plugin porte désormais un manifeste
Codex, prioritaire sur celui de Claude, qui pointe ses variantes Codex.

### Ajouté

- `.codex-plugin/plugin.json` (kp-agents, `skills` → `./codex/`) et
  `jpb-platform/.codex-plugin/plugin.json` (`skills` → `./codex/`), à la même version que les
  manifestes Claude.
- Installation Codex :
  `codex plugin marketplace add KeyProd/kp-agents` puis
  `codex plugin add kp-agents@kp-agents` / `codex plugin add jpb-platform@kp-agents` ;
  mise à jour : `codex plugin marketplace upgrade kp-agents`.
- Hook de pré-commit : refuse qu'un manifeste Codex porte une autre version que le manifeste
  Claude du même plugin.

### Modifié

- Variantes Codex de jpb-platform renommées `jpb-app-*` → `app-*` : dans Codex, le plugin
  préfixe ses skills, d'où `jpb-platform:app-kickstart`, le même nom que dans Claude Code.
  Renvois entre skills en `$jpb-platform:app-…` et `$kp-agents:kp-…`.
- `jpb-platform:app-kickstart` (Codex) : la version du plugin se lit dans le chemin du
  `SKILL.md` installé, et la présence de kp-agents dans la liste des skills.
- `sync.sh` n'installe plus que Cursor ; il retire les anciennes copies `kp-*` / `jpb-*` de
  `~/.codex/skills/`, qui doubleraient les skills du plugin.
- README, CLAUDE.md, AGENTS.md, README du plugin jpb-platform : installation Codex.

### Vérifié

Dans un `CODEX_HOME` jetable : marketplace ajoutée, plugins installés, skills vues par le
modèle (`codex debug prompt-input`) — `jpb-platform:app-*` et `kp-agents:kp-*`, toutes
depuis `codex/`. Dans une configuration Claude Code jetable : jpb-platform charge toujours
ses skills de `skills/`. `sync.sh` dans un `HOME` jetable : anciennes copies retirées,
`.system` et skills tierces intactes.

---

## [jpb-platform-v0.2.0] — app-kickstart : poste vérifié, dépôt protégé dès le départ

Retours des premiers essais réels d'`app-kickstart` (2026-10-07 et 2026-10-08). Les règles correspondantes
sont dans le dépôt jpb-platform (`standards/gabarit-app/`, BR-13 de
`protection-branches.md`, point 14 du référentiel) : ce plugin ne porte que la démarche.

### Ajouté

- **`scripts/verifier-poste.sh`** — un tableau ✅ / ⚠️ / ❌ montré à l'utilisateur : version
  du plugin, git, gh, compte GitHub, appartenance à KeyProd, double authentification (non
  lisible depuis le poste : ⚠️, jamais un faux ✅), référentiel lu (branche et commit). Un ❌
  arrête la skill avec le geste à faire et la personne à contacter.
- **Garde-fous du dépôt dès l'amorçage** — hooks git (pas de commit sur `develop` ni `main`,
  pas de secret ni de manifest Kubernetes, pas de push vers `develop` ni `main`), hooks
  Claude Code (`core.hooksPath` activé à chaque session, refus de `--no-verify`, `kubectl`,
  `helm`, lecture des `.env`), bloc `.gitignore` ; remis à jour à chaque appel.
- **Travail par branches** `feat/<sujet>` et `fix/<sujet>`, retour par PR vers `develop`,
  expliqué à l'utilisateur dès l'amorçage.
- **Caller CI préparé dès l'amorçage** sur `feat/ci-plateforme`, dans une PR en brouillon
  vers `develop`, fusionnée une fois le raccordement confirmé par DevOps.
- **`develop` et `main` dès la création du dépôt**, sur le commit d'amorçage : il ne porte
  aucun workflow, GitHub n'y lance aucune CI (BR-02 révisé). Un dépôt créé avec la 0.1.0
  reçoit `main` sur le premier commit de `develop`, si celui-ci n'a pas de workflow.
- **Modèle `apps-poc/hello-a`** remis en conformité côté jpb-platform et cité par la skill
  quand la technologie est choisie (`Dockerfile`, `.env.example`, `qa.yml`).
- **Nom de travail** renommable (`gh repo rename`) jusqu'à l'envoi de la demande de
  raccordement, enregistrée dans `docs/raccordement.md`.

### Modifié

- `app-kickstart` : le dépôt est créé **avant** le brainstorm, même vierge de code ; le
  cadrage s'écrit dedans, sur une branche.
- `app-conformite-audit` : ne fige plus le nombre de points, il déroule ceux du référentiel
  (14 depuis l'ajout des garde-fous).
- Variantes Codex alignées (`jpb-app-kickstart`, `jpb-app-conformite-audit`) ; Codex n'ayant
  pas de hook de session, la skill y vérifie `core.hooksPath` à chaque appel.

---

## [jpb-platform-v0.1.0] — Nouveau plugin jpb-platform

Second plugin de la marketplace, indépendant de `kp-agents` (sa propre version, ses propres tags).

### Ajouté

- **`app-kickstart`** — point d'entrée d'une nouvelle application JPB-Platform, à lancer dès la
  première session : règles de la plateforme dans la conversation, brainstorm recommandé si le
  besoin n'est pas cadré, création du dépôt `KeyProd/<app>` (branche `develop`, jamais `main`),
  inscription des règles dans `CLAUDE.md` / `AGENTS.md` de l'app, demande de raccordement pour
  l'équipe DevOps, point de conformité au fil des décisions. Ré-invocable.
- **`app-conformite-audit`** et **`app-conformite-transformation`** — reprises du dépôt
  jpb-platform (`.claude/skills/`), où elles ne portaient que pour les sessions ouvertes sur le
  poste de l'équipe DevOps. Désormais : mode créateur / contre-audit pour l'audit, partage
  créateur / DevOps pour la transformation (gestes plateforme → demande de raccordement),
  hébergement sous GitHub KeyProd (point 13).
- **Plugin « mince »** : ce dépôt étant public, les skills ne portent que la démarche ; les
  règles (référentiel de conformité, procédure, standards) sont lues dans le dépôt privé
  `KeyProd/jpb-platform` par `scripts/jpb-platform-ref.sh` (clone de travail
  `$JPB_PLATFORM_DIR`, sinon copie en cache rafraîchie à chaque appel).
- Variantes **Codex** `jpb-app-*` dans `jpb-platform/codex/`, installées par `sync.sh`.
- `sync.sh` installe et nettoie aussi `jpb-*` ; le hook de pré-commit vérifie le bump de
  chaque plugin séparément.

---

## [kp-agents-v4.1.0] — Codex et Cursor reconstruits (annexes) + README réaligné

### Corrigé

- **Inlining Codex / Cursor cassé** — l'ancienne génération substituait `{{ref:...}}` par le contenu brut du gabarit, **au milieu des phrases et des cellules de tableau**. Résultat sur les 20 fichiers `codex/` + `cursor/` : tableaux d'Inputs/Outputs éclatés sur 75 lignes, et le même gabarit répété jusqu'à **3×** dans un fichier (`kp-architect`, `kp-review`).
  Les 20 fichiers sont régénérés depuis la source Claude selon une convention explicite : le corps **renvoie** (`annexe « nom »`), une section `# Annexes` en fin de fichier **contient** un bloc `## Annexe — <nom>` par skill partagée et par procédure, chacun présent **une seule fois**.
- **5 gabarits jamais répliqués** (ajoutés en v3.1.0 côté Claude uniquement) : `idea`, `roadmap`, `ux`, `ui`, `design-system` sont désormais présents dans les 7 rôles qui déclarent `kp-doc-templates`, sur les 3 cibles.
- **`kp-doc-templates` ne fuit plus vers `kp-setup` et `kp-test`** : la v3.1.0 l'avait retiré de leurs compétences, mais il restait tiré transitivement par une mention de passage dans `kp-sources-config`. `kp-test` passe de 1474 à 864 lignes, `kp-setup` de 1990 à 1805.
- **README — section « Configuration projet »** : documentait encore `.kp-agents.yml` / `.kp-agents.local.yml`, format **plus lu depuis la v2.0.0**. Réécrite sur le format en vigueur (frontmatter `kp-agents:` des `docs/*.md` + variantes `.local.md`), avec le tableau des clés par fichier et la note de migration.

### Ajouté

- **Convention d'inlining** documentée dans `CLAUDE.md` et `AGENTS.md` : table de correspondance des renvois Claude → Codex/Cursor, et la règle « le corps renvoie, l'annexe contient ».
- `.gitignore` : `docs/*.local.md`.

---

## [kp-agents-v4.0.0] — Retour au modèle 100 % skills (BREAKING)

⚠️ **BREAKING (Claude)** — Les **subagents introduits en v3.0.0 sont supprimés**. Côté Claude Code, chaque rôle redevient une **skill** invocable `/kp-agents:kp-<role>` (comme en v2.x). `@agent-kp-agents:kp-<role>` ne fonctionne plus.

La refonte « dossiers plats par outil » est conservée : toujours pas de génération ni de templating, `claude/` / `codex/` / `cursor/` restent les 3 sources écrites à plat. Seul le modèle Claude change.

**Arbitrage retenu** — un seul critère pour placer un contenu :

| Contenu | Où il vit | Chargement |
|---|---|---|
| Transverse à plusieurs rôles | skill partagée `claude/skills/kp-<nom>/` | outil `Skill` |
| Propre à un seul rôle | `claude/skills/kp-<role>/references/<proc>.md` | `Read` |

Les 17 skills « spécifiques » de la v3 ne servaient chacune qu'à un seul rôle : elles polluaient le namespace `/kp-agents:` sans rien dé-dupliquer. Elles redeviennent des `references/`.

### Supprimé

- **`claude/agents/`** (10 subagents) et le champ `agents[]` de `.claude-plugin/plugin.json`.
- **17 skills spécifiques** promues à tort en v3.0.0, repliées en `references/` de leur rôle :
  - `kp-setup-*` (8) → `claude/skills/kp-setup/references/setup-*.md`
  - `kp-test-*` (7) → `claude/skills/kp-test/references/kp-test-*.md`
  - `kp-doc-index` → `claude/skills/kp-documentation/references/doc-index-management.md`
  - `kp-uxui-dev-specs` → `claude/skills/kp-ux-ui/references/uxui-dev-specs.md`

### Ajouté

- **10 skills de rôle** `claude/skills/kp-<role>/SKILL.md` — corps dédupliqué hérité des subagents v3, frontmatter `name` + `description` **orientée déclenchement** (celle déjà utilisée par Cursor et Codex, bien plus riche que le `short_description` servi aux skills jusqu'en v2.4.0).

### Conservé

- **5 skills partagées** : `kp-sources-config`, `kp-docs-structure`, `kp-handoff`, `kp-doc-templates`, `kp-validation-criteres` (developer ↔ review) — c'est là que vit la dé-duplication réelle (les gabarits étaient copiés 9× par `sync.sh` jusqu'en v2.4.0).
- `codex/` et `cursor/` inchangés : monolithiques par rôle, tout inliné.
- `sync.sh` (copie seule), hook de pré-commit, manifeste racine, versioning manuel.

### Modifié

- Section « Compétences » des 10 rôles : distingue explicitement **skills transverses** (outil `Skill`) et **procédures locales** (`references/`, via `Read`).
- Tournures cassées héritées de la génération v2 corrigées (« Utilise le template charge la skill `kp-doc-templates` » → « Utilise le gabarit fourni par la skill `kp-doc-templates` »).
- Tous les `@agent-kp-agents:kp-<role>` → `/kp-agents:kp-<role>` (skills, gabarits, bloc de handoff, docs).
- `.githooks/pre-commit` : ne surveille plus `claude/agents/`.
- `plugin.json` : version `3.1.1` → `4.0.0`.
- `CLAUDE.md`, `AGENTS.md`, `README.md`, `docs/agents.md` mis à jour.

---

## [kp-agents-v3.1.1] — fix packaging : le repo est aussi un plugin uploadable

Le dépôt n'exposait `plugin.json` que dans `claude/` ; un téléversement direct du repo échouait avec `Invalid plugin: missing .claude-plugin/plugin.json` (l'uploader attend le manifeste à la racine).

### Corrigé

- **Manifeste plugin déplacé à la racine** : `.claude-plugin/plugin.json` (source de version unique), avec champs de chemins `agents[]` (liste des 10 fichiers `./claude/agents/*.md`) et `skills[]` (`./claude/skills/`). Le contenu reste dans `claude/` ; `codex/` et `cursor/` ne sont pas référencés → exclus du plugin.
- **`marketplace.json`** : `source` `./claude` → `./` (le repo entier est le plugin auto-référencé).
- **Supprimé** `claude/.claude-plugin/plugin.json` (évite la double source de version).
- **Hook de pré-commit** : lit la version depuis `.claude-plugin/plugin.json` (racine).
- Docs (CLAUDE.md, AGENTS.md, README.md) mises à jour : emplacement du manifeste, source `./`, note « ajouter le nouvel agent à `agents[]` ».

> Le champ `agents` du manifeste exige une **liste de fichiers** (pas un dossier) — chaque nouvel agent doit y être ajouté.

---

## [kp-agents-v3.1.0] — Audit cohérence agents/skills : templates manquants + skill partagée

Suite à un audit de cohérence agents↔skills (câblage sain, 0 skill orpheline) : comblement des trous de couverture et nettoyage.

### Ajouté

- **Skill `kp-validation-criteres`** — format de la section `## Validation par critère` (critère → implémentation + preuve + limites, statuts ✅/⚠️/❌). Partagée entre `kp-developer` (rédaction) et `kp-review` (vérification) ; l'exemple jadis inliné dans `kp-developer` y est centralisé.
- **5 gabarits dans `kp-doc-templates`** : `idea-template` (`docs/ideas/`), `roadmap-template` (`docs/project/roadmap.md`), `ux-template` / `ui-template` (`docs/features/<group>/`), `design-system-template` (`docs/design-system.md`) — documents jusque-là produits sans gabarit (brainstorm, product, ux-ui).

### Modifié

- `kp-doc-templates` couvre désormais l'ensemble des documents structurants ; description et table mises à jour.
- Nettoyage de cohérence : `kp-doc-templates` retiré des Compétences de `kp-test` et `kp-setup` (qui ne l'utilisent pas) ; blurb reformulé chez les autres agents.
- `kp-developer` / `kp-review` : référencent la skill `kp-validation-criteres`.
- `plugin.json` : version `3.0.0` → `3.1.0`.

---

## [kp-agents-v3.0.0] — Modèle agents / skills (Claude) + dossiers plats (BREAKING)

⚠️ **BREAKING (Claude)** — Côté Claude Code, chaque rôle devient un **subagent** (`claude/agents/kp-<role>.md`) au lieu d'un skill. L'invocation change : auto-délégation sur la `description`, ou `@agent-kp-agents:kp-<role>` — **les anciens `/kp-agents:kp-<role>` ne s'appliquent plus aux rôles**.

Découpage **contexte/méthode** (agents) ↔ **actions** (skills). Les blocs jadis dupliqués dans les 10 agents sont extraits en **skills partagées** ; les procédures spécifiques deviennent des **skills d'action**. Périmètre : `claude/` uniquement — `codex/` et `cursor/` restent monolithiques par rôle (réplication à venir).

### Ajouté

- **10 subagents** `claude/agents/kp-<role>.md` : persona + méthode + bonnes pratiques + section « Compétences (skills) ». Auto-délégation via `description`, accès aux skills via l'outil `Skill`.
- **21 skills** `claude/skills/` :
  - **Partagées (4)** : `kp-sources-config`, `kp-docs-structure`, `kp-handoff`, `kp-doc-templates` (dé-duplication des blocs communs aux 10 agents).
  - **Spécifiques** : `kp-test-*` (7), `kp-setup-*` (8), `kp-doc-index`, `kp-uxui-dev-specs`.
- Le hook de pré-commit couvre désormais aussi `claude/agents/`.

### Modifié

- `plugin.json` : version `2.4.0` → `3.0.0`.
- `CLAUDE.md`, `AGENTS.md`, `README.md`, `docs/agents.md` : modèle agents/skills + nouvelle invocation Claude.
- Nettoyage : retrait d'un gotcha obsolète (références `plugins/`/`dist/`/`agents/`) hérité de l'ancienne architecture.

### Inclus dans cette release — Refonte « dossiers plats par outil »

Suppression de la mécanique de génération/templating. Chaque outil a désormais son dossier dédié, au format attendu, avec le contenu **écrit à plat et dupliqué**. Les skills sont **identiques** à ceux générés précédemment (aucun changement de contenu → version inchangée).

### Modifié

- **Architecture** : `agents/` + `includes/` + génération `sync.sh` → 3 dossiers plats `claude/`, `codex/`, `cursor/`. Plus de `{{include}}` / `{{ref}}`, plus de `dist/`.
- **`claude/`** remplace `plugins/kp-agents/` (via `git mv`). `.claude-plugin/marketplace.json` pointe désormais sur `./claude` (transparent pour les utilisateurs au prochain `marketplace update`).
- **`sync.sh`** réduit à une simple installation locale : copie `cursor/` → `~/.cursor/rules` et `codex/` → `~/.codex/skills`, et câble le hook de pré-commit. Flags réduits à `--clean` et `-h`.
- **Versioning manuel** : retrait de l'auto-bump, du hash de contenu (`_contentHash`, `_lastAutoVersion`) et des flags `--minor` / `--major`.

### Ajouté

- **`.githooks/pre-commit`** — bloque un commit qui modifie un skill (`claude/skills/`, `codex/`, `cursor/`) sans bump de `version` dans `plugin.json`. Activé via `git config core.hooksPath .githooks` (câblé par `sync.sh`).

### Supprimé

- `agents/`, `includes/`, `dist/`, `.installed-agents`, et toute la logique de génération/résolution d'includes/refs et d'auto-bump dans `sync.sh`.

---

## [kp-agents-v2.4.0] — 2026-06-10 (kp-test — routine E2E validée terrain)

Aligne l'agent `kp-test` sur la routine de migration E2E éprouvée (Cypress → Playwright natif sur keyprod).

### Ajouté

- **Include `kp-test-dashboard`** — contrat de `progress_tracker` (suivi de progression par cas) : pipeline 5 états (À faire → Définition → En cours → À valider → Terminé), CLI de mutation unique + hook auto, chorégraphie de l'agent, workflow par lot. Référencé en transverse depuis `kp-test.md`.
- **Validation visuelle humaine** comme verrou du critère 5 : run en mode UI + « oui » explicite de l'utilisateur avant de clore un cas (jamais d'auto-validation).
- **Garde de visibilité anti-faux-vert** (`kp-test-implementation`) : asserter que les données seedées sont réellement visibles avant le comportement (évite le faux-vert sur liste vide), + restriction des assertions de tri aux lignes seedées.
- **Section visibilité / scopes multi-tenant** et **seeder FK-safe** dans `kp-test-data-isolation`.

### Modifié

- **Critère 6 (remontée Xray) rendu non bloquant** — phase CI/P3. La validation locale = critères 1→5 verts (dont validation humaine).
- **kp-test peut désormais écrire les seeders dédiés test** (sous `isolation.test_seed_namespace`) — règles dures #1/#2 et frontières `kp-developer` mises à jour. Le handoff developer ne concerne plus que les structures applicatives (modèle/colonne/migration/flag).
- **Modèle d'isolation** : ajout de la stratégie « seeder nommé + fixture `seed(SeederClass, folder)` » (Rollback→Seeder / teardown Rollback) à côté du `beforeEach`/`ref` unique.

## [kp-agents-v2.0.0] — 2026-05-12 (BREAKING — convention `docs/` self-documenting)

⚠️ **BREAKING CHANGE** — La configuration projet quitte le YAML (`.kp-agents.yml`, `.kp-agents.local.yml`) et migre vers du **markdown self-documenting** dans `docs/`. L'objectif : un projet kp-agents devient **lisible et exploitable par n'importe quel agent IA** (kp-agents, superpower, codex, cursor, ou autre), pas seulement les agents kp.

### Ajouté

- **Convention `docs/` self-documenting** — 8 fichiers structurants à la racine de `docs/` :
  - `guidelines.md` (commité, statique) — convention de la documentation pour tout agent IA
  - `git.md` / `git.local.md` — politique git du projet / préférences personnelles du dev
  - `project.md` / `project.local.md` — suivi projet, tickets, mapping JIRA / overrides personnels
  - `documentation.md` / `documentation.local.md` — sources de doc externes / chemins absolus machine-spécifiques
  - `index.md` (renommé depuis `INDEX.md`) — index navigable, maintenu par l'agent `documentation`
- **Frontmatter YAML namespacé `kp-agents:`** — chaque fichier `*.md` structurant porte sa configuration machine-lisible dans un frontmatter standard markdown (entre `---` en tête). Parsing déterministe pour tout agent IA, prose humaine dans le body.
- **Sections gérées dans `CLAUDE.md`** — l'agent `setup` injecte et maintient 4 sections canoniques (`## Documentation`, `## Projet & Tickets`, `## Git`, `## Apps`) qui pointent vers les fichiers `docs/` structurants. Matching strict + fuzzy (avec confirmation si titre renommé).
- **Détection monorepo** — `apps/`, `packages/`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `Cargo.toml [workspace]`, `package.json :: workspaces`. Bootstrap de `apps/<name>/docs/index.md` par app + section `## Apps` dans CLAUDE.md racine + entrée dans `docs/index.md`.
- **Migration automatique v1.x → v2.0.0** — au prochain `/kp-agents:setup`, si `.kp-agents.yml` ou `.kp-agents.local.yml` détecté, setup propose la conversion intégrale vers les MD canoniques (avec confirmation à chaque étape, atomicité totale).
- **Refonte de l'agent `setup`** en orchestrateur 5 dimensions : `guidelines`, `git`, `tickets`, `documentation` (fusion product + global_doc), `monorepo`, plus la maintenance `claudemd` en fin de flow.
- **8 templates de fichiers structurants** (`includes/template-*.md`) — chargés à la demande lors du bootstrap d'un fichier vide. Cohérence garantie entre projets.

### Modifié

- **Auto-bump majeur** : v1.x → v2.0.0 (breaking change sur le format de configuration).
- **Renaming `INDEX.md` → `index.md`** dans toute la convention. Le rename est non-destructif : si un projet a un `INDEX.md` existant, `setup` propose la migration sans écraser silencieusement.
- **`git.auto_commit` et `git.auto_push` déplacés** du YAML commité (v1.x) vers `docs/git.local.md` gitignored (v2.0.0). C'est intentionnel : ce sont des préférences **personnelles du dev**, pas une politique projet imposée à toute l'équipe.
- **Les 7 autres agents** (`architect`, `brainstorm`, `developer`, `documentation`, `product`, `review`, `ux-ui`) lisent désormais leur config depuis les frontmatter MD au lieu des YAML.
- **Include `docs-structure`** : nouvelle hiérarchie documentée, plus de section "Documents structurants" + section "Apps" (monorepo) + section "Configuration machine-lisible (frontmatter)".
- **Include `doc-index-management`** : `index.md` lowercase + nouvelles sections "Documents structurants `docs/`" et "Apps (monorepo)".
- **Includes `sources-config-base`, `sources-config-git`, `sources-config-tickets`** : lecture frontmatter MD au lieu de YAML. Migration `git.auto_*` documentée.

### Supprimé

- `includes/setup-product.md` et `includes/setup-global-doc.md` — fusionnés dans `includes/setup-documentation.md`.
- Plus de lecture de `.kp-agents.yml` / `.kp-agents.local.yml` par les agents en runtime. Setup ne les lit qu'au moment de la migration.
- `docs/kp-agents-config.md` (généré en v1.x) — supprimé après migration, ses informations sont absorbées par les nouveaux MD canoniques.

### Corrigé

- **`sync.sh` — escape de `&` et `\` dans les remplacements `${var//pat/repl}`** : bash 5.3+ traite désormais `&` dans le replacement comme un backref (le pattern matché), ce qui causait des boucles infinies lors de la résolution des `{{include:}}` / `{{ref:}}` si le contenu remplacé contenait `&` (ex: titre "Projet & Tickets"). Ordre d'escape : `\` d'abord, puis `&`. Sans ce fix, le contenu inliné réintroduisait le pattern et la boucle while ne terminait jamais.

### Notes

- **Guide de migration pour les utilisateurs v1.x** : la migration est automatique. Lance `/kp-agents:setup` dans ton projet, setup détecte les `.kp-agents.yml` / `.kp-agents.local.yml`, propose le plan de migration, et bascule tout vers `docs/*.md` après confirmation. Les anciens fichiers sont conservés jusqu'à confirmation explicite de suppression.
- **Compatibilité externe** — la convention `docs/guidelines.md` documente la structure de façon agnostique. Tout agent IA (superpower, codex, cursor) lisant `CLAUDE.md` y trouvera les pointeurs vers `docs/index.md` et `docs/guidelines.md`, et pourra travailler le projet selon les mêmes conventions sans connaître kp-agents.
- **Pourquoi pas de fichiers YAML séparés** : on évite la duplication YAML + MD. Le MD avec frontmatter est markdown standard (Jekyll, Hugo, Astro, MDX, Obsidian, Anthropic skills…) — parseable déterministiquement par tout LLM, lisible par humain, pas de drift possible entre deux sources.
- **Aucun changement de comportement** runtime sur les autres agents — ils lisent au même endroit logique, juste depuis un fichier différent.

---

## [kp-agents-v1.1.0] — 2026-04-22 (epic E-0004 terminée)

Externalisation des sources de documentation produit (OneDrive) et des tickets (JIRA via MCP), avec un 8ème agent `setup` dédié à la configuration projet. **Rétro-compatibilité 100%** : un projet sans `.kp-agents.yml` se comporte exactement comme avant.

### Ajouté

- **Agent `setup`** (`/kp-agents:setup`) : configure les sources du projet (`product.mode`, `tickets.mode`), les préférences Git et la matrice de mapping JIRA. Audit-first, non-destructif — annonce avant d'écrire, demande confirmation. Seul agent autorisé à écrire `.kp-agents.yml` / `.kp-agents.local.yml`.
- **Fichiers de config projet** (S-0001) :
  - `.kp-agents.yml` commité — politique de sources, mapping tickets, préférences git partagées.
  - `.kp-agents.local.yml` gitignoré — chemins machine-spécifiques (OneDrive) et override local (projet JIRA personnel).
- **Include partagé `sources-config`** — injecté dans les 8 agents par `sync.sh`. Centralise la logique de lecture config, résolution de chemin, fallback write, protocole d'erreur MCP.
- **Mode `product.mode: external`** (S-0004) : doc produit sur OneDrive (ou tout chemin filesystem). 4 outputs redirigeables (`product.md`, `ideas/*.md`, `features/<g>/product.md`, `roadmap.md`). Fallback local avec warn standardisé en cas d'échec.
- **Mode `product.access: read-only`** (S-0009) : doc produit externe en lecture seule. Agents `product` et `brainstorm` rendent le contenu en chat au format 🔒 au lieu d'écrire. Cas d'usage : OneDrive partagé maintenu par un PM humain.
- **Mode `tickets.mode: mcp`** (S-0006) : epics et stories dans JIRA via MCP. Pipeline d'écriture/lecture/update documenté, frontmatter YAML encodé en labels, `description` = body markdown uniquement. Support du champ `parent` natif pour la hiérarchie epic → story. Protocole d'erreur MCP en 3 options (retry / bascule locale ponctuelle / annuler).
- **Schéma `tickets.mapping`** : configurable par projet (issue types, status workflow, préfixe summary, labels systématiques, label patterns, custom fields, placement section Review). Override local du `project_key` via `.kp-agents.local.yml` (deep merge champ par champ).
- **Préférences Git `git:`** (S-0007) : `branch_pattern` (template de nommage de branches), `auto_commit` (yes/no/ask), `auto_push` (yes/no/ask). Défauts : `ask` pour commit, `no` pour push, pas de pattern imposé — comportement actuel préservé en l'absence de config.
- **Spike JIRA mapping** (S-0005) : `docs/project/epics/E-0004-Sources-Externalisation/spike-jira-mapping.md` documente la faisabilité (GO partiel), le schéma de mapping, les défauts setup et les 6 ajustements intégrés à S-0006.

### Modifié

- **7 agents existants** (S-0003) intégrent l'include `sources-config` et la section `## Configuration du projet` adaptée à leur périmètre :
  - `product`, `brainstorm`, `ux-ui` : lisent la doc produit externe si configurée. `product` et `brainstorm` respectent `read-only`.
  - `architect` : écritures **toujours locales** (périmètre technique).
  - `developer`, `review` : epics/stories suivent `tickets.mode` (local ou MCP). Respectent les préférences `git:`.
  - `documentation` : `INDEX.md`, README, CLAUDE.md, architect.md **toujours locaux** (index du repo code).
- **Auto-redirect vers `/kp-agents:setup`** : tout agent détectant une config manquante ou incomplète propose l'invocation setup sans bloquer l'utilisateur.
- **CLAUDE.md** : workflow diagram enrichi (setup + dotted arrows `config manquante`), tableau des agents à 8 entrées.
- **Plugin manifest** (`plugins/kp-agents/.claude-plugin/plugin.json`) et **marketplace** (`.claude-plugin/marketplace.json`) : description listant les 8 agents.

### Notes

- **Non-régression absolue** garantie par construction : chaque ajout est conditionnel à la présence d'une clé dans `.kp-agents.yml`. Un projet existant (ex: `kp-agents` lui-même) continue de fonctionner sans friction.
- **Guide de migration pour les utilisateurs v1.0.x** : rien à faire. Si tu veux activer l'externalisation, invoque `/kp-agents:setup` dans ton projet.
- **Tailles SKILL.md** : les 8 agents grossissent de ~150-200 lignes chacun (include `sources-config` inliné). Plus gros agent : `developer` à 635 lignes. Acceptable, pas de saturation observée.
- **Dépendances** : MCP Atlassian à configurer dans les `settings.json` Claude Code pour activer `tickets.mode: mcp`. L'agent `setup` référence le MCP mais ne le configure pas lui-même.

---

## [kp-agents-v0.3.0] — à venir (épic E-0002 terminée)

Introduction de l'auto-bump de version du plugin `kp-agents` — le composant `patch` est désormais incrémenté automatiquement à chaque modification du contenu des skills, sans action manuelle du contributeur.

### Ajouté

- **Auto-bump patch** (S-0001) : `sync.sh` calcule un hash SHA256 stable sur `plugins/kp-agents/skills/**/SKILL.md` et incrémente le composant `patch` de la version si le hash a changé depuis le précédent sync.
- **Champs custom `_contentHash` et `_lastAutoVersion`** dans `plugin.json` (préfixés `_`, acceptés par `claude plugin validate`). Servent respectivement à détecter les changements de contenu et à repérer les bumps manuels.
- **Flags `--minor` et `--major`** (S-0002) : bump explicite des composantes semver supérieures avec reset des composantes inférieures (ex: `0.3.5 --minor` → `0.4.0`). Flags mutuellement exclusifs, incompatibles avec `--clean` / `--clean-all`.
- **Détection du bump manuel** (S-0002) : un édit direct de `version` dans `plugin.json` est respecté — `sync.sh` ne re-bumpe jamais par-dessus une saisie humaine.
- **ADR-005** (S-0003) : `docs/architect.md` documente la décision, les 5 alternatives rejetées et les conséquences. ADR-004 (versioning manuel) passée en `deprecated`.
- **Section Troubleshooting versioning** (S-0003) dans `README.md` : 3 cas couverts (version ne bouge pas, conflit merge Git sur `plugin.json`, rollback d'une release).

### Modifié

- `README.md` et `CLAUDE.md` : l'étape de bump manuel dans "Publier une mise à jour" a été remplacée par une description du bump automatique + des flags `--minor`/`--major`.
- `CLAUDE.md` : tableau "Flags disponibles" enrichi de `--minor` et `--major` avec règles d'exclusivité.

### Notes

- Aucun changement breaking pour les consommateurs du plugin (le flow d'installation et d'utilisation reste identique).
- Pour les contributeurs : l'étape "bumper `plugin.json` à la main" disparaît du workflow standard. Elle reste possible en cas de besoin explicite (et est respectée par le mécanisme).
- Dépendances : `shasum` (ou fallback `openssl`) + `python3` — tous standard macOS/Linux.

---

## [kp-agents-v0.2.0] — 2026-04-18

Optimisation transverse des 7 agents selon les best practices agentskills.io, clôture de l'epic **E-0003 Optimisation-Agents-Best-Practices**.

### Cohérence (S-0001, S-0003)

- **Bloc Activation factorisé** dans `includes/activation.md` et inclus via `{{include:activation}}` dans les 7 agents — suppression de la duplication mot-à-mot.
- **Include `includes/dependency-versions.md`** créé et inclus dans `architect`, `developer`, `review` (seuls agents qui installent / mettent à jour des dépendances).
- **Section `## Gotchas`** ajoutée à chaque agent, placée **avant** `## Règles`. 4 items communs factorisés dans `includes/gotchas-transverses.md` (`plugins/` + `dist/` générés, INDEX.md propriété de documentation, numérotation locale des stories, archives en lecture seule) + 4 à 6 items spécifiques par agent.

### Descriptions (S-0002)

- **Toutes les descriptions `description:` du frontmatter réécrites** en impératif : "Use this skill when…" + verbes déclencheurs + cas de non-usage explicite. Longueur < 530 caractères par description (bien sous la limite Claude 1024).
- Objectif : améliorer le trigger matching côté Claude Code (skill selection) sans rupture fonctionnelle.

### Refactoring (S-0004, S-0005, S-0006)

- **product** : document raccourci (243 → 127 lignes). Mode `init` déplacé en étape 1, 3 templates inline remplacés par des `{{include:*-template}}`, exemples de calibrage extraits dans leur propre section.
- **developer** : étapes 6 (Bilan) + 7 (Mise à jour doc) fusionnées en `### 6. Bilan et relais documentaire` (7 sous-points numérotés couvrant testable → mise à jour epic). Étape 5 (Simplification) rendue portable multi-cibles (`/simplify` Claude Code / équivalent Cursor / Codex / passe manuelle). Ajout d'un exemple pédagogique `## Validation par critère` (✅ bon / ❌ trop vague).
- **brainstorm** : « Choix de méthode » simplifié en 1 défaut explicite (**Starbursting**) + 2 alternatives contextuelles, autres méthodes sur demande. `STOP` ajouté à l'étape 4.
- **architect** : « Processus » et « Format recommandé » fusionnés en une checklist unique à 9 points. 4 règles génériques élaguées.
- **review** : étape « Revue automatisée » condensée de 17 → 4 lignes ; 7 règles → 4, déduplication avec les Gotchas.
- **documentation** : bloc « Format de l'index » (52 lignes) extrait en `includes/index-template.md`. 12 règles → 6 (déduplication avec le processus et les Gotchas).
- **ux-ui** : mini-template de specs Developer ajouté (tokens CSS custom properties + états de composant + breakpoints). Slogan « belle mais confuse » remplacé par une consigne actionnable (hésitation > 2s).

### Outillage (S-0007)

- Structure d'évaluation mise en place dans `agents/_evals/` (mainteneurs uniquement, **ignorée par `sync.sh`**) pour les 2 agents pilotes **developer** et **review**.
- Chaque agent pilote a :
  - `trigger_queries.json` : 20 prompts annotés (10 positifs + 10 négatifs avec `reason` de near-miss), ~30 % EN / 70 % FR.
  - `output_evals.json` : 3 cas de bout en bout avec assertions objectives (`file_contains`, `frontmatter_field_equals`, `section_order`, `file_absent`, `git_files_unchanged`, `response_contains_any`).
- `agents/_evals/README.md` documente le protocole et le format prévu pour un futur `benchmark.json`.
- Exécution des evals hors périmètre de cette release — structure en place, exécution à planifier.

### Notes

- Aucun changement breaking. Les utilisateurs installés en v0.1.0 reçoivent la v0.2.0 via `/plugin marketplace update` + `/plugin install kp-agents@kp-agents`.
- Gain de lisibilité mesurable : les 7 sources `agents/*.md` perdent ~400 lignes cumulées (extraction d'includes + dédoublonnage), aucun contenu fonctionnel supprimé.

---

## [kp-agents-v0.1.0] — 2026-04-17

Première release officielle du plugin `kp-agents`, distribué via la marketplace Claude Code `kp-agents` (hébergée sur GitHub `KeyProd/kp-agents`).

### Ajouté

- Plugin `kp-agents` au format Claude Code natif : 7 skills (`brainstorm`, `product`, `architect`, `developer`, `review`, `documentation`, `ux-ui`) dans `plugins/kp-agents/skills/`
- Marketplace catalogue `.claude-plugin/marketplace.json` à la racine du repo, distribué via GitHub
- Namespaces d'invocation : `/kp-agents:brainstorm`, `/kp-agents:product`, etc. (7 commandes)
- Nouvelle section `Troubleshooting` dans `README.md` documentant :
  - Purge du cache plugin en cas d'anomalie `0 skills`
  - Migration des anciens `/kp-brainstorm` vers `/kp-agents:brainstorm`
  - Installation depuis une branche feature
- `docs/product.md` — vision produit, personas, KPIs
- `docs/architect.md` — architecture complète avec 4 ADR et diagrammes Mermaid
- `docs/project/roadmap.md` — Phase 1 (migration plugin) + Phase 2 (ouverture publique)
- Epic `E-0001 Plugin-Marketplace` avec 3 stories (S-0001, S-0002, S-0003)

### Modifié

- **Plugin renommé** : `kp-core` → `kp-agents` pour aligner le nom du plugin sur celui de la marketplace et du projet
- `sync.sh` refactoré :
  - Retrait complet de la génération et installation vers `~/.claude/commands/` (fonctions `generate_claude*` supprimées)
  - Nouvelle fonction `generate_plugin` produisant `plugins/kp-agents/skills/<name>/SKILL.md` avec frontmatter Claude plugin minimal
  - Nouvelle fonction `cleanup_legacy_claude` idempotente qui purge les résidus d'installations Claude locales antérieures
  - Flags `--clean` et `--clean-all` adaptés : préservent `plugin.json` (statique) mais purgent `plugins/kp-agents/skills/`
  - Messages d'aide (`--help`) et logs finaux mis à jour
- Documentation entièrement réalignée sur l'architecture plugin marketplace :
  - `README.md` : installation scindée entre plugin Claude et `sync.sh` (Cursor/Codex), suppression section RecetteMoi
  - `CLAUDE.md` : section Distribution, structure du projet, workflow inter-agents avec namespaces `/kp-agents:<nom>`
  - `docs/agents.md` : retrait complet de la section Pipeline RecetteMoi, namespaces mis à jour dans 8 diagrammes Mermaid

### Supprimé

- **Agents RecetteMoi** (`recettemoi-support`, `recettemoi-dev`, `recettemoi-review`) — hors périmètre du plugin
- Plugin temporaire `kp-agents-spike` (anciennement `kp-core-spike`) utilisé pour le spike de faisabilité
- Cible d'installation Claude locale dans `sync.sh` et `dist/claude/` (désormais distribué via plugin marketplace)

### Architecture

Migration achevée vers une architecture marketplace + plugin natif :
- **Claude Code** : `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
- **Cursor** : `./sync.sh` installe les règles dans `~/.cursor/rules/`
- **Codex** : `./sync.sh` installe les skills dans `~/.codex/skills/`

Source unique : `agents/*.md` avec directives `{{include:xxx}}` résolues par `sync.sh`.

### Notes de migration pour utilisateurs existants

Si tu avais installé kp-agents avec une version antérieure de `sync.sh` :

1. Lance `./sync.sh` une fois — les anciens `~/.claude/commands/kp-*.md` seront automatiquement purgés (cleanup idempotent)
2. Installe le plugin via `/plugin marketplace add KeyProd/kp-agents` + `/plugin install kp-agents@kp-agents`
3. Les anciens noms `/kp-brainstorm` deviennent `/kp-agents:brainstorm` (namespace imposé par Claude Code)

Si tu avais installé le spike `kp-agents-spike` :

1. `/plugin uninstall kp-agents-spike@kp-agents`
2. `/plugin marketplace update kp-agents`
3. `/plugin install kp-agents@kp-agents`
