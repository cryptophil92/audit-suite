# Historique JSON

`bin/history_json.sh` exporte l'historique local au format JSON.

## Commandes

```bash
bash bin/history_json.sh list
bash bin/history_json.sh latest
bash bin/history_json.sh paths
```

La commande par défaut est `list`.

## Liste

```bash
bash bin/history_json.sh list
```

Retourne :

```json
{
  "kind": "audit-suite.history",
  "schema_version": "1.0.0",
  "count": 0,
  "paths": {
    "index": "history/runs.jsonl"
  },
  "runs": []
}
```

## Dernier run

```bash
bash bin/history_json.sh latest
```

Retourne un objet `latest`. Si aucun dernier run n'existe, `latest` vaut `null`.

## Chemins

```bash
bash bin/history_json.sh paths
```

Retourne les chemins utilisés pour l'historique :

- dossier history ;
- index JSONL ;
- latest JSON.

## Notes

- La commande nécessite `jq`.
- Elle respecte `AUDIT_HISTORY_DIR`.
- Elle ne modifie pas l'historique.
- Elle lit uniquement les fichiers locaux d'historique.
