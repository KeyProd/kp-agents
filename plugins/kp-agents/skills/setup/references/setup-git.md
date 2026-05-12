## Configuration de la dimension `git`

Cette dimension règle les préférences appliquées par `developer` et `review` : nommage de branches (projet), commit auto, push auto (dev local). Elle écrit dans **deux fichiers** :

- `docs/git.md` (commité) — politique projet (branch_pattern)
- `docs/git.local.md` (gitignored) — préférences personnelles du dev (auto_commit, auto_push)

### Questions à poser (groupées)

1. **Convention de nommage de branches ?** Laisse vide pour que l'agent demande à chaque fois (comportement actuel). Exemples de patterns : `feat/{slug}`, `feature/KP-{ticket}-{slug}`. Placeholders supportés : `{slug}`, `{ticket}`, `{epic}`.

2. **Commit automatique par l'agent ?**
   - `ask` (défaut) — demande avant chaque commit
   - `yes` — commit sans demander
   - `no` — ne commit jamais, annonce et laisse la main

3. **Push automatique par l'agent ?**
   - `ask`
   - `yes`
   - `no` (défaut — push reste une décision explicite)

### Validation

Avant écriture du `branch_pattern` :
- Parser et vérifier qu'il n'y a pas d'accolade non fermée.
- Placeholders inconnus → warn mais accepter.
- Pattern vide → ne pas écrire le champ (ou l'écrire comme `""`).

### Écriture dans `docs/git.md` (frontmatter)

```markdown
---
kp-agents:
  branch_pattern: "feat/{slug}"
---
```

Si le fichier existe déjà avec un body humain (conventions de commits, PR, etc.) : **préserver le body**. Ne modifier que le frontmatter. Si le fichier n'existe pas, bootstrap depuis ``references/template-git.md`` puis adapter le frontmatter.

### Écriture dans `docs/git.local.md` (frontmatter)

```markdown
---
kp-agents:
  auto_commit: ask
  auto_push: no
---
```

Si le fichier n'existe pas, bootstrap depuis ``references/template-git-local.md``. Vérifier que `docs/git.local.md` figure dans `.gitignore` (pattern `docs/*.local.md` accepté).

### Cas limites

- **`git.auto_commit: yes` ou `auto_push: yes`** → rappeler à l'utilisateur que cela **n'autorise jamais** le skip de hooks / signature GPG / autres bypass — c'est un raccourci pour sauter la confirmation, pas pour désactiver les règles de sécurité globales (voir `CLAUDE.md`).
- **`git.branch_pattern` modifié en cours de projet** → les branches déjà créées ne sont pas renommées rétroactivement. Prévenir que le nouveau pattern s'applique uniquement aux prochaines branches créées par `developer`.
- **`docs/git.md` édité manuellement par l'équipe** (conventions de commits ajoutées dans le body) → afficher un diff frontmatter avant écrasement et **préserver intégralement le body** lors de la mise à jour.
- **Aucune des 3 questions répondue** → ne pas écrire les fichiers. Si l'utilisateur veut juste documenter ses conventions sans config machine, créer `docs/git.md` avec un frontmatter `kp-agents: { branch_pattern: "" }` minimal pour signaler que le fichier a été initialisé.
