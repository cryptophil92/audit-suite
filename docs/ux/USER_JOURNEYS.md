# Parcours utilisateurs

## Convention

Chaque parcours distingue :

- intention ;
- étapes ;
- état actuel ;
- cible UX ;
- risques et preuves.

## Installer l’application

**Intention :** obtenir un environnement fonctionnel et vérifiable.

### Actuel

1. cloner le dépôt ;
2. ajouter les droits ;
3. exécuter `check_deps.sh` ;
4. résoudre manuellement les dépendances ;
5. lancer le smoke test.

### Cible

1. choisir « consultation locale » ou « moteur d’audit » ;
2. voir les prérequis et privilèges ;
3. exécuter un diagnostic non mutatif ;
4. obtenir un résumé prêt/bloqué/dégradé ;
5. lancer un smoke test ;
6. consulter l’action corrective exacte.

## Comprendre le cadre légal

1. lire l’avertissement avant le premier plan ;
2. sélectionner le type de périmètre autorisé ;
3. confirmer disposer de l’autorisation ;
4. voir pourquoi les cibles publiques sont bloquées ;
5. conserver la confirmation dans les métadonnées du run si une exécution est faite.

L’interface ne doit jamais transformer cette confirmation en simple case précochée.

## Sélectionner une interface réseau

### Actuel

Détection automatique Linux par `ip`; aucune sélection explicite dans le Web.

### Cible

1. afficher interfaces détectées ;
2. expliquer adresse et état ;
3. recommander l’interface probable ;
4. permettre un choix explicite ;
5. signaler privilèges et limites ;
6. enregistrer le choix dans le plan.

Ce parcours dépend d’une future fonction moteur et ne doit pas être simulé dans l’UI avant disponibilité.

## Préparer un premier audit

1. vérifier l’état local ;
2. saisir une cible privée ;
3. choisir un profil expliqué ;
4. choisir des vérifications avec maturité et durée estimée ;
5. afficher les options et privilèges ;
6. générer un aperçu ;
7. vérifier périmètre, commandes et sorties attendues ;
8. copier ou exporter le plan.

Le bouton actuel correspond à l’étape 6, pas à une exécution.

## Lancer une analyse

Non disponible depuis le Web.

### Cible future, sous réserve de sécurité

1. partir d’un plan validé ;
2. confirmer le périmètre ;
3. confirmer les vérifications intrusives ;
4. afficher les privilèges ;
5. démarrer avec identifiant unique ;
6. offrir annulation et journal ;
7. ne jamais masquer les résultats partiels.

Ce parcours nécessite une revue de sécurité séparée.

## Suivre la progression

### Besoins

- étape actuelle ;
- nombre de vérifications terminées ;
- durée ;
- état par module ;
- dépendances manquantes ;
- annulation ;
- résultat partiel conservé.

### États

```text
préparé → en cours → terminé
                 ↘ partiel
                 ↘ annulé
                 ↘ échoué
```

## Comprendre les appareils détectés

### Cible

1. vue liste avec identifiant anonymisable ;
2. adresse locale, nom et fabricant seulement si disponibles ;
3. services détectés ;
4. provenance et horodatage ;
5. niveau de confiance ;
6. filtre et recherche ;
7. détail sans interprétation excessive.

Le moteur actuel ne fournit pas encore un modèle d’appareil consolidé.

## Identifier les alertes

1. distinguer observation, alerte et vulnérabilité potentielle ;
2. afficher gravité, confiance et source ;
3. expliquer le risque sans dramatiser ;
4. proposer une vérification manuelle ;
5. ne jamais présenter un script NSE comme preuve définitive ;
6. permettre l’export.

Ce parcours nécessite un modèle de données absent aujourd’hui.

## Comprendre et traiter un constat

### Cible

1. lire un titre et une explication en langage clair ;
2. identifier l’actif et le service concernés ;
3. distinguer observation, risque potentiel et vulnérabilité confirmée ;
4. voir séparément gravité, score éventuel, confiance et statut de validation ;
5. comprendre la méthode et la justification de la note ;
6. consulter la preuve et sa provenance ;
7. comprendre l’impact sans dramatisation ;
8. appliquer une remédiation avec effort et risque du changement ;
9. suivre une procédure de vérification ;
10. marquer le traitement ou comparer avec un audit ultérieur.

Un constat insuffisamment documenté reste `unscored` ou à confirmer. L’interface
ne complète jamais les champs manquants par une supposition.

## Consulter les recommandations

Chaque recommandation doit contenir :

- constat ;
- impact possible ;
- niveau de confiance ;
- action prudente ;
- prérequis et risque de l’action ;
- source ;
- statut de validation.

La structure cible est détaillée dans
[`../PREMIUM_REPORT_SPEC.md`](../PREMIUM_REPORT_SPEC.md).

## Exporter un rapport

### Actuel

Rapport HTML et archive générés localement.

### Cible

1. choisir le run ;
2. prévisualiser le contenu ;
3. voir les données sensibles incluses ;
4. anonymiser ;
5. sélectionner HTML ou archive ;
6. confirmer la destination ;
7. obtenir empreinte et liste des fichiers.

## Relancer ou comparer

1. sélectionner un run de référence ;
2. dupliquer son plan ;
3. modifier uniquement les champs nécessaires ;
4. lancer via CLI sécurisée ;
5. comparer les états ;
6. distinguer régression, amélioration et donnée absente.

## Gérer une erreur

Parcours cible :

1. identifier la zone affectée ;
2. conserver les zones utilisables ;
3. afficher un message non technique ;
4. proposer une action ;
5. ouvrir le détail avec commande, code et log anonymisé ;
6. réessayer sans perdre la saisie ;
7. permettre l’export diagnostic.

## Matrice de réussite

| Parcours | Preuve de réussite |
|---|---|
| Installer | smoke test et diagnostic verts |
| Comprendre le cadre | utilisateur reformule le périmètre |
| Préparer | plan valide sans création de run |
| Suivre | état et résultats partiels compris |
| Comprendre résultats | tâches prioritaires identifiées |
| Traiter un constat | preuve, risque, action et vérification reformulés correctement |
| Exporter | contenu sensible maîtrisé |
| Erreur | cause/action comprises sans documentation externe |
