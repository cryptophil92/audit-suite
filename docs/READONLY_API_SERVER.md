# API locale en lecture seule

`api/server.py` expose les sorties JSON locales et la page web locale via HTTP.

## Lancement

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Par défaut, l'écoute est limitée à `127.0.0.1`.

## Routes disponibles

```text
GET /
GET /index.html
GET /api/health
GET /api/status
GET /api/modules
GET /api/history
GET /api/latest
GET /api/snapshot
GET /api/openapi.json
GET /api/plan?targets=192.168.1.0/24&profile=fast&categories=all&run_id=API_PLAN_TEST
```

## Route plan

`/api/plan` appelle `bin/plan_json.sh` et retourne un plan JSON sans créer de dossier de run.

Paramètres acceptés :

```text
targets       obligatoire
profile       défaut: fast
categories    défaut: all
run_id        optionnel
allow_public  1/true/yes/on
no_udp        1/true/yes/on
no_zeek       1/true/yes/on
no_suricata   1/true/yes/on
```

## Spécification

`/api/openapi.json` sert le fichier `api/openapi.json`.

## Comportement

- `/` et `/index.html` servent `web/index.html`.
- Les routes `/api/*` retournent du JSON.
- Les méthodes non prévues sont refusées.
- Les chemins inconnus retournent une erreur JSON.
- Les réponses utilisent `Cache-Control: no-store`.

## Commandes appelées

```text
bin/status_json.sh
bin/modules_json.sh
bin/history_json.sh
bin/api_snapshot_json.sh
bin/plan_json.sh
```

## Objectif

Ce composant prépare :

- une interface web locale ;
- une lecture structurée de l'état du projet ;
- un point d'entrée HTTP simple autour des commandes JSON existantes.
