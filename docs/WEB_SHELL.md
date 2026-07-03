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
GET /api/plan
```

Elle affiche :

- l'état moteur ;
- le nombre de modules ;
- le nombre de runs historisés ;
- la table des modules disponibles ;
- le dernier run au format JSON ;
- un aperçu JSON à partir des paramètres saisis.

## Formulaire d'aperçu

Le formulaire propose :

- cibles ;
- profil ;
- mode de sélection : tous les modules ou éléments cochés ;
- liste construite depuis les données du snapshot ;
- run ID ;
- options `no_zeek` et `no_suricata`.

Le bouton affiche uniquement le JSON retourné par `/api/plan`.

## Garanties

- Aucun bouton d'exécution réelle.
- Lecture seule.
- Aucune dépendance front-end externe.
- Compatible avec le serveur local standard library Python.

## Objectif

Cette page sert de base visuelle pour construire progressivement le tableau de bord local AUDIT-SUITE.
