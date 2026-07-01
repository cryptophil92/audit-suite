# API Snapshot JSON

`bin/api_snapshot_json.sh` agrège plusieurs sorties JSON locales dans un seul objet.

## Commande

```bash
bash bin/api_snapshot_json.sh
```

## Contenu agrégé

La commande inclut :

- `status` : sortie de `bin/status_json.sh` ;
- `modules` : sortie de `bin/modules_json.sh` ;
- `history` : sortie de `bin/history_json.sh list` ;
- `latest` : sortie de `bin/history_json.sh latest`.

## Sortie

```json
{
  "kind": "audit-suite.api_snapshot",
  "schema_version": "1.0.0",
  "generated_at": "2026-07-01T12:00:00Z",
  "status": {},
  "modules": {},
  "history": {},
  "latest": {}
}
```

## Objectif

Ce format prépare :

- une lecture unique pour un futur backend API ;
- l'affichage rapide d'un tableau de bord web ;
- les diagnostics locaux avant lancement ;
- les tests automatisés de l'état global du moteur.

## Notes

- La commande nécessite `jq`.
- Elle respecte `AUDIT_HISTORY_DIR` via les scripts appelés.
- Elle ne crée pas de dossier de run.
- Elle ne lance aucun module.
