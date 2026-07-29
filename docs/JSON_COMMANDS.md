# Commandes JSON locales

Ce document regroupe les commandes JSON disponibles dans AUDIT-SUITE.

## Version

```bash
bash bin/version_json.sh
```

Retourne la version courante et le commit source au format JSON. La version est
lue depuis le fichier racine `VERSION`.

## Routes

```bash
bash bin/routes_json.sh
```

Retourne le catalogue des chemins locaux exposés par l'API.

## Modules

```bash
bash bin/modules_json.sh
```

Retourne le catalogue complet, avec maturité, sélection, capacités,
intrusivité, privilèges, dépendances et limites. Voir
[`MODULE_CATALOG.md`](MODULE_CATALOG.md).

## Statut

```bash
bash bin/status_json.sh
```

Retourne l'état local du moteur, des dépendances et de l'historique.

## Historique

```bash
bash bin/history_json.sh list
bash bin/history_json.sh latest
bash bin/history_json.sh paths
```

Retourne l'historique local des runs au format JSON.

## Plan

```bash
bash bin/plan_json.sh --profile fast --targets 192.168.1.0/24 --categories all --run-id TEST_LOCAL
```

Retourne un plan d'exécution JSON sans lancer de module réel.

## Manifest et constats

```bash
bash bin/manifest_json.sh validate output/AUDIT_1/manifest.json
bash bin/manifest_json.sh normalize output/AUDIT_1/manifest.json
```

Valide le schéma manifest et le contrat `findings[]`, ou normalise en lecture
les schémas `1.0.0`, `1.1.0` et `1.2.0` sans modifier le fichier source.

## Snapshot API

```bash
bash bin/api_snapshot_json.sh
```

Retourne un snapshot JSON combinant les données principales exposables au dashboard.

## Smoke local

```bash
bash bin/smoke_local.sh
```

Contrôle les sorties JSON principales et le dry-run sans lancer de module réel.

## Garanties communes

- Lecture seule pour les commandes de consultation.
- Aucun scan réel lancé par les commandes de planification ou de snapshot.
- Aucune création de dossier de run hors commandes explicitement prévues pour l'exécution.
- Tests CI dédiés pour les commandes structurantes.
