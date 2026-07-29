# Status JSON

`bin/status_json.sh` exporte l'état local du moteur au format JSON.

## Commande

```bash
bash bin/status_json.sh
```

## Sortie

La commande renvoie un objet JSON :

```json
{
  "kind": "audit-suite.status",
  "schema_version": "1.1.0",
  "cwd": "/path/to/audit-suite",
  "checks": {
    "modules_dir_exists": true,
    "history_index_exists": false,
    "latest_exists": false
  },
  "counts": {
    "modules": 10,
    "history_runs": 0
  },
  "paths": {
    "history": "history",
    "history_index": "history/runs.jsonl",
    "history_latest": "history/latest.json"
  },
  "dependencies": {
    "required": [],
    "optional": []
  },
  "capabilities": {
    "platform": {
      "family": "linux",
      "supported": true,
      "reference": "Kali/Linux"
    },
    "environment_detection": {
      "iproute2_available": true,
      "degraded_without_iproute2": true
    },
    "api": {
      "python3_available": true,
      "minimum_version": "3.10",
      "minimum_version_met": true,
      "engine_usable_without_python": true
    },
    "privileges": {
      "raw_socket_available": false,
      "fallback": "tcp_connect_without_os_detection_and_udp"
    }
  }
}
```

## Objectif

Ce format prépare :

- le diagnostic local avant lancement ;
- l'affichage d'un état de santé dans une future interface web ;
- l'intégration avec un futur backend API ;
- les tests automatisés autour de l'environnement local.

## Notes

- La commande nécessite `jq` pour produire le JSON.
- Les capacités n’exposent ni utilisateur, ni chemin d’outil, ni interface, ni
  adresse réseau.
- `raw_socket_available` décrit la capacité courante ; les exigences précises
  par module sont dans `bin/modules_json.sh`.
- Elle respecte `AUDIT_HISTORY_DIR`.
- Elle ne modifie aucun fichier.
- Elle ne lance aucun module.
