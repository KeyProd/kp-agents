## Configuration de la dimension `product`

Cette dimension définit où vivent les outputs produit (roadmap, product.md, ideas, features/*/product.md).

### Questions à poser

1. **Mode** ? `local` (défaut, dans `docs/`) ou `external` (chemin absolu, ex: OneDrive).
2. Si `external` → **chemin absolu** du dossier. Présence d'espaces ou caractères spéciaux acceptée (ex: `Library/CloudStorage/OneDrive - Entity/`).
3. Si `external` → **accès** ? `read-write` (défaut, agents peuvent écrire) ou `read-only` (PM humain maintient ailleurs, agents lisent uniquement).

   Formuler ainsi :
   > La doc produit externe sera-t-elle **modifiable par les agents** (`read-write`, défaut) ou **en lecture seule** (`read-only`) ? Le mode `read-only` convient quand un PM humain maintient la doc ailleurs : les agents la lisent comme source de vérité mais n'y touchent jamais. Les epics et stories restent créables indépendamment via la dimension `tickets`.

### Validation d'accessibilité (si mode external)

Tente une lecture du `product.path` (ex: `Read` sur un fichier factice ou listing). Si échec :
- Option (a) : corriger le chemin
- Option (b) : enregistrer quand même, mode dégradé (warn à chaque démarrage d'agent)
- Option (c) : annuler le setup

### Écriture dans `.kp-agents.yml`

```yaml
product:
  mode: local | external
  access: read-write | read-only   # uniquement si mode: external
```

### Écriture dans `.kp-agents.local.yml` (si mode external)

```yaml
product:
  path: <chemin absolu>
```

### Cas limites

- **`access` omis ou absent** → ne pas écrire le champ (laisser les agents appliquer le défaut `read-write`). N'écris le champ que s'il vaut explicitement `read-only`, ou si l'utilisateur l'a explicité même à `read-write`.
- **`access` en mode local** → inutile, ne jamais le proposer ni l'écrire. Si déjà présent dans un `.kp-agents.yml` existant lors d'une modification, warn (« champ ignoré en mode local ») et propose de le retirer.
