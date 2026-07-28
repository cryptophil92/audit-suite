# Limites connues

> État révisé après l’audit du 28 juillet 2026. Voir
> [`audit/TECHNICAL_AUDIT_2026-07-28.md`](audit/TECHNICAL_AUDIT_2026-07-28.md)
> pour les preuves, priorités et recommandations.

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

## Limites bloquantes ou importantes

- des sorties d’audit sont encore suivies dans l’historique Git public ;
- le FIFO de logging peut bloquer une exécution POSIX faute de lecteur ;
- plusieurs modules masquent les erreurs des outils ;
- l’API ne borne pas la durée ni la taille des sous-processus ;
- les versions publiées par les composants et les tags divergent.

Ne pas considérer le moteur prêt pour une mission professionnelle avant traitement.

## Limites non bloquantes

### Pas encore validé sur Kali réel après audit

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

## Limites corrigées dans l'état de code non publié

- Une ligne JSONL invalide ou tronquée ne rend plus l'historique et le
  snapshot indisponibles : les entrées valides sont conservées et la
  dégradation est signalée.
- Les écritures de l'historique sont sérialisées, `latest.json` est remplacé
  atomiquement et un `run_id` ne peut plus être réservé par deux processus.
