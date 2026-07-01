# Pack rapport local

Depuis `v0.2.5-report-pack`, AUDIT-SUITE peut générer une archive `.tar.gz` contrôlée depuis un `manifest.json`.

## Commande

Créer un pack à côté du manifest :

```bash
bash bin/report_pack.sh output/RUN_1/manifest.json
```

Cela crée par défaut :

```text
output/RUN_1/RUN_1_report_pack.tar.gz
```

Créer un pack vers un chemin explicite :

```bash
bash bin/report_pack.sh output/RUN_1/manifest.json output/RUN_1/RUN_1_report_pack.tar.gz
```

## Contenu du pack

Le pack contient un dossier racine :

```text
AUDIT_SUITE_REPORT_PACK_<RUN_ID>/
```

Avec, selon disponibilité :

```text
manifest.json
report.html
logs/
results/
README.txt
PACK_CONTENTS.txt
```

## Règles de copie

Le pack copie :

- le manifest demandé ;
- le rapport HTML situé à côté du manifest, s'il existe ;
- le dossier de logs indiqué par `manifest.paths.logs`, s'il existe ;
- les résultats présents dans `manifest.paths.output`, s'ils existent.

Le pack évite d'inclure :

- les archives déjà générées `*_report_pack.tar.gz` ;
- les fichiers temporaires nommés `tmp` ou `temp` ;
- le manifest et le rapport HTML en double dans `results/`.

## Objectif

Cette étape prépare :

- l'envoi ou l'archivage propre d'un résultat ;
- l'export PDF futur ;
- l'interface web ;
- une conservation plus fiable des audits terminés.

La commande ne lance aucune action réseau. Elle lit uniquement des fichiers locaux déjà générés.
