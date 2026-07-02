# API locale en lecture seule

`api/server.py` expose les sorties JSON locales via HTTP.

## Lancement

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Par défaut, l'écoute est limitée à `127.0.0.1`.

## Routes disponibles

```text
GET /api/health
GET /api/status
GET /api/modules
GET /api/history
GET /api/latest
GET /api/snapshot
```

## Comportement

- Les routes disponibles retournent du JSON.
- Les méthodes non prévues sont refusées.
- Les chemins inconnus retournent une erreur JSON.
- Les réponses utilisent `Cache-Control: no-store`.

## Commandes appelées

```text
bin/status_json.sh
bin/modules_json.sh
bin/history_json.sh
bin/api_snapshot_json.sh
```

## Objectif

Ce composant prépare :

- une interface web locale ;
- une lecture structurée de l'état du projet ;
- un point d'entrée HTTP simple autour des commandes JSON existantes.
