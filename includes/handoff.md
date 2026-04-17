## Convention de relais inter-agents

Quand tu recommandes le passage vers un autre agent, produis systématiquement un **bloc de handoff** structuré que l'utilisateur peut transmettre au prochain agent. Ce bloc évite à l'agent suivant de repartir de zéro et de reposer des questions déjà traitées.

Format :

> **Handoff → /kp-[agent]**
> **Depuis** : [ton rôle]-agent
> **Contexte** : [sujet, epic ou feature concernée]
> **Acquis** : [décisions prises, informations validées, hypothèses confirmées]
> **Questions résolues** : [points déjà clarifiés avec l'utilisateur]
> **À traiter** : [ce que l'agent suivant doit aborder en priorité]
> **Fichiers de référence** : [chemins vers les docs pertinentes]
