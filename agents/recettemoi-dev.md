---
name: recettemoi-dev
description: "KeyProd RecetteMoi Dev: skill technique déclenché uniquement depuis recettemoi-support pour les tickets de type BUG ou IMPROVEMENT avec impact code. Ne jamais démarrer ce skill directement — toujours passer par recettemoi-support d'abord. Gère l'analyse du code concerné, la création de branche, l'implémentation via /kp-developer, le commit/push, puis passe le relais à recettemoi-review pour valider la réponse technique."
short_description: "KeyProd RecetteMoi Dev — Traitement technique des tickets"
default_prompt: "Use $kp-recettemoi-dev to implement a fix for a RecetteMoi ticket."
---

# RecetteMoi — Dev (Traitement technique)

Ce skill prend en charge les tickets techniques (BUG, IMPROVEMENT) après qualification par `recettemoi-support`. Il analyse le code, implémente la correction via `/kp-developer`, et passe le relais à `recettemoi-review`.

---

## CONTEXTE D'ENTRÉE ATTENDU

Ce skill reçoit depuis `recettemoi-support` :
- `Ticket ID`, `Titre`, `Type`, `Catégorie`
- `Description` complète
- `Messages` de la conversation
- `Résumé support` de l'analyse fonctionnelle

---

## ÉTAPE D1 — Analyse technique préalable

### D1.1 — Évaluer la faisabilité automatique

Analyser le ticket pour déterminer :
- Quel(s) fichier(s) / composant(s) sont concernés
- Si la correction est bien délimitée (simple / moyenne / complexe)
- Si l'agent peut traiter en autonomie ou si une intervention manuelle est nécessaire

**Traitable automatiquement si :**
- Correction localisée dans 1-3 fichiers identifiables
- Logique claire sans ambiguïté fonctionnelle
- Pas de refactoring architectural

**Manuel si :**
- Impact sur l'architecture ou plusieurs modules
- Ambiguïté sur le comportement attendu
- Risque de régression élevé

### D1.2 — Passer le ticket `En cours`

Appeler `update_ticket_status` → `En cours`.
Confirmer : "Ticket passé en En cours ✅"

### D1.3 — Présenter le plan

```
🔧 Plan de traitement technique

Ticket : <TITRE>
Complexité estimée : [Simple / Moyenne / Complexe]
Fichiers concernés : <liste>
Mode : [Automatique via agent / Manuel]

→ Je crée la branche et lance le traitement. Confirmes-tu ?
```

Attendre confirmation explicite.

---

## ÉTAPE D2 — Préparation de la branche

Indiquer les commandes git (ou les transmettre à l'agent) :

```bash
git checkout main
git pull origin main

# BUG :
git checkout -b hotfix/<ticket-id>-<slug-du-titre>

# IMPROVEMENT ou IDEA :
git checkout -b feature/<ticket-id>-<slug-du-titre>
```

Le slug = titre en minuscules, mots séparés par des tirets, sans accents ni caractères spéciaux.

Exemple : "Impossible de valider une recette IA" (ID: cmmkc1i2k)
→ `hotfix/cmmkc1i2k-impossible-valider-recette-ia`

---

## ÉTAPE D3 — Traitement par l'agent développeur

### Mode automatique

Invoquer `/kp-developer` avec le contexte complet :

```
Ticket : <TITRE>
ID : <ticket-id>
Type : <BUG|IMPROVEMENT>
Catégorie : <catégorie>

Description :
<description complète>

Messages utilisateur :
<messages>

Analyse technique :
<fichiers concernés, complexité, nature de la correction>

Instructions :
1. git checkout main && git pull origin main
2. Créer la branche :
   - BUG → git checkout -b hotfix/<ticket-id>-<slug>
   - IMPROVEMENT → git checkout -b feature/<ticket-id>-<slug>
3. Implémenter la correction
4. git add . && git commit -m "<type>(<catégorie>): <titre court>

Ticket: <ticket-id>
- <résumé des changements>"
5. git push origin <branche>
6. Retourner : fichiers modifiés, nature des changements, diff résumé, commandes exécutées
```

Types de commit : `fix` pour BUG, `feat` pour IMPROVEMENT.

### Mode manuel

Fournir le contexte à l'agent et guider l'utilisateur étape par étape :

```
/kp-developer

Ticket : <TITRE>
Type : <type> | Catégorie : <catégorie>

Description :
<description>

Messages :
<messages>

Objectif : Analyser le code concerné et proposer une correction/implémentation.
```

Après validation de la proposition par l'utilisateur :

```bash
git add .
git commit -m "<fix|feat>(<catégorie>): <titre court>

Ticket: <ticket-id>
- <résumé>"
git push origin <branche>
```

---

## ÉTAPE D4 — Handoff vers recettemoi-review

Une fois le commit/push effectué, transmettre le rapport à `recettemoi-review` :

```
🔀 Handoff vers recettemoi-review

Lire /mnt/skills/user/recettemoi-review/SKILL.md et continuer avec ce contexte :

Ticket ID : <id>
Titre : <titre>
Type : <type>
Catégorie : <catégorie>
Description : <description>
Messages : <messages>
Résumé support : <résumé de l'analyse fonctionnelle>
Origine : dev (technique)

Rapport de traitement :
- Branche : <nom-de-la-branche>
- Commit : <message de commit>
- Fichiers modifiés :
  - <fichier 1> : <nature du changement>
  - <fichier 2> : <nature du changement>
- Diff résumé : <description des changements effectués>
```

---

## Règles

- **Langue** : rédige toujours tes réponses en français, avec une orthographe correcte et les accents appropriés (é, è, ê, à, ù, ç, î, ô, etc.). Les termes techniques anglais couramment utilisés dans le métier (commit, push, pull request, sprint, backlog, etc.) peuvent rester en anglais.
- Ne jamais démarrer ce skill directement — toujours arriver depuis `recettemoi-support`
- Ne jamais marquer `Résolu` — c'est `recettemoi-review` qui conclut avec l'utilisateur
- Toujours demander confirmation avant de lancer l'agent en mode automatique
- En cas de doute sur la faisabilité automatique, passer en mode manuel
- Statuts utilisables : `En cours` uniquement dans ce skill
- **Ordre de sortie** : effectue toujours tes écritures de fichiers (Edit, Write) AVANT ta réponse textuelle. Claude Code affiche les diffs avant le texte, donc cet ordre garantit une lecture fluide pour l'utilisateur. Ne force pas un format de synthèse structuré : adapte librement le contenu de ta réponse au contexte. Si tu as des questions à poser à l'utilisateur, place-les toujours à la toute fin de ta réponse, jamais au milieu.
