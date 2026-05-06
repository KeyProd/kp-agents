## Configuration de la dimension `git`

Cette dimension règle 3 préférences appliquées par `developer` et `review` : nommage de branches, commit auto, push auto.

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
- Pattern vide → ne pas écrire le champ.

### Écriture dans `.kp-agents.yml`

```yaml
git:
  branch_pattern: "feat/{slug}"     # uniquement si non vide
  auto_commit: ask | yes | no
  auto_push: ask | yes | no
```

Si une seule des 3 réponses est donnée, n'écrire que ce champ (YAML clairsemé). Les autres héritent du défaut documenté dans `references/sources-config.md`.

### Cas limites

- **`git.auto_commit: yes` ou `auto_push: yes`** → rappeler à l'utilisateur que cela **n'autorise jamais** le skip de hooks / signature GPG / autres bypass — c'est un raccourci pour sauter la confirmation, pas pour désactiver les règles de sécurité globales (voir `CLAUDE.md`).
- **`git.branch_pattern` modifié en cours de projet** → les branches déjà créées ne sont pas renommées rétroactivement. Prévenir que le nouveau pattern s'applique uniquement aux prochaines branches créées par `developer`.
