# Evals — Évaluation objective des agents kp-agents

Ce dossier contient les **jeux d'évaluation** des agents kp-agents. Il est destiné aux mainteneurs du projet. Il n'est **pas distribué** aux cibles Claude Code / Cursor / Codex : le glob `agents/*.md` utilisé par `sync.sh` (voir `sync.sh:423`) ignore naturellement ce sous-répertoire, et le préfixe `_` garantit l'exclusion même si le glob évoluait.

## But

Mesurer deux choses, par agent, avant et après une modification :

1. **Trigger rate** — est-ce que la description de l'agent (`description` du frontmatter) déclenche bien le bon skill quand un utilisateur formule une demande typique, et ne déclenche **pas** sur les prompts voisins (near-miss avec d'autres agents) ?
2. **Output quality** — quand l'agent est déclenché sur un prompt connu, produit-il un livrable qui satisfait des assertions objectives (présence de sections, champs de frontmatter, respect d'un statut, etc.) ?

Ces métriques transforment une intuition qualitative (« la description a l'air plus claire ») en un chiffre comparable entre deux commits.

## Structure

```
agents/_evals/
├── README.md                            ← ce fichier
├── developer/
│   ├── trigger_queries.json             ← ~20 prompts, 10 positifs + 10 négatifs (dont near-miss)
│   └── output_evals.json                ← 2-3 cas prompt + expected_output + assertions
└── review/
    ├── trigger_queries.json
    └── output_evals.json
```

Pilotes choisis : **developer** et **review** — les deux agents dont les prompts sont le plus souvent confondus (ex: « vérifie ce code » → developer ou review ?) et dont l'exigence sur le livrable est la plus forte.

## Formats

### `trigger_queries.json`

Liste de prompts annotés par la vérité terrain (ce que l'utilisateur attend réellement) :

```json
{
  "agent": "developer",
  "version": "v0.2.0",
  "queries": [
    {
      "id": "dev-pos-01",
      "query": "implémente la story S-0003 de l'epic E-0002",
      "should_trigger": true,
      "reason": "ID de story explicite → developer"
    },
    {
      "id": "dev-neg-01",
      "query": "review ma PR #42",
      "should_trigger": false,
      "reason": "near-miss vers review"
    }
  ]
}
```

**Règles de rédaction** :
- Au moins **20 queries** par agent.
- Équilibre **10 positives / 10 négatives** minimum.
- Au moins **3 near-miss** : prompts ambigus qui auraient pu appartenir à un agent voisin (product / review / brainstorm).
- **25 % au moins** des queries en **anglais**, le reste en français — pour tester l'agnosticisme linguistique de la description.

### `output_evals.json`

Cas de bout en bout avec assertions vérifiables sans jugement humain :

```json
{
  "agent": "developer",
  "cases": [
    {
      "id": "dev-out-01",
      "prompt": "implémente S-0001 de l'epic E-0003 (story factice de test)",
      "expected_behavior": [
        "l'agent lit docs/architect.md avant de coder",
        "l'agent propose un plan d'implémentation et attend validation",
        "le statut de la story passe à IN PROGRESS puis DONE ou REVIEW"
      ],
      "assertions": [
        { "type": "file_contains", "path": "docs/project/epics/E-0003-.../S-0001-....md", "substring": "## Implémentation" },
        { "type": "file_contains", "path": "docs/project/epics/E-0003-.../S-0001-....md", "substring": "## Validation par critère" },
        { "type": "frontmatter_field_equals", "path": "...", "field": "status", "value": "DONE" }
      ]
    }
  ]
}
```

**Types d'assertions supportés** (à implémenter côté runner) :
- `file_contains` : le fichier contient une sous-chaîne.
- `file_absent` : le fichier n'existe pas.
- `frontmatter_field_equals` : un champ YAML vaut exactement une valeur.
- `section_order` : une section apparaît avant une autre dans un fichier markdown.

## Exécution (hors périmètre S-0007)

Cette story **ne couvre pas** l'exécution. Un runner futur devra :

1. Lire `trigger_queries.json`, appeler l'API Anthropic avec et sans le skill chargé, calculer le delta de trigger rate.
2. Lire `output_evals.json`, lancer un agent isolé (worktree jetable, base documentaire factice), vérifier les assertions.
3. Produire un `benchmark.json` avec les métriques (trigger rate, pass rate, time, tokens) commit par commit.

Format prévu pour `benchmark.json` :

```json
{
  "commit": "a1b2c3d",
  "date": "2026-04-18",
  "agents": {
    "developer": {
      "trigger_rate_with_skill": 0.95,
      "trigger_rate_without_skill": 0.30,
      "output_pass_rate": 0.88,
      "avg_tokens": 12400
    }
  }
}
```

## Maintenance

- Mettre à jour les queries quand la `description` d'un agent change significativement (S-0002 a par exemple reformulé toutes les descriptions en impératif).
- Les near-miss doivent **rester ambigus** — si le modèle les tranche facilement, remplacer par des near-miss plus subtils.
- Préférer l'ajout au remplacement : garder la trace des queries historiques aide à suivre l'évolution de la discrimination.
