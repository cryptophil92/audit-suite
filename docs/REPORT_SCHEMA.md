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
  "schema_version": "1.1.0",
  "version": "X.Y.Z",
  "commit": "0123456789abcdef"
}
```

## Champs racine

| Champ | Type | Description |
|---|---:|---|
| `schema_version` | string | Version du schéma manifest. |
| `kind` | string | Type logique du document. |
| `version` | string | Version applicative lue depuis `VERSION`. |
| `commit` | string | Commit Git du code exécuté, ou `unknown`. |
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
  "success_count": 1,
  "partial_count": 1,
  "failed_count": 0,
  "skipped_count": 1,
  "total_duration_seconds": 42,
  "status": "partial"
}
```

Valeurs possibles pour `summary.status` :

- `success` : au moins un module réussi, sans module partiel ni échoué ;
- `partial` : au moins un module partiel et aucun module échoué ;
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
- `partial`
- `failed`
- `skipped`

## Contrat d’état des modules

- `success` : les étapes structurantes et facultatives demandées ont réussi.
- `partial` : les étapes structurantes ont réussi, mais au moins une étape explicitement facultative a échoué. Les fichiers utiles déjà produits sont conservés et `reason` explique la limitation.
- `failed` : une étape structurante, le contrat du module ou son délai a échoué. Un code non nul non déclaré ne peut jamais devenir `success`.
- `skipped` : le module n’a pas été exécuté, soit par option explicite déclarée avec `MOD_SKIP_OPTION`, soit parce qu’une dépendance manque.

Un module peut appeler `module_mark_partial "raison"` uniquement pour une étape réellement facultative. Les options `OPTS_NO_ZEEK` et `OPTS_NO_SURICATA` sont évaluées avant les dépendances afin de produire un état `skipped` déterministe, que les outils soient installés ou non.

Le schéma `1.1.0` ajoute `partial` et `summary.partial_count`. Les lecteurs doivent continuer à accepter les manifests `1.0.0`, où ce compteur est absent.

## Objectif

Ce schéma prépare :

- l'API locale ;
- les exports HTML/PDF ;
- l'interface web ;
- la comparaison entre deux audits ;
- l'exploitation des résultats sans relire les logs bruts.
