# Rapport HTML local

Depuis `v0.2.4-html-report`, AUDIT-SUITE peut générer un rapport HTML local à partir d'un `manifest.json`.

## Commande

Générer le rapport à côté du manifest :

```bash
bash bin/report_html.sh output/AUDIT_1/manifest.json
```

Cela crée :

```text
output/AUDIT_1/report.html
```

Générer vers un chemin explicite :

```bash
bash bin/report_html.sh output/AUDIT_1/manifest.json output/AUDIT_1/rapport.html
```

## Entrée

Le script lit les manifests AUDIT-SUITE `1.0.0`, `1.1.0` et `1.2.0` décrits
dans :

```text
docs/REPORT_SCHEMA.md
```

Champs utilisés :

- `run_id`
- `created_at`
- `profile`
- `targets`
- `options`
- `paths`
- `summary`
- `modules`

## Contenu du rapport

Le rapport contient :

- résumé global ;
- statut du run ;
- compte des modules ;
- succès / échecs / ignorés ;
- durée totale ;
- contexte d'exécution ;
- cibles ;
- options ;
- chemins de sortie ;
- tableau détaillé des modules.

## Limite actuelle

Ce rapport indique si les vérifications techniques ont réussi, échoué, été
ignorées ou produit un résultat partiel. Le manifest `1.2.0` peut contenir des
constats structurés, mais le HTML actuel ne les présente pas encore.

La cible du rapport premium est documentée dans
[`PREMIUM_REPORT_SPEC.md`](PREMIUM_REPORT_SPEC.md) et suivie par
[#71](https://github.com/cryptophil92/audit-suite/issues/71).

## Sécurité d'affichage

Les valeurs issues du JSON sont échappées avant insertion dans le HTML via `jq @html`.

Le rapport est un fichier statique local. Il ne lance aucun scan, ne contacte aucun service, et ne dépend d'aucun backend.

## Objectif

Cette étape prépare :

- l'export PDF futur ;
- le pack rapport ;
- l'affichage web ;
- la lecture rapide des résultats sans ouvrir le JSON brut.
