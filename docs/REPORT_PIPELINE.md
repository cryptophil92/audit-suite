# Pipeline de finalisation des rapports

AUDIT-SUITE finalise automatiquement les sorties locales après génération du
manifest. Ce chemin est l’unique pipeline canonique de rapport et de pack.

## Commande manuelle

```bash
bash bin/finalize_reports.sh output/RUN_1/manifest.json
```

La commande génère :

```text
output/RUN_1/report.html
output/RUN_1/RUN_1_report_pack.tar.gz
```

L’ancien module `modules/90_report_pack.sh` est conservé comme repère de
migration, mais il n’est plus sélectionnable et ne crée plus d’archive. Cela
évite un pack incomplet avant le manifest puis un second pack après le
manifest.

`report.html` est le rapport premium privé. Une copie partageable doit être
générée explicitement après revue :

```bash
bash bin/report_html.sh --shareable output/RUN_1/manifest.json
```

## Intégration dans `audit.sh`

Après l'exécution des modules, `audit.sh` effectue maintenant :

```text
validation de findings.json s’il existe
write_manifest_json
finalize_run_outputs
history_record_run
```

Cela garantit que :

- le manifest existe avant génération HTML ;
- un fichier de constats invalide ne peut pas être intégré au manifest ;
- le pack peut inclure le rapport HTML ;
- les copies partageables ou techniques ne sont pas ajoutées par erreur dans
  les résultats du pack privé ;
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

La compatibilité détaillée et le nouveau schéma du catalogue figurent dans
[`MODULE_CATALOG.md`](MODULE_CATALOG.md).
