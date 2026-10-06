---
name: "kp-validation-criteres"
description: "Format et règles de la section ## Validation par critère : mapper chaque critère d'acceptation à son implémentation, sa preuve et ses limites, de façon traçable. Utilisée par kp-developer (rédaction) et kp-review (vérification)."
---

## Validation par critère — section traçable

Une story implémentée porte une section `## Validation par critère` qui mappe **chaque critère d'acceptation** à :
- l'**implémentation** réalisée (`fichier:ligne`) ;
- la **preuve** ou le test exécuté (unitaire / intégration / e2e selon pertinence) ;
- les **limites** connues ou cas non couverts.

Statut par critère : **✅** validé · **⚠️** partiel / non vérifié en conditions réelles · **❌** non couvert. Un critère non validé est **documenté explicitement** — jamais marqué implicitement comme couvert.

### ✅ Bien remplie — chaque critère traçable

```markdown
## Validation par critère

- **Le token expire après 24h** : ✅ implémenté via `TokenService.expiresIn: 86400` dans `src/auth/token.ts:42`. Test `token.test.ts:15-28` vérifie l'expiration simulée. Limite : pas de test d'horloge système modifiée.
- **L'email de confirmation part en < 30s** : ⚠️ implémenté via queue async (`src/email/queue.ts`), **non vérifié en charge** — seul le happy path local est testé. À valider en staging.
- **Permissions admin respectées** : ✅ middleware `requireAdmin` (`src/middleware/auth.ts:60`), testé via `auth.e2e.test.ts` (403 pour user non-admin).
```

### ❌ Trop vague — à éviter

```markdown
## Validation par critère

- Le token : OK
- L'email : testé
- Permissions : fonctionnent
```

La différence : dans le mauvais exemple, un reviewer ne peut pas vérifier **ce qui a été fait**, **avec quelle preuve**, ni **où sont les limites**.

### Usage

- **kp-developer** (rédaction) : écrit cette section en fin de validation — un critère = une ligne traçable. Distingue les niveaux de test (unitaire / intégration / e2e). Si un critère n'a pas pu être validé, le déclarer explicitement.
- **kp-review** (vérification) : vérifie que **chaque** critère d'acceptation de la story a sa ligne, que les preuves citées (fichiers/tests) existent réellement, et challenge les `⚠️` / `❌` avant de rendre son verdict GO/NO-GO.
