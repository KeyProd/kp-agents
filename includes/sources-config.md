## Configuration des sources

Ce projet peut pointer vers des sources externes (doc produit OneDrive, tickets externalisés via MCP) via deux fichiers optionnels à la racine du projet. En leur absence, **tous les outputs vont dans `docs/` local** (comportement par défaut, inchangé).

### Fichier `.kp-agents.yml` (commité) — politique de sources

```yaml
product:
  mode: local | external      # défaut: local
tickets:
  mode: local | mcp           # défaut: local
  mcp_server: <nom>           # requis si mode: mcp
  project_key: <clé>          # requis si mode: mcp
```

### Fichier `.kp-agents.local.yml` (gitignoré) — chemins machine-spécifiques

```yaml
product:
  path: <chemin absolu>       # requis si product.mode: external
```

### Comportement au démarrage

1. **Lire** `.kp-agents.yml` via Read. S'il est absent → mode 100% local, aucune vérification supplémentaire.
2. **Pour chaque dimension activée en externe**, vérifier les prérequis :
   - `product.mode: external` → `.kp-agents.local.yml` présent et `product.path` renseigné et accessible en lecture.
   - `tickets.mode: mcp` → `mcp_server` et `project_key` renseignés dans `.kp-agents.yml`.
3. **Si config incomplète ou chemin inaccessible** → warn l'utilisateur, proposer `/kp-agents:setup` pour corriger, et continuer en mode local dégradé pour la session.

### Résolution de chemin pour la dimension `product`

Quand `product.mode: external` est actif et le chemin est valide, les outputs suivants sont **redirigés vers `<product.path>/`** au lieu de `docs/` local :

- `ideas/<theme>.md`
- `product.md`
- `features/<group>/product.md`
- `project/roadmap.md`
- `project/epics/E-XXXX-*/readme.md`

**Toujours écrits en local** quelle que soit la config, car relevant du périmètre technique ou de l'index local du repo : `docs/architect.md`, `docs/features/<group>/architect.md`, `docs/INDEX.md`, toute doc technique. Les stories individuelles (`S-XXXX-*.md`) suivent la dimension `tickets` (voir ci-dessous).

### Mode `tickets.mode: mcp`

Quand `tickets.mode: mcp` est actif, les epics et stories sont créées / lues / mises à jour via les outils MCP du serveur `mcp_server` dans le projet `project_key`. Aucun fichier `E-XXXX-*/readme.md` ni `S-XXXX-*.md` n'est créé localement pour ces tickets. L'utilisateur doit avoir configuré le serveur MCP correspondant dans ses `settings.json` Claude Code — l'agent ne configure pas le MCP lui-même.

### Écriture avec fallback local

Toute écriture sur une source externe (chemin `product.path` ou serveur MCP) suit ce protocole :

1. Tenter l'écriture au chemin externe ou via l'outil MCP.
2. Si erreur (permission refusée, dossier inexistant, MCP injoignable) → **basculer sur `docs/` local** en reproduisant l'arborescence relative, et **warner explicitement** l'utilisateur en indiquant le chemin exact du fichier écrit.

### Redirection vers `/kp-agents:setup`

Si, au cours d'une opération, la config requise est absente, incomplète ou incohérente, proposer à l'utilisateur l'invocation `/kp-agents:setup` pour corriger. La redirection est une **suggestion, jamais un blocage** — l'utilisateur peut toujours refuser et poursuivre manuellement.
