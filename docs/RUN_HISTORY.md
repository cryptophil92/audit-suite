# Historique local des audits

Depuis le lot `v0.2.1-run-history`, AUDIT-SUITE tient un historique local des audits exécutés.

## Fichiers générés

Les fichiers d'historique sont générés dans :

```text
history/
```

Ce dossier est ignoré par Git.

Fichiers principaux :

```text
history/runs.jsonl
history/latest.json
```

## `runs.jsonl`

`runs.jsonl` contient une ligne JSON par audit.

Chaque ligne contient notamment :

- `run_id`
- `created_at`
- `profile`
- `targets`
- `options`
- `selected_modules`
- `module_count`
- `success_count`
- `failed_count`
- `skipped_count`
- `output_path`
- `manifest_path`

## `latest.json`

`latest.json` contient le dernier audit sous forme lisible, avec le détail des modules.

## Commandes

Lister les audits :

```bash
bin/history.sh list
```

Afficher le dernier audit :

```bash
bin/history.sh latest
```

Afficher le chemin de l'index :

```bash
bin/history.sh path
```

## Objectif

Ce système prépare la future API/backend sans introduire de base de données pour l'instant.

L'idée est de conserver une trace simple, portable et exploitable par :

- une future interface web ;
- un backend API ;
- des exports HTML/PDF ;
- des comparaisons entre audits.
