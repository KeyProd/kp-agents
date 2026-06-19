## Template recommandé — `docs/ideas/<theme>.md`

Objectif : capturer l'exploration d'une idée et la faire mûrir (`draft → exploring → qualified / rejected`).

```markdown
---
title: <Titre de l'idée>
date: <YYYY-MM-DD>
status: draft        # draft | exploring | qualified | rejected
author: brainstorm-agent
---

# <Titre de l'idée>

## Problème / besoin
- Qui ? Quel contexte ? Quelle douleur ?
- Pourquoi maintenant ?

## Approches envisagées
1. **<Approche A>** — principe, avantages, inconvénients
2. **<Approche B>** — …
3. **<Approche C>** — …

## Analyse critique
- Hypothèses à valider
- Contraintes (techniques, métier, temps)
- Risques / inconnues

## Recommandation
- Approche privilégiée + justification

## Décision / Next steps
- [ ] …
- Relais : `@agent-kp-agents:kp-product` (si qualifiée) ou `@agent-kp-agents:kp-architect` (incertitudes techniques)
```
