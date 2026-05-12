## Bootstrap de `docs/guidelines.md`

`docs/guidelines.md` est la **convention de documentation lisible par tout agent IA** (kp-agents, superpower, ou autre). Setup le crée une fois et le maintient à la demande explicite.

### Quand créer le fichier

- **Au premier setup** d'un projet — fichier inexistant → créer.
- **À la demande de l'utilisateur** — `« mets à jour guidelines.md »` ou refresh après modification de la convention.
- **Migration depuis v1.x** — la procédure de migration inclut le bootstrap de guidelines.md.

### Quand ne PAS toucher

- **Fichier existant non vide** — ne jamais écraser silencieusement. Afficher un diff et demander confirmation explicite.
- **Pendant une session d'agent autre que setup** — `guidelines.md` ne se modifie qu'au démarrage d'un setup explicite.

### Procédure

1. **Vérifier l'existence** : lis `docs/guidelines.md`. Absent → bootstrap. Présent → demander confirmation avant refresh.
2. **Charger le template** : utilise ``references/template-guidelines.md`` comme contenu de base.
3. **Personnaliser si pertinent** :
   - Si monorepo détecté : la section "Monorepo" du template reste générique, pas besoin d'adaptation.
   - Si le projet a des conventions de nommage epic/story différentes : adapter les sections concernées.
4. **Écrire** : créer `docs/guidelines.md` avec le contenu personnalisé.
5. **Confirmer** : annoncer "docs/guidelines.md créé. Ce fichier est lu par tous les agents IA pour comprendre la convention."

### Cas limites

- **`docs/guidelines.md` existe avec un contenu très divergent du template** → afficher un diff complet, proposer 3 options :
  1. Garder l'existant tel quel (ne rien faire)
  2. Remplacer intégralement par le template à jour
  3. Merge manuel (afficher template, l'utilisateur copie-colle ce qu'il veut)
- **`docs/` n'existe pas** → créer le dossier (`mkdir -p docs`) avant d'écrire `guidelines.md`.
- **Pas d'agent `setup` invocable** (cas dégradé) → un autre agent peut **lire** `guidelines.md` mais ne doit **jamais** l'écrire. Renvoyer vers `/kp-agents:setup`.
