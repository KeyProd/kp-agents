---
name: recettemoi-review
description: "KeyProd RecetteMoi Review: skill de validation et réponse, déclenché depuis recettemoi-support (tickets fonctionnels) ou recettemoi-dev (tickets techniques après implémentation). Ne jamais démarrer ce skill directement. Analyse la réponse à donner à l'utilisateur : rédige une réponse fonctionnelle claire (depuis support) ou valide le rapport de traitement technique et prépare la communication utilisateur (depuis dev). Conclut le cycle de vie du ticket."
short_description: "KeyProd RecetteMoi Review — Validation et réponse utilisateur"
default_prompt: "Use $kp-recettemoi-review to validate and respond to a RecetteMoi ticket."
---

# RecetteMoi — Review (Validation & Réponse)

Ce skill conclut le traitement d'un ticket. Il est appelé depuis `recettemoi-support` (réponse fonctionnelle) ou `recettemoi-dev` (validation d'une implémentation technique). Il analyse la qualité de la réponse à donner et gère la communication finale avec l'utilisateur.

---

## CONTEXTE D'ENTRÉE ATTENDU

Ce skill reçoit depuis `recettemoi-support` ou `recettemoi-dev` :
- `Ticket ID`, `Titre`, `Type`, `Catégorie`
- `Description`, `Messages`
- `Résumé support`
- `Origine` : `support (fonctionnel)` ou `dev (technique)`
- Si origine `dev` : `Rapport de traitement` (branche, commit, fichiers modifiés, diff résumé)

---

## ÉTAPE R0 — Déterminer le mode selon l'origine

- **Origine `support (fonctionnel)`** → ÉTAPE R1 (réponse fonctionnelle)
- **Origine `dev (technique)`** → ÉTAPE R2 (validation technique)

---

## ÉTAPE R1 — Réponse fonctionnelle (depuis support)

Pour les tickets QUESTION, IDEA, COMPLIMENT ou tickets sans impact code.

### R1.1 — Analyser la demande et formuler la réponse

Construire une réponse claire, utile et bienveillante pour l'utilisateur :

**Grille d'analyse :**
- Quelle est la vraie demande de l'utilisateur ?
- Y a-t-il une solution immédiate dans le produit actuel ?
- Faut-il orienter vers une fonctionnalité existante ?
- S'agit-il d'une demande à planifier (IDEA/IMPROVEMENT) ?
- Y a-t-il une workaround en attendant une correction ?

**Structure de réponse recommandée :**
```
Bonjour ! Merci pour ton message 🙏

[Reformulation courte de la demande pour montrer qu'on a compris]

[Réponse directe : solution, explication, ou information]

[Si applicable : étapes concrètes / lien vers la fonctionnalité]

[Si IDEA ou IMPROVEMENT : confirmation que c'est noté et sera étudié]

N'hésite pas si tu as d'autres questions !
```

### R1.2 — Review interne de la réponse

Avant de présenter à l'utilisateur, vérifier :
- ✅ La réponse répond bien à la vraie question
- ✅ Le ton est bienveillant et en tutoiement
- ✅ Pas de jargon technique inutile
- ✅ La réponse est actionnable (l'utilisateur sait quoi faire)
- ✅ Longueur appropriée (ni trop courte, ni trop longue)

### R1.3 — Présenter la réponse à l'admin

```
📝 Réponse proposée pour l'utilisateur :

---
<message rédigé>
---

✅ Points couverts : <liste rapide>
⚠️ Points non couverts / à noter : <si applicable>

→ Tu confirmes l'envoi ?
```

Attendre confirmation explicite.

### R1.4 — Envoyer et conclure

Une fois confirmé :
1. `add_ticket_message` avec le message
2. Si ticket résolu → proposer de passer en `Résolu` : "Souhaites-tu passer ce ticket en Résolu ?"
3. Si IDEA/IMPROVEMENT → proposer `À planifier` si pas déjà fait
4. Informer : "Réponse envoyée ✅"

---

## ÉTAPE R2 — Validation technique (depuis dev)

Pour les tickets BUG ou IMPROVEMENT après implémentation par `recettemoi-dev`.

### R2.1 — Analyser le rapport de traitement

Examiner le rapport reçu depuis `recettemoi-dev` :

**Grille de validation :**
- ✅ La branche est correctement nommée (`hotfix/` ou `feature/`)
- ✅ Le commit message suit la convention (`fix(catégorie):` ou `feat(catégorie):`)
- ✅ Les fichiers modifiés correspondent à la nature du ticket
- ✅ Le diff résumé semble cohérent avec la correction attendue
- ⚠️ Y a-t-il des effets de bord potentiels ?
- ⚠️ Des tests à mentionner à l'admin ?

### R2.2 — Présenter le rapport de validation à l'admin

```
✅ Traitement terminé — Rapport de validation

📌 Ticket : <TITRE> (<ticket-id>)
🌿 Branche : <nom-de-la-branche>
📝 Commit : <message de commit>

Fichiers modifiés :
- <fichier 1> : <nature du changement>
- <fichier 2> : <nature du changement>

Analyse :
- Cohérence avec le ticket : ✅ / ⚠️ <commentaire>
- Convention de nommage : ✅ / ⚠️ <commentaire>
- Points d'attention : <si applicable>

🔍 Prochaine étape recommandée :
1. Revoir les changements sur la branche
2. Tester le comportement corrigé
3. Créer une Pull Request vers main
4. Passer le ticket en Résolu après déploiement

→ Est-ce que tout te convient ?
```

### R2.3 — Rédiger la réponse utilisateur

Préparer un message à envoyer à l'utilisateur du ticket pour l'informer de la correction :

```
Bonjour ! Merci pour ton signalement 🙏

Bonne nouvelle : nous avons identifié et corrigé le problème que tu as remonté.

[Description simple de ce qui a été corrigé, sans jargon technique]

La correction sera disponible lors de la prochaine mise à jour de l'application.
N'hésite pas à nous faire signe si tu constates encore un problème !
```

### R2.4 — Valider et envoyer

Présenter le message utilisateur : "Voici le message à envoyer à l'utilisateur, tu confirmes ?"

Une fois confirmé :
1. `add_ticket_message` avec le message
2. Proposer de passer en `Résolu` si le déploiement est imminent, sinon laisser `En cours`
3. "Message envoyé ✅"

---

## ÉTAPE R3 — Clôture et suite

Après l'envoi :

```
🎯 Ticket traité avec succès !

Récap :
- Ticket : <TITRE>
- Action : <Réponse fonctionnelle / Correction technique>
- Statut final : <nouveau statut>

→ Souhaites-tu traiter un autre ticket ?
```

Si oui → indiquer de relancer `recettemoi-support` (ÉTAPE 1, Mode B).

---

## Règles

- **Langue** : rédige toujours tes réponses en français, avec une orthographe correcte et les accents appropriés (é, è, ê, à, ù, ç, î, ô, etc.). Les termes techniques anglais couramment utilisés dans le métier (commit, push, pull request, sprint, backlog, etc.) peuvent rester en anglais.
- Ne jamais démarrer ce skill directement — toujours arriver depuis support ou dev
- Ne jamais marquer `Résolu` sans demander confirmation à l'utilisateur
- Toujours tutoyer dans les messages aux utilisateurs du support
- Toujours présenter la réponse à l'admin avant envoi
- En mode dev : valider la cohérence du rapport avant de présenter à l'admin
- Statuts utilisables : `Résolu`, `Fermé`, `À planifier` (selon contexte)
- **Ordre de sortie** : effectue toujours tes écritures de fichiers (Edit, Write) AVANT ta réponse textuelle. Claude Code affiche les diffs avant le texte, donc cet ordre garantit une lecture fluide pour l'utilisateur. Ne force pas un format de synthèse structuré : adapte librement le contenu de ta réponse au contexte. Si tu as des questions à poser à l'utilisateur, place-les toujours à la toute fin de ta réponse, jamais au milieu.
