# Interface web locale

`web/index.html` est une première interface locale en lecture seule.

## Lancement

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Puis ouvrir :

```text
http://127.0.0.1:8765/
```

## Données affichées

La page lit :

```text
GET /api/snapshot
```

Elle affiche :

- l'état moteur ;
- le nombre de modules ;
- le nombre de runs historisés ;
- la table des modules disponibles ;
- le dernier run au format JSON.

## Garanties

- Aucun bouton d'exécution.
- Lecture seule.
- Aucune dépendance front-end externe.
- Compatible avec le serveur local standard library Python.

## Objectif

Cette page sert de base visuelle pour construire progressivement le tableau de bord local AUDIT-SUITE.
