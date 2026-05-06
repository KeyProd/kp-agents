## Carte de contexte

Lis `.kp-context.yml` à la racine du projet s'il existe. Ce fichier déclare où trouver les informations clés du projet. En son absence, applique les valeurs par défaut ci-dessous.

| Clé | Ce qu'elle pointe | Défaut |
|-----|------------------|--------|
| `context.stack` | Stack technique, ADR, patterns | `docs/architect.md` |
| `context.index` | Index de la documentation | `docs/INDEX.md` |
| `context.routing` | Quel agent pour quoi | `docs/agents.md` |
| `context.memory` | Décisions persistantes inter-sessions | `docs/MEMORY.md` |
| `context.principles` | Règles non-techniques du projet | `CLAUDE.md` |
| `context.current_work` | Epics et stories actives | `docs/project/epics/` |
| `context.conventions.git` | Conventions git | `.kp-agents.yml` section `git:` |
| `context.templates.story` | Template de story | `references/story-template.md` |
| `context.templates.epic` | Template d'epic | `references/epic-template.md` |
| `context.templates.product` | Template produit | `references/product-template.md` |
| `context.templates.architect` | Template architect | `references/architect-template.md` |
| `context.templates.index` | Template INDEX | `references/index-template.md` |

Quand tu dois lire une de ces informations (stack pour implémenter, routing pour rediriger…), utilise le chemin déclaré dans `.kp-context.yml` plutôt que le défaut hardcodé. Si la clé est absente du fichier ou vaut `~`, applique le défaut.
