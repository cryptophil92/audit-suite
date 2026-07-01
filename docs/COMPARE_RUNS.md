# Comparaison de deux audits

Depuis `v0.2.3-compare-runs`, AUDIT-SUITE peut comparer deux manifests d'audit sans relancer de scan.

## Commande

Sortie texte :

```bash
bash bin/compare_runs.sh output/AUDIT_1/manifest.json output/AUDIT_2/manifest.json
```

Sortie JSON :

```bash
bash bin/compare_runs.sh --json output/AUDIT_1/manifest.json output/AUDIT_2/manifest.json
```

## Entrées

La commande prend deux fichiers :

1. manifest avant ;
2. manifest après.

Les manifests doivent contenir au minimum :

- `run_id` ;
- `modules[]`.

Le schéma `v1.0.0` issu de `docs/REPORT_SCHEMA.md` est supporté.

## Sortie JSON

La sortie JSON a le type logique :

```json
{
  "kind": "audit-suite.compare",
  "schema_version": "1.0.0"
}
```

Elle contient :

- `before` : résumé du premier audit ;
- `after` : résumé du second audit ;
- `summary` : compteurs de comparaison ;
- `modules` : comparaison module par module.

## Changements détectés

Valeurs possibles pour `modules[].change` :

- `added` : module présent seulement dans le second audit ;
- `removed` : module présent seulement dans le premier audit ;
- `status_changed` : statut changé, par exemple `success` -> `failed` ;
- `rc_changed` : statut identique mais code retour différent ;
- `unchanged` : pas de changement notable.

## Régressions et améliorations

Le résumé calcule aussi :

- `regression_count` ;
- `improvement_count`.

Une régression correspond par exemple à :

- `success` -> `failed` ;
- `success` -> `skipped` ;
- `skipped` -> `failed`.

Une amélioration correspond par exemple à :

- `failed` -> `success` ;
- `skipped` -> `success` ;
- `failed` -> `skipped`.

## Objectif

Cette étape prépare :

- un futur écran de comparaison dans l'interface web ;
- les exports HTML/PDF comparatifs ;
- l'analyse de dérive entre deux audits ;
- l'API locale de consultation d'historique.

Aucun scan réseau n'est lancé par cette commande.
