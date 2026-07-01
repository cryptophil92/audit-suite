# Plan JSON

`bin/plan_json.sh` génère un plan JSON sans créer de dossier de sortie et sans lancer de module.

## Commande

```bash
bash bin/plan_json.sh \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories all \
  --run-id AUDIT_TEST_LOCAL \
  --no-zeek \
  --no-suricata
```

## Sortie

La commande renvoie un objet JSON :

```json
{
  "kind": "audit-suite.plan",
  "schema_version": "1.0.0",
  "run_id": "AUDIT_TEST_LOCAL",
  "profile": "fast",
  "targets": ["192.168.1.0/24"],
  "categories": "all",
  "selected_modules": ["10_network_discovery.sh"],
  "options": {
    "allow_public": false,
    "no_udp": false,
    "no_zeek": true,
    "no_suricata": true
  },
  "paths": {
    "output": "output/AUDIT_TEST_LOCAL",
    "logs": "logs/AUDIT_TEST_LOCAL"
  }
}
```

## Objectif

Ce format prépare :

- l'affichage d'un plan dans une future interface web ;
- le contrôle des paramètres avant lancement ;
- l'intégration avec un futur backend API ;
- des tests locaux reproductibles.

## Notes

- La commande nécessite `jq`.
- Elle valide les cibles et les modules.
- Elle ne crée pas `output/<RUN_ID>`.
- Elle ne crée pas `logs/<RUN_ID>`.
