# API locale en lecture seule

`api/server.py` expose les sorties JSON locales et la page web locale via HTTP.

## Lancement

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Par défaut, l'écoute est limitée à `127.0.0.1`.

`--host` accepte uniquement une adresse IP loopback littérale :

```text
127.0.0.0/8
::1
```

Exemple IPv6 :

```bash
python3 api/server.py --host ::1 --port 8765
```

Les adresses non loopback (`0.0.0.0`, une adresse LAN ou une adresse publique)
et les noms d'hôte sont refusés avant la création du serveur. Il n'existe aucun
mode de contournement pour une écoute distante : cette capacité nécessiterait
une revue dédiée et un mécanisme d'authentification.

## Budgets des sous-processus

Chaque route dynamique possède un délai maximal :

| Route | Délai par défaut |
| --- | ---: |
| `/api/status` | 10 s |
| `/api/modules` | 10 s |
| `/api/history` | 10 s |
| `/api/history/paths` | 10 s |
| `/api/latest` | 10 s |
| `/api/plan` | 10 s |
| `/api/snapshot` | 15 s |

La sortie combinée `stdout` + `stderr` est limitée à 1 048 576 octets par
commande. Les valeurs peuvent être remplacées au lancement :

```bash
python3 api/server.py \
  --host 127.0.0.1 \
  --port 8765 \
  --command-timeout 20 \
  --max-output-bytes 2097152
```

`--command-timeout` remplace tous les délais de route. Les deux valeurs doivent
être strictement positives. Une expiration retourne HTTP `504` avec
`error: command_timeout`; un dépassement de volume retourne HTTP `502` avec
`error: output_limit_exceeded`. Le processus est interrompu et aucune trace
Python n'est incluse dans la réponse.

`/api/routes` publie le délai effectivement appliqué à chaque route dynamique,
la surcharge éventuelle et la limite de sortie. La spécification OpenAPI
documente les réponses `502` et `504`.

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
GET /api/routes
GET /api/plan?targets=192.168.1.0/24&profile=fast&categories=all&run_id=API_PLAN_TEST
```

## Catalogue des routes

`/api/routes` retourne la liste structurée des routes exposées par le serveur local.

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

`/api/openapi.json` sert le fichier `api/openapi.json` après injection de la
version canonique et du commit courant. `/api/health` expose les mêmes valeurs.

## Comportement

- `/` et `/index.html` servent `web/index.html`.
- Les routes `/api/*` retournent du JSON.
- Les méthodes non prévues sont refusées.
- Les chemins inconnus retournent une erreur JSON.
- Les réponses utilisent `Cache-Control: no-store`.
- Les routes dynamiques bornent leur durée et le volume capturé de leurs
  sous-processus.
- Les erreurs HTTP des sous-processus n'exposent ni la commande exécutée, ni
  `stderr`, ni les chemins internes des ressources statiques.
- Les détails nécessaires au diagnostic sont consignés uniquement dans le
  journal privé du processus serveur.

Sous Windows Git Bash, les quatre sources du snapshot sont calculées en
parallèle afin de rester dans le budget documenté de 15 secondes. Ce budget
n'est pas augmenté silencieusement selon la plateforme ; toute surcharge exige
une option explicite au lancement.

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
