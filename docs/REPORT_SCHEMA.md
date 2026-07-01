# Schéma des résultats AUDIT-SUITE

Depuis `v0.2.2-report-schema`, le manifest de run contient un schéma versionné.

## Manifest

Chemin généré :

```text
output/<RUN_ID>/manifest.json
```

Type logique :

```json
{
  "kind": "audit-suite.manifest",
  "schema_version": "1.0.0"
}
```

## Champs racine

| Champ | Type | Description |
|---|---:|---|
| `schema_version` | string | Version du schéma manifest. |
| `kind` | string | Type logique du document. |
| `run_id` | string | Identifiant horodaté du run. |
| `created_at` | string | Date ISO de génération du manifest. |
| `profile` | string | Profil utilisé : `fast`, `full` ou `stealth`. |
| `targets` | array | Cibles validées. |
| `options` | object | Options d'exécution. |
| `paths` | object | Chemins principaux générés. |
| `selected_modules` | array | Modules demandés. |
| `summary` | object | Résumé exploitable par API/export. |
| `modules` | array | Résultat détaillé par module. |

## `summary`

```json
{
  "module_count": 3,
  "success_count": 2,
  "failed_count": 0,
  "skipped_count": 1,
  "total_duration_seconds": 42,
  "status": "success"
}
```

Valeurs possibles pour `summary.status` :

- `success` : au moins un module réussi et aucun module échoué ;
- `failed` : au moins un module échoué ;
- `empty` : aucun module exécuté ou enregistré.

## Résultat module

Chaque entrée de `modules[]` suit cette structure :

```json
{
  "id": "10_network_discovery",
  "name": "Découverte réseau",
  "path": "modules/10_network_discovery.sh",
  "status": "success",
  "rc": 0,
  "started_at": "2026-07-01T00:00:01+00:00",
  "finished_at": "2026-07-01T00:00:02+00:00",
  "duration_seconds": 1,
  "output_path": "output/AUDIT_.../10_network_discovery",
  "reason": ""
}
```

Valeurs possibles pour `modules[].status` :

- `success`
- `failed`
- `skipped`

## Objectif

Ce schéma prépare :

- l'API locale ;
- les exports HTML/PDF ;
- l'interface web ;
- la comparaison entre deux audits ;
- l'exploitation des résultats sans relire les logs bruts.
