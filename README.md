# kp-agents

Système de distribution multi-cibles pour agents IA. Définir un agent une seule fois, le déployer sur Claude Code, Cursor et Codex.

## Principe

```
agents/*.md  ──→  sync.sh  ──→  dist/claude/    → ~/.claude/commands/
                            ──→  dist/cursor/    → ~/.cursor/rules/
                            ──→  dist/codex/     → ~/.codex/skills/
```

Un seul fichier source par agent dans `agents/`. Le script `sync.sh` génère les artefacts pour chaque plateforme et les installe dans les répertoires utilisateur.

## Utilisation

```bash
# Générer et installer
./sync.sh

# Générer sans installer (dist/ uniquement)
./sync.sh --dist-only

# Nettoyer les agents installés lors du précédent sync (via manifeste)
./sync.sh --clean

# Nettoyer TOUS les skills kp-* (glob, indépendant du manifeste)
./sync.sh --clean-all
```

Après sync :
- **Claude Code** : `/kp-brainstorm`, `/kp-product`, `/kp-developer`, etc.
- **Cursor** : `@kp-brainstorm` via le sélecteur de règles
- **Codex** : skills auto-détectées

### Manifeste de synchronisation

À chaque run, `sync.sh` écrit la liste des agents installés dans `.installed-agents` (fichier local, non versionné). Cela permet au run suivant de supprimer proprement les agents qui ont été retirés de `agents/` entre-temps.

- `--clean` lit ce manifeste et retire chirurgicalement chaque agent précédemment installé
- `--clean-all` ignore le manifeste et supprime tout ce qui commence par `kp-*` dans les 3 cibles (utile pour repartir de zéro)

## Créer un agent

Créer `agents/mon-agent.md` avec ce frontmatter :

```yaml
---
name: mon-agent
description: "Description longue pour les outils IA"
short_description: "Description courte pour les listes"
default_prompt: "Prompt suggéré à l'utilisateur."
---

# Contenu de l'agent

Instructions, processus, règles...
```

Lancer `./sync.sh` — le script préfixe automatiquement avec `kp-`, donc l'agent sera disponible comme `/kp-mon-agent`.

## Includes

Les agents peuvent réutiliser des blocs partagés avec `{{include:nom}}` :

```markdown
{{include:docs-structure}}
```

Les fichiers d'include sont dans `includes/*.md`.

## Structure

```
agents/          Source de vérité (un .md par agent)
includes/        Templates partagés ({{include:nom}})
dist/            Artefacts générés (ne pas modifier)
  claude/        Commandes Claude Code (.md)
  cursor/        Règles Cursor (.mdc)
  codex/         Skills Codex (SKILL.md + openai.yaml)
sync.sh          Script de synchronisation
```

## Agents

### Workflow développement
| Agent | Description |
|-------|-------------|
| `brainstorm` | Explorer des idées, challenger des hypothèses |
| `product` | Structurer en roadmap, epics et stories |
| `architect` | Concevoir l'architecture technique |
| `developer` | Implémenter les stories et epics |
| `review` | Relire, tester, valider le code |
| `documentation` | Analyser et maintenir la documentation |
| `ux-ui` | Designer UX/UI et identité visuelle |

### Workflow RecetteMoi (tickets support)
| Agent | Description |
|-------|-------------|
| `recettemoi-support` | Triage et recommandation de tickets |
| `recettemoi-dev` | Traitement technique (BUG/IMPROVEMENT) |
| `recettemoi-review` | Validation et réponse utilisateur |

### Flux entre agents

```
brainstorm → product → architect → developer → review → documentation
                                       ↑                    ↓
                                       └────────────────────┘

recettemoi-support → recettemoi-dev → recettemoi-review
                   → recettemoi-review (direct si fonctionnel)
```
