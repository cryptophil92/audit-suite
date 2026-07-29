# Catalogue JSON des modules

`bin/modules_json.sh` génère le catalogue complet des modules, y compris les
placeholders et chemins obsolètes qui ne sont pas sélectionnables.

## Commande

```bash
bash bin/modules_json.sh
```

## Sortie

La commande renvoie un objet JSON :

```json
{
  "kind": "audit-suite.modules",
  "schema_version": "1.2.0",
  "count": 10,
  "selectable_count": 6,
  "maturity_counts": {
    "experimental": 5,
    "partial": 1,
    "placeholder": 3,
    "deprecated": 1,
    "unknown": 0
  },
  "report_pipeline": {
    "canonical_command": "bash bin/finalize_reports.sh <manifest.json>",
    "timing": "after_manifest",
    "legacy_module": "90_report_pack.sh",
    "compatibility": "preserved_but_not_selectable_and_creates_no_archive"
  },
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "10_network_discovery.sh",
      "display_name": "Découverte réseau",
      "path": "modules/10_network_discovery.sh",
      "order": 10,
      "executable": true,
      "maturity": "experimental",
      "selectable": true,
      "capabilities": ["host_discovery"],
      "intrusiveness": "low",
      "privileges": ["standard_user"],
      "limitations": "Découverte Nmap uniquement…",
      "requirements": {
        "commands": ["nmap"],
        "raw_socket_profiles": [],
        "raw_socket_for_udp": false,
        "degraded_fallback": null
      }
    }
  ]
}
```

## Champs

- `id` : nom sans extension `.sh`.
- `name` : nom du fichier.
- `display_name` : nom compréhensible destiné à l’interface.
- `path` : chemin local du module.
- `order` : ordre numérique extrait du préfixe.
- `executable` : indique si le fichier possède le bit exécutable.
- `maturity` : `experimental`, `partial`, `placeholder`, `deprecated` ou
  `unknown`.
- `selectable` : inclusion possible dans un plan d’audit.
- `capabilities` : fonctions réellement implémentées.
- `intrusiveness` : niveau indicatif de sollicitation de la cible.
- `privileges` : privilèges standard et capacités optionnelles.
- `limitations` : couverture réduite ou absente à afficher.
- `requirements.commands` : commandes nécessaires au module.
- `requirements.raw_socket_profiles` : profils qui utilisent des sockets
  brutes.
- `requirements.raw_socket_for_udp` : besoin de sockets brutes pour l’étape
  UDP facultative.
- `requirements.degraded_fallback` : couverture conservée lorsque la capacité
  manque, ou `null`.

## Objectif

Ce format fournit :

- une liste honnête et filtrable pour le dashboard ;
- une sélection `all` limitée aux capacités utilisables ;
- les tests automatisés autour de la sélection de modules.

## Notes

- La commande nécessite `jq`.
- Les fichiers `_TEMPLATE` sont exclus.
- La commande lit uniquement les fichiers du dossier `modules/`.
- Elle ne lance aucun module ni trafic réseau.
- Les règles de maturité, la matrice courante et la migration `1.1.0` vers
  `1.2.0` sont détaillées dans
  [`MODULE_CATALOG.md`](MODULE_CATALOG.md).
