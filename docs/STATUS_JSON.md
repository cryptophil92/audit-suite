# Status JSON

`bin/status_json.sh` exporte l'état local du moteur au format JSON.

## Commande

```bash
bash bin/status_json.sh
```

## Sortie

La commande renvoie un objet JSON :

```json
{
  "kind": "audit-suite.status",
  "schema_version": "1.0.0",
  "cwd": "/path/to/audit-suite",
  "checks": {
    "modules_dir_exists": true,
    "history_index_exists": false,
    "latest_exists": false
  },
  "counts": {
    "modules": 10,
    "history_runs": 0
  },
  "paths": {
    "history": "history",
    "history_index": "history/runs.jsonl",
    "history_latest": "history/latest.json"
  },
  "dependencies": {
    "required": [],
    "optional": []
  }
}
```

## Objectif

Ce format prépare :

- le diagnostic local avant lancement ;
- l'affichage d'un état de santé dans une future interface web ;
- l'intégration avec un futur backend API ;
- les tests automatisés autour de l'environnement local.

## Notes

- La commande nécessite `jq` pour produire le JSON.
- Elle respecte `AUDIT_HISTORY_DIR`.
- Elle ne modifie aucun fichier.
- Elle ne lance aucun module.
