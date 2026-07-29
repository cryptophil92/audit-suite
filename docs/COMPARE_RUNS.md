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

Les schémas manifest `1.0.0`, `1.1.0` et `1.2.0` issus de
`docs/REPORT_SCHEMA.md` sont supportés. Le résumé de comparaison expose le
nombre de constats notés et non notés ; la comparaison détaillée des constats
reste prévue avec l’interface des résultats.

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

Les statuts reconnus sont classés ainsi : `failed` < `skipped` < `partial` < `success`. Une transition vers un rang inférieur est une régression ; une transition vers un rang supérieur est une amélioration.

Une régression correspond par exemple à :

- `success` -> `partial` ;
- `success` -> `failed` ;
- `partial` -> `skipped` ;
- `skipped` -> `failed`.

Une amélioration correspond par exemple à :

- `failed` -> `success` ;
- `skipped` -> `partial` ;
- `partial` -> `success` ;
- `failed` -> `skipped`.

## Objectif

Cette étape prépare :

- un futur écran de comparaison dans l'interface web ;
- les exports HTML/PDF comparatifs ;
- l'analyse de dérive entre deux audits ;
- l'API locale de consultation d'historique.

Aucun scan réseau n'est lancé par cette commande.
