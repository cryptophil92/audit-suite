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
  "degraded": false,
  "error_count": 0,
  "degradation": {
    "invalid_line_count": 0,
    "ignored_line_count": 0
  },
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

Si `latest.json` est invalide ou tronqué, la commande reste exploitable :
elle retourne `latest: null`, `degraded: true`, `error_count: 1` et le code
structuré `invalid_latest_json`.

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
- Les lignes JSONL vides sont ignorées et comptées dans
  `degradation.ignored_line_count`.
- Les lignes invalides ou tronquées n'empêchent pas le retour des entrées
  valides. Elles sont signalées par `degraded`, `error_count` et
  `degradation.invalid_line_count`.
- La commande `run RUN_ID` applique la même lecture tolérante et retourne le
  dernier enregistrement valide correspondant.
