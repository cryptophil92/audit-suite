# Pipeline de finalisation des rapports

Depuis `v0.2.6-report-pipeline`, AUDIT-SUITE peut finaliser automatiquement les sorties locales après génération du manifest.

## Commande manuelle

```bash
bash bin/finalize_reports.sh output/RUN_1/manifest.json
```

La commande génère :

```text
output/RUN_1/report.html
output/RUN_1/RUN_1_report_pack.tar.gz
```

## Intégration dans `audit.sh`

Après l'exécution des modules, `audit.sh` effectue maintenant :

```text
write_manifest_json
finalize_run_outputs
history_record_run
```

Cela garantit que :

- le manifest existe avant génération HTML ;
- le pack peut inclure le rapport HTML ;
- l'historique reste enregistré après génération des fichiers finaux.

## Comportement en cas d'erreur

La finalisation des rapports est non bloquante dans `audit.sh`.

Si `report.html` ou le pack ne peuvent pas être générés, l'audit reste terminé et un warning est écrit dans les logs.

## Objectif

Cette étape évite de devoir relancer manuellement plusieurs commandes après chaque audit :

```bash
bash bin/report_html.sh output/RUN_1/manifest.json
bash bin/report_pack.sh output/RUN_1/manifest.json
```

La commande de finalisation ne lance aucune action réseau. Elle lit uniquement les fichiers locaux déjà produits.
