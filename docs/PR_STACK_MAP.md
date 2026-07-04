# Carte de pile des PR

Ce document décrit l'ordre logique de revue, test et fusion des PR empilées.

## Principe

Les PR sont empilées les unes sur les autres. Elles doivent être testées et fusionnées dans l'ordre croissant.

Ne pas fusionner une PR intermédiaire si la PR précédente n'a pas été validée localement.

## Ordre de fusion

```text
#1  -> #2  -> #3  -> #4  -> #5
#6  -> #7  -> #8  -> #9  -> #10
#11 -> #12 -> #13 -> #14 -> #15
#16 -> #17 -> #18 -> #19 -> #20
#21 -> #22 -> #23 -> #24 -> #25
#26 -> #27 -> #28 -> #29 -> #30
#31 -> #32 -> #33
```

## Groupes fonctionnels

### Socle moteur

```text
#1  Hardening Bash
#2  Run history
#3  Report schema
#4  Compare run manifests
#5  HTML report
#6  Report pack
#7  Report pipeline
```

### CLI et garde-fous

```text
#8   CLI args
#9   Dry run
#10  Module validation
#11  Categories all
#12  Run id
#13  Run id collision
```

### Sorties JSON

```text
#14  Plan JSON
#15  Modules JSON
#16  History JSON
#17  Status JSON
#18  API snapshot JSON
#28  Version JSON
#30  Routes JSON CLI
```

### Smoke tests et documentation de contrôle

```text
#19  Smoke local
#29  Smoke version check
#31  Smoke routes check
#32  JSON commands documentation
#33  Local quickstart
```

### API et interface locale

```text
#20  Read-only API server
#21  Web shell
#22  API plan route
#23  Web plan preview
#24  OpenAPI spec
#25  Web module selector
#26  API routes JSON
#27  Web routes panel
```

## Garde-fous avant fusion

Avant toute fusion :

```bash
bash bin/smoke_local.sh
bash audit.sh --dry-run --profile fast --targets 192.168.1.0/24 --categories all --run-id MERGE_CHECK --no-zeek --no-suricata
python3 api/server.py --host 127.0.0.1 --port 8765
```

Puis ouvrir :

```text
http://127.0.0.1:8765/
```

## Règles

- Garder toutes les PR en brouillon tant que le test local réel n'est pas fait.
- Ne pas activer de lancement réel depuis l'interface web avant validation explicite.
- Garder l'API locale sur `127.0.0.1` par défaut.
- Ne tester que sur réseau personnel, lab ou environnement autorisé.
- Fusionner dans l'ordre croissant uniquement.
