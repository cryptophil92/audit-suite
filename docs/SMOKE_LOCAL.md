# Smoke test local

`bin/smoke_local.sh` vérifie rapidement les commandes locales principales sans lancer de module réel.

## Commande

```bash
bash bin/smoke_local.sh
```

## Vérifications exécutées

Le script contrôle :

- `bin/version_json.sh` ;
- `bin/modules_json.sh` ;
- `bin/status_json.sh` ;
- `bin/history_json.sh list` ;
- `bin/plan_json.sh` ;
- `bin/api_snapshot_json.sh` ;
- `audit.sh --dry-run`.

## Variables d'environnement

```bash
SMOKE_TARGET=192.168.1.0/24
SMOKE_RUN_ID=SMOKE_LOCAL
SMOKE_HISTORY_DIR=/tmp/audit-suite-smoke
```

## Garanties

- Ne lance aucun module.
- Ne crée pas de dossier de run.
- Utilise un historique temporaire par défaut.
- Vérifie que les sorties JSON sont bien structurées.

## Objectif

Ce script sert de contrôle rapide avant un test local plus complet ou avant le branchement d'un futur backend/API.
