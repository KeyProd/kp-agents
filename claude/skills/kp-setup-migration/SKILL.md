---
name: "kp-setup-migration"
description: "Migration de la config legacy .kp-agents.yml / .kp-agents.local.yml (v1.x) vers la convention docs/ self-documenting (v2.0.0)."
---

## Migration v1.x → v2.0.0 (YAML → MD)

Avant v2.0.0, la configuration vivait dans `.kp-agents.yml` (commité) et `.kp-agents.local.yml` (gitignored). Depuis v2.0.0, elle est en **frontmatter YAML** dans `docs/*.md`. Cette ref pilote la migration automatique des projets existants.

### Détection

Au début de chaque audit, setup vérifie la présence de :

- `.kp-agents.yml` à la racine du projet → **migration nécessaire**
- `.kp-agents.local.yml` à la racine → **migration nécessaire**
- `docs/kp-agents-config.md` à la racine → **fichier déprécié à supprimer après migration**

Si **aucun** de ces fichiers n'existe → projet déjà en v2.0.0 ou jamais configuré, pas de migration.

### Annonce à l'utilisateur

Si migration détectée, annoncer **avant toute autre action** :

> 🔄 **Migration v1.x → v2.0.0 détectée**
>
> J'ai trouvé `.kp-agents.yml` (et/ou `.kp-agents.local.yml`) à la racine. Depuis v2.0.0, la configuration vit en frontmatter dans `docs/*.md` (lisible par tout agent IA, pas seulement kp-agents).
>
> **Plan de migration** :
> 1. Lire le contenu de `.kp-agents.yml` (politique projet) et `.kp-agents.local.yml` (chemins locaux)
> 2. Répartir dans : `docs/git.md`, `docs/project.md`, `docs/documentation.md` (commités) + `docs/git.local.md`, `docs/project.local.md`, `docs/documentation.local.md` (gitignored)
> 3. Bootstrap `docs/guidelines.md` (convention pour tout agent)
> 4. Mettre à jour `CLAUDE.md` avec les sections canoniques (`## Documentation`, `## Projet & Tickets`, `## Git`, et `## Apps` si monorepo)
> 5. Mettre à jour `.gitignore` (entrée `docs/*.local.md`)
> 6. Supprimer `.kp-agents.yml`, `.kp-agents.local.yml`, `docs/kp-agents-config.md` (avec confirmation)
>
> Lance-toi ? (Y/n)

**STOP** : attendre confirmation explicite.

### Mapping YAML → MD frontmatter

Tableau de conversion :

| Clé YAML v1.x | Fichier v2.0.0 | Clé frontmatter |
|---|---|---|
| `.kp-agents.yml :: product.mode` | `docs/documentation.md` | `kp-agents.product.mode` |
| `.kp-agents.yml :: product.access` | `docs/documentation.md` | `kp-agents.product.access` |
| `.kp-agents.local.yml :: product.path` | `docs/documentation.local.md` | `kp-agents.product.path` |
| `.kp-agents.local.yml :: global_doc.specs` | `docs/documentation.local.md` | `kp-agents.global_doc.specs` |
| `.kp-agents.local.yml :: global_doc.tech` | `docs/documentation.local.md` | `kp-agents.global_doc.tech` |
| `.kp-agents.local.yml :: global_doc.product_inputs` | `docs/documentation.local.md` | `kp-agents.global_doc.product_inputs` |
| `.kp-agents.yml :: tickets.*` (sauf override local) | `docs/project.md` | `kp-agents.tickets.*` |
| `.kp-agents.local.yml :: tickets.project_key` | `docs/project.local.md` | `kp-agents.tickets.project_key` |
| `.kp-agents.yml :: git.branch_pattern` | `docs/git.md` | `kp-agents.branch_pattern` |
| `.kp-agents.yml :: git.auto_commit` | `docs/git.local.md` ⚠️ | `kp-agents.auto_commit` |
| `.kp-agents.yml :: git.auto_push` | `docs/git.local.md` ⚠️ | `kp-agents.auto_push` |

⚠️ **Déplacement git** : `auto_commit` et `auto_push` étaient dans le YAML **commité** en v1.x. En v2.0.0, ils sont dans `git.local.md` **gitignored** — c'est intentionnel (préférences perso du dev, pas politique projet). Annoncer ce changement explicitement à l'utilisateur lors de la migration.

### Procédure d'écriture

1. **Lire le YAML existant** : parser `.kp-agents.yml` et `.kp-agents.local.yml`.
2. **Construire les nouveaux contenus** :
   - Pour chaque fichier cible, charger le template depuis `references/template-<nom>.md`
   - Remplacer le frontmatter du template par les valeurs extraites du YAML
   - Préserver le body humain du template
3. **Afficher le plan d'écriture** : liste des fichiers à créer/modifier, contenu de chaque frontmatter (pas le body). Demander confirmation finale.
4. **Écrire dans l'ordre** :
   - `docs/git.md`, `docs/git.local.md` (si valeurs présentes)
   - `docs/project.md`, `docs/project.local.md` (si valeurs présentes)
   - `docs/documentation.md`, `docs/documentation.local.md` (si valeurs présentes)
   - `docs/guidelines.md` (toujours, depuis le template)
   - `CLAUDE.md` (sections canoniques injectées via la procédure skill `kp-setup-claudemd`)
5. **Mettre à jour `.gitignore`** :
   - Si pattern `docs/*.local.md` absent → ajouter
   - **Conserver l'ancienne entrée** `.kp-agents.local.yml` pour rétro-compat pendant 1 release, puis nettoyer
6. **Demander avant de supprimer les anciens fichiers** :
   > Migration terminée. Veux-tu supprimer `.kp-agents.yml`, `.kp-agents.local.yml` et `docs/kp-agents-config.md` ? (Y/n)
   - **Y** → supprimer les 3 fichiers
   - **n** → les garder (recommandation : les supprimer après quelques jours de validation)

### Cas limites

- **`.kp-agents.yml` malformé** (YAML invalide) → ne pas planter. Afficher l'erreur, proposer de corriger le YAML ou de tout recréer from scratch (sans migration auto).
- **`.kp-agents.yml` présent mais vide** → considérer comme "pas de config v1" et passer en bootstrap v2 from scratch.
- **`.kp-agents.local.yml` absent alors qu'un mode externe est actif dans `.kp-agents.yml`** → migrer le yml partagé en `docs/documentation.md`, ne pas créer de `documentation.local.md`, warner que `product.path` est manquant.
- **Conflit avec un `docs/git.md` (ou autre) déjà présent** → diff, demander confirmation. Stratégie par défaut : merger le frontmatter (le YAML existant gagne), préserver le body humain existant.
- **Anciennes refs de l'ancien chemin** dans d'autres docs (ex: `README.md` qui mentionne `.kp-agents.yml`) → ne pas toucher automatiquement. Lister ces occurrences dans le récap final et suggérer un grep + update manuel.
- **Migration annulée par l'utilisateur** → ne rien écrire, ne rien supprimer. Les fichiers v1.x restent en place et les agents v2.0.0 utiliseront les défauts (mode local 100%) avec warn.
- **Migration partielle** (plantage à mi-chemin) → ne pas laisser le projet dans un état hybride. Si une écriture échoue, rollback les fichiers déjà écrits et signaler l'erreur.
