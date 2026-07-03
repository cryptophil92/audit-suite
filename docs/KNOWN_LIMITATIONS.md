# Limites connues avant test local réel

Ce document liste les limites connues de la pile actuelle avant validation sur machine locale.

## État actuel

La pile contient :

- un moteur Bash renforcé ;
- des sorties JSON locales ;
- un historique local ;
- des rapports HTML et archives ;
- un smoke test ;
- une API locale en lecture seule ;
- un premier dashboard local ;
- une documentation de test et de fusion.

## Limites non bloquantes

### Pas encore testé sur machine locale réelle

La CI valide les scripts et les tests automatisés, mais ne remplace pas un test réel sur ta machine.

À vérifier localement :

- chemins réels ;
- droits d'exécution ;
- dépendances installées ;
- comportement navigateur ;
- lancement API locale ;
- dry-run complet.

### API locale volontairement limitée

L'API reste en lecture seule.

Elle ne doit pas encore :

- lancer un audit réel ;
- modifier l'historique ;
- créer un run ;
- exposer l'écoute hors `127.0.0.1`.

### Dashboard volontairement limité

Le dashboard sert à consulter et préparer.

Il ne doit pas encore :

- déclencher une exécution réelle ;
- modifier des fichiers ;
- gérer une authentification ;
- exposer des fonctions hors usage local.

### OpenAPI basique

La spécification OpenAPI est volontairement simple.

Elle pourra être enrichie après test local avec :

- schémas détaillés ;
- exemples complets ;
- documentation de chaque champ JSON ;
- validation automatisée de cohérence routes/spec.

## Limites à traiter plus tard

- Gestion propre des erreurs côté dashboard.
- Lecture détaillée des anciens runs depuis l'interface.
- Affichage HTML des rapports générés.
- Contrôleur d'exécution sécurisé avec confirmation explicite.
- Authentification locale si exposition hors localhost un jour.
- Tests manuels sur réseau personnel ou lab.

## Règle de prudence

Tant que le test local réel n'est pas effectué, garder toutes les PR en brouillon et ne pas fusionner.
