# Routes JSON

`bin/routes_json.sh` retourne un catalogue JSON des chemins locaux exposés par l'API.

## Commande

```bash
bash bin/routes_json.sh
```

## Sortie

La sortie contient :

- `kind` ;
- `schema_version` ;
- une liste `routes` avec `method`, `path`, `type` ;
- `requires_query` pour les chemins qui exigent un paramètre.

## Objectif

Cette commande permet de consulter le catalogue des routes sans démarrer le serveur local.

## Garanties

- Lecture seule.
- Ne lance aucun module réel.
- Ne crée aucun dossier de run.
- Testé en CI.
