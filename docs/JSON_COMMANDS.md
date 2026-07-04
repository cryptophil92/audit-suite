# Commandes JSON locales

Ce document regroupe les commandes JSON disponibles dans AUDIT-SUITE.

## Version

```bash
bash bin/version_json.sh
```

Retourne la version courante au format JSON.

## Routes

```bash
bash bin/routes_json.sh
```

Retourne le catalogue des chemins locaux exposés par l'API.

## Modules

```bash
bash bin/modules_json.sh
```

Retourne la liste structurée des modules disponibles.

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
bash bin/plan_json.sh --profile fast --targets 192.168.1.0/24 --categories all --run-id TEST_LOCAL --no-zeek --no-suricata
```

Retourne un plan d'exécution JSON sans lancer de module réel.

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
