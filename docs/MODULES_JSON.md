# Catalogue JSON des modules

`bin/modules_json.sh` génère un catalogue JSON des modules disponibles.

## Commande

```bash
bash bin/modules_json.sh
```

## Sortie

La commande renvoie un objet JSON :

```json
{
  "kind": "audit-suite.modules",
  "schema_version": "1.0.0",
  "count": 2,
  "modules": [
    {
      "id": "10_network_discovery",
      "name": "10_network_discovery.sh",
      "path": "modules/10_network_discovery.sh",
      "order": 10,
      "executable": false
    }
  ]
}
```

## Champs

- `id` : nom sans extension `.sh`.
- `name` : nom du fichier.
- `path` : chemin local du module.
- `order` : ordre numérique extrait du préfixe.
- `executable` : indique si le fichier possède le bit exécutable.

## Objectif

Ce format prépare :

- l'affichage de la liste des modules dans une future interface web ;
- l'intégration avec un futur backend API ;
- les tests automatisés autour de la sélection de modules.

## Notes

- La commande nécessite `jq`.
- Les fichiers `_TEMPLATE` sont exclus.
- La commande lit uniquement les fichiers du dossier `modules/`.
