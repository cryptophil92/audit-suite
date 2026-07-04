# Run detail JSON

`bin/history_json.sh run RUN_ID` retourne un run précis depuis l'index local `history/runs.jsonl`.

## Exemple

```bash
bash bin/history_json.sh run SMOKE_LOCAL
```

## Format

```json
{
  "kind": "audit-suite.history.run",
  "schema_version": "1.0.0",
  "run_id": "SMOKE_LOCAL",
  "found": true,
  "paths": {
    "index": "history/runs.jsonl"
  },
  "run": {}
}
```

Si le run n'existe pas, `found` vaut `false` et `run` vaut `null`.

## Sécurité

Ce lot lit uniquement l'index d'historique. Il ne lit pas les manifests disque depuis un paramètre utilisateur.
