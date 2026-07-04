# Spécification OpenAPI

`api/openapi.json` décrit les routes JSON locales.

## Fichier

```text
api/openapi.json
```

## Route

```text
GET /api/openapi.json
```

## Vérifications couvertes

Le test serveur vérifie que :

- le document est servi en JSON ;
- la version OpenAPI est `3.0.3` ;
- les routes principales sont présentes.

## Objectif

Cette spécification prépare l'intégration future avec des outils de documentation, de test ou une interface web plus complète.
