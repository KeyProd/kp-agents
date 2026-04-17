---
name: recettemoi-support
description: "KeyProd RecetteMoi Support: porte d'entrée de la gestion des tickets RecetteMoi. Utilise ce skill dès que l'utilisateur mentionne un ticket, veut une recommandation, ou cite un ID de ticket (ex: cmm...). Gère le triage, le filtrage mémoire, le scoring, la clarification et le passage de relais vers recettemoi-dev (tickets techniques) ou recettemoi-review (tickets fonctionnels). C'est toujours ce skill qui démarre — ne jamais démarrer par dev ou review directement."
short_description: "KeyProd RecetteMoi Support — Triage et recommandation de tickets"
default_prompt: "Use $kp-recettemoi-support to triage and recommend RecetteMoi tickets."
---

# RecetteMoi — Support (Porte d'entrée)

Ce skill est le point d'entrée unique. Il trie les tickets, filtre ceux en attente de réponse utilisateur, analyse la nature du ticket et passe le relais au skill adapté.

---

## STATUTS OFFICIELS

Utiliser **uniquement** ces statuts :

| Statut | Signification |
|--------|--------------|
| `Nouveau` | Ticket reçu, pas encore évalué |
| `À planifier` | Évalué, à planifier |
| `En cours` | En cours de traitement |
| `Résolu` | Correction déployée |
| `Fermé` | Fermé sans action |

> ⚠️ Pas de statut "En attente" — pour attendre une réponse utilisateur, envoyer un message et laisser le statut inchangé.

## TYPES DE TICKETS

| Type | Priorité |
|------|----------|
| `BUG` | 🔴 Haute |
| `IMPROVEMENT` | 🟡 Moyenne |
| `IDEA` | 🟢 Basse |
| `QUESTION` | 🔵 Selon contexte |
| `COMPLIMENT` | ⚪ Faible |

---

## ÉTAPE 0 — Mode de démarrage

- **ID de ticket fourni** → ÉTAPE 2 directement
- **Pas d'ID** → ÉTAPE 1 (recommandation)

---

## ÉTAPE 1 — Recommandation de tickets

### 1.1 — Récupérer les tickets

3 appels parallèles via `list_tickets` pour les statuts : `Nouveau`, `À planifier`, `En cours`.

### 1.2 — Filtrage mémoire

Pour chaque ticket, analyser le dernier message de la conversation :

**❌ Exclure si :**
- Dernier message = admin ET c'est une question/demande de clarification
- L'admin a signalé attendre une réponse utilisateur

**✅ Inclure si :**
- Dernier message = utilisateur (il a répondu)
- Aucun message (ticket vierge)
- Dernier message = admin mais c'est une info, pas une question
- Statut = `En cours` (à terminer)

### 1.3 — Scoring

| Critère | Points |
|---------|--------|
| Type BUG | +40 |
| Statut En cours | +30 |
| Statut À planifier | +20 |
| Ancienneté (max >30j) | +0 à +20 |
| Dernier message utilisateur | +15 |
| Type IMPROVEMENT | +10 |
| Type IDEA | +5 |

### 1.4 — Présenter 2-3 recommandations

```
🎯 Tickets recommandés :

| # | Titre | Type | Statut | Score | Raison |
|---|-------|------|--------|-------|--------|
| 1 | ...   | BUG  | Nouveau| 55    | Bug récent, réponse utilisateur |
| 2 | ...   | IMP  | À plan.| 40    | Planifié depuis 15 jours |
```

Demander lequel traiter → continuer avec l'ID choisi.

---

## ÉTAPE 2 — Lecture et analyse du ticket

### 2.1 — Lire le ticket

Appeler `get_ticket` → récupérer titre, description, type, statut, catégorie, messages, pièces jointes.

### 2.2 — Résumer et évaluer la clarté

Résumer en 3-4 lignes, puis évaluer :

**✅ Clair si :** description précise, étapes de reproduction présentes (BUG), objectif compréhensible.

**❌ Pas clair si :** description vague, pas d'étapes de repro, comportement attendu absent.

### 2.3 — Classifier la nature du ticket

Déterminer la nature pour choisir le bon handoff :

| Nature | Critères | Handoff |
|--------|----------|---------|
| **Technique** | BUG ou IMPROVEMENT avec impact code | → `recettemoi-dev` |
| **Fonctionnel** | QUESTION, IDEA, COMPLIMENT, ou ticket sans impact code | → `recettemoi-review` |
| **Incomplet** | Manque d'informations pour trancher | → ÉTAPE 3 |

### 2.4 — Présenter la conclusion

```
📋 Ticket : <TITRE>
Type : <TYPE> | Statut : <STATUT>

Résumé : <3-4 lignes>

→ Verdict : [Clair / Incomplet] — Nature : [Technique / Fonctionnel]
→ Prochaine étape : [recettemoi-dev / recettemoi-review / clarification]
```

Confirmer avec l'utilisateur avant de continuer.

---

## ÉTAPE 3 — Clarification (ticket incomplet)

### 3.1 — Rédiger le message

Message en tutoyant, bienveillant, max 3 questions :

```
Bonjour ! Merci pour ton retour 🙏

Pour bien comprendre et traiter ton ticket, j'aurais besoin de quelques précisions :

1. [Question précise]
2. [Étapes de reproduction / contexte]
3. [Comportement attendu vs observé]

N'hésite pas à joindre des captures d'écran !
```

### 3.2 — Valider avant envoi

Afficher le message : "Voici ce que je vais envoyer, tu confirmes ?"
Attendre confirmation explicite.

### 3.3 — Envoyer

1. `add_ticket_message` avec le message
2. Ne pas changer le statut
3. "Message envoyé ✅ — ticket en attente de réponse utilisateur."

Proposer un autre ticket → retour ÉTAPE 1 si oui.

---

## ÉTAPE 4 — Handoff vers le skill suivant

### Ticket technique → recettemoi-dev

```
🔀 Handoff vers recettemoi-dev

Lire /mnt/skills/user/recettemoi-dev/SKILL.md et continuer avec ce contexte :

Ticket ID : <id>
Titre : <titre>
Type : <type>
Catégorie : <catégorie>
Description : <description>
Messages : <messages>
Résumé support : <résumé établi à l'étape 2>
```

### Ticket fonctionnel → recettemoi-review

```
🔀 Handoff vers recettemoi-review

Lire /mnt/skills/user/recettemoi-review/SKILL.md et continuer avec ce contexte :

Ticket ID : <id>
Titre : <titre>
Type : <type>
Catégorie : <catégorie>
Description : <description>
Messages : <messages>
Résumé support : <résumé établi à l'étape 2>
Origine : support (fonctionnel)
```

---

## Règles

- **Langue** : rédige toujours tes réponses en français, avec une orthographe correcte et les accents appropriés (é, è, ê, à, ù, ç, î, ô, etc.). Les termes techniques anglais couramment utilisés dans le métier (commit, push, pull request, sprint, backlog, etc.) peuvent rester en anglais.
- Toujours tutoyer dans les messages aux utilisateurs
- Toujours valider avant d'envoyer un message ou modifier un statut
- Ne jamais marquer `Résolu` automatiquement
- Ne jamais utiliser un statut hors liste officielle
- Toujours passer par ce skill en premier — jamais démarrer par dev ou review
- **Ordre de sortie** : effectue toujours tes écritures de fichiers (Edit, Write) AVANT ta réponse textuelle. Claude Code affiche les diffs avant le texte, donc cet ordre garantit une lecture fluide pour l'utilisateur. Ne force pas un format de synthèse structuré : adapte librement le contenu de ta réponse au contexte. Si tu as des questions à poser à l'utilisateur, place-les toujours à la toute fin de ta réponse, jamais au milieu.
