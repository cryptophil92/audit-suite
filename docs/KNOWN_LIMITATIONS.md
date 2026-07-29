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

Ne pas considérer le moteur prêt pour une mission professionnelle avant traitement.

Les commandes structurantes des modules propagent désormais leurs erreurs et les étapes facultatives peuvent produire un état `partial`. Cette mécanique reste à valider sur un run Kali autorisé avant de considérer les résultats fiables en production.

## Limites non bloquantes

### Bus d’événements désactivé

Le logging écrit uniquement dans `logs/<RUN_ID>/combined.log`. L’ancien FIFO sans consommateur a été désactivé pour garantir que `emit` ne bloque pas sur POSIX. Toute réintroduction d’un bus d’événements devra définir le cycle de vie du lecteur et conserver un test de non-blocage.

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
- exposer l'écoute hors d’une adresse loopback littérale.

### Dashboard volontairement limité

Le dashboard sert à consulter et préparer.

Il ne doit pas encore :

- déclencher une exécution réelle ;
- modifier des fichiers ;
- gérer une authentification ;
- exposer des fonctions hors usage local.

### Rapport centré sur l’exécution

Le manifest `1.2.0` accepte des constats structurés, mais les modules réels ne
disposent pas encore tous d’un adaptateur. Le rapport HTML actuel présente
uniquement le contexte et l’état des modules. Il ne contient pas encore :

- l’affichage des constats, gravités, confiances et notes ;
- les preuves et remédiations du contrat `findings[]` ;
- de résumé exécutif ou plan d’action.

Voir [`FINDINGS_CONTRACT.md`](FINDINGS_CONTRACT.md),
[`PREMIUM_REPORT_SPEC.md`](PREMIUM_REPORT_SPEC.md) et l’issue #71.

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

Une correction qui dépend du comportement réel des outils réseau ne doit pas
être déclarée validée en production sans test Kali/lab autorisé. Les lots
documentaires, gardes et tests déterministes peuvent être fusionnés après
contrôles automatisés et validation explicite du propriétaire, sans créer de
release.

## Limites corrigées dans l'état de code non publié

- Les sous-processus des routes API ont des délais documentés, une limite de
  sortie combinée et des erreurs structurées en cas de dépassement.
- Le snapshot calcule ses quatre sources en parallèle et reste soumis au même
  budget de 15 secondes sur Windows comme sur Linux.
- Une ligne JSONL invalide ou tronquée ne rend plus l'historique et le
  snapshot indisponibles : les entrées valides sont conservées et la
  dégradation est signalée.
- Les écritures de l'historique sont sérialisées, `latest.json` est remplacé
  atomiquement et un `run_id` ne peut plus être réservé par deux processus.
