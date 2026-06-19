---
name: "kp-setup-claudemd"
description: "Écriture des sections canoniques de CLAUDE.md (Documentation, Projet & Tickets, Git, Apps) en fin de flow setup."
---

## Maintien des sections dans `CLAUDE.md`

L'agent `setup` maintient 4 sections dans le `CLAUDE.md` à la racine du projet pour que **tout agent IA** (kp-agents, superpower, autre) trouve immédiatement les pointeurs vers la documentation projet.

### Sections gérées

| Section (titre `##` exact) | Contenu | Présence |
|---|---|---|
| `## Documentation` | Pointeurs vers `docs/index.md`, `docs/guidelines.md`, `docs/documentation.md`, `docs/product.md`, `docs/architect.md` | Toujours |
| `## Projet & Tickets` | Pointeurs vers `docs/project.md`, `docs/project/roadmap.md`, `docs/project/epics/` | Toujours |
| `## Git` | Pointeurs vers `docs/git.md`, `docs/git.local.md` | Toujours |
| `## Apps` | Liste des apps détectées (monorepo) avec lien vers leur `docs/index.md` | Uniquement si workspaces détectés |

### Procédure d'injection

1. **Lis `CLAUDE.md`** s'il existe à la racine du projet. Sinon, créer.
2. **Parser les titres `##`** pour repérer la présence des 4 sections canoniques.
3. **Pour chaque section manquante** : injection en fin de fichier (après confirmation utilisateur).
4. **Pour chaque section présente** : remplacer son contenu (entre son `##` et le prochain `##` ou EOF) par le contenu canonique à jour.
5. **Préserver tout le contenu hors sections gérées** — texte avant, texte entre les sections, texte après. Setup ne touche que les blocs qu'il pilote.

### Frontière de section

Une section commence à la ligne du titre `## <Nom exact>` et se termine **juste avant** :
- le prochain titre `##` (ou `# `) rencontré, **ou**
- la fin du fichier.

Les sous-titres `###` à l'intérieur appartiennent à la section.

### Matching fuzzy (titres renommés)

Si le titre exact n'est pas trouvé mais qu'un titre proche existe (similarité de prefix + contenu reconnaissable comme pointeurs vers `docs/`), proposer à l'utilisateur :

> J'ai détecté `## Docs` qui ressemble à la section canonique `## Documentation`. Tu veux que je la renomme `## Documentation` et la maintienne ? (Y/n)
> - **Y** → renommer + remplacer le contenu par le canonique
> - **n** → ne pas toucher cette section et créer `## Documentation` en fin de fichier (l'utilisateur aura les deux et pourra cleanup)

Critères de similarité fuzzy (au moins 2 sur 3) :
- Préfixe en commun (≥ 3 caractères : `Doc`, `Pro`, `Git`)
- Contenu contient un chemin `docs/...`
- Présence de mots-clés (`documentation`, `tickets`, `branches`, `commits`)

### Contenu canonique des sections

Voir ``references/template-claudemd-sections.md`` pour les templates complets injectés.

### Cas limites

- **`CLAUDE.md` n'existe pas** → créer le fichier avec uniquement les 4 sections (ou 3 si pas monorepo). En-tête minimal : `# Instructions Claude pour <nom-projet>` (déduit du nom du dossier racine).
- **`CLAUDE.md` existe avec du contenu mais aucune des 4 sections** → afficher le plan d'injection, demander confirmation, injecter en fin de fichier.
- **Doublon détecté** (deux `## Documentation` par exemple, suite à un fuzzy match raté) → afficher le problème, proposer de fusionner manuellement ou de garder le premier et supprimer le second.
- **Section vide ou contenu minimal** dans une section existante → remplacer par le canonique sans demander (considérer comme un placeholder).
- **Section avec contenu humain riche et divergent du canonique** → afficher diff, demander confirmation. Possibilité de proposer une stratégie "append" qui ajoute le canonique en fin de section sans supprimer le contenu existant.
- **Fichier en lecture seule** → afficher une erreur claire, ne rien écrire, ne pas planter.
- **CLAUDE.md géré par un autre outil** (ex: template org-wide) → si setup détecte une section `<!-- managed by X -->` ou commentaire similaire en début de fichier, demander confirmation explicite avant tout write.

### Synchronisation avec les autres fichiers

Le contenu des 4 sections doit **toujours être cohérent** avec les fichiers réellement présents dans `docs/` :

- `## Documentation` ne pointe vers `docs/guidelines.md` que si le fichier existe
- `## Apps` n'est créé que si workspaces détectés ET au moins un `apps/<name>/docs/index.md` existe (ou si setup vient de bootstrap les apps)
- Les liens `docs/git.local.md`, `docs/project.local.md`, `docs/documentation.local.md` sont mentionnés comme "(gitignored)" pour que l'humain comprenne qu'ils peuvent manquer sur certaines machines
