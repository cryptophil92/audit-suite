# Versions et releases

## Source canonique

La version applicative est définie uniquement dans le fichier racine
[`VERSION`](../VERSION). Elle respecte
[Semantic Versioning 2.0.0](https://semver.org/lang/fr/).

Les commentaires `@version` encore présents dans certains scripts décrivent
l'historique de ces composants et ne constituent pas la version du produit.

Les consommateurs suivants lisent ou valident la source canonique :

- `./audit.sh --version` ;
- `bash bin/version_json.sh` ;
- l'en-tête serveur et `/api/health` ;
- le document servi par `/api/openapi.json` ;
- chaque `manifest.json` produit par un audit.

`api/openapi.json` est un consommateur généré. Ne modifiez pas sa version à la
main : utilisez `bash bin/sync_version.sh` après un changement de `VERSION`.

Le commit est résolu depuis Git. Pour une archive sans dossier `.git`, la
construction peut injecter un SHA avec `AUDIT_SUITE_COMMIT`. En l'absence de
ces deux sources, la valeur publiée est `unknown`.

## Stratégie de version

AUDIT-SUITE suit SemVer :

- `MAJOR` pour une incompatibilité publique ;
- `MINOR` pour une fonctionnalité compatible ;
- `PATCH` pour une correction compatible.

Le fichier `VERSION` décrit l'état du code. Une version n'est publiée que si un
tag immuable `vX.Y.Z` pointe vers le commit fusionné correspondant et qu'une
entrée datée existe dans [`CHANGELOG.md`](../CHANGELOG.md).

## Prérequis d'une release

- aucune issue ouverte `priority:P0` ou `priority:P1` destinée à la release ;
- CI verte sur `main` ;
- licence et attributions à jour ;
- section `Non publié` du changelog relue ;
- version et documentation cohérentes ;
- validation explicite du propriétaire du dépôt.

Le premier tag suivant `v0.1.2` reste interdit tant que ces prérequis ne sont
pas satisfaits.

## Procédure

1. Créer une branche `release/X.Y.Z` depuis `main`.
2. Modifier `VERSION` avec la nouvelle version.
3. Exécuter `bash bin/sync_version.sh` pour régénérer la version OpenAPI.
4. Transformer les changements concernés de `Non publié` en section
   `X.Y.Z — AAAA-MM-JJ` dans le changelog.
5. Exécuter :

   ```bash
   bash bin/sync_version.sh --check
   bash tests/test_version_consistency.sh
   bash tests/test_version_json.sh
   bash tests/test_manifest_schema.sh
   bash tests/test_api_server.sh
   bash bin/smoke_local.sh
   ```

6. Faire relire et fusionner la pull request de release.
7. Depuis le commit exact fusionné dans `main`, créer le tag annoté
   `vX.Y.Z`, puis le pousser.
8. Créer la GitHub Release correspondante avec les notes issues du changelog.

La stratégie initiale publie uniquement les archives sources générées par
GitHub. Aucun paquet exécutable ou installateur n'est déclaré officiel tant
qu'un workflow de packaging reproductible et ses sommes de contrôle ne sont
pas disponibles.

Un tag publié n'est jamais déplacé. Une erreur après publication donne lieu à
une nouvelle version corrective.
