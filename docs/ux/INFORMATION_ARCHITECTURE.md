# Architecture de l’information

## Objectif

Organiser l’interface selon les tâches réelles sans activer prématurément l’exécution d’audits depuis le Web.

## Architecture cible v0.x

```text
Audit Suite
├── Vue d’ensemble
│   ├── État local
│   ├── Dernier audit
│   ├── Constats prioritaires
│   ├── Actions recommandées
│   └── Limites actives
├── Préparer un audit
│   ├── Périmètre autorisé
│   ├── Cibles
│   ├── Profil
│   ├── Vérifications
│   └── Aperçu du plan
├── Historique
│   ├── Liste
│   ├── Détail
│   └── Comparaison
├── Rapports
│   ├── Rapports disponibles
│   ├── Résumé exécutif
│   ├── Constats et plan d’action
│   ├── Prévisualisation
│   └── Export/anonymisation
├── Diagnostic
│   ├── Dépendances
│   ├── API
│   ├── Modules
│   └── Journaux techniques
└── Aide et cadre légal
    ├── Démarrage
    ├── Vocabulaire
    ├── Usage autorisé
    ├── Données locales
    └── Sécurité
```

## Ce qui existe

| Destination | Données actuelles | État |
|---|---|---|
| Vue d’ensemble | status, modules, history, latest | Présent sous forme de cartes/JSON |
| Préparer | route `/api/plan` | Présent |
| Historique | list/latest/run | API/CLI, peu présenté |
| Rapports | fichiers locaux générés | Pas relié dans le Web |
| Diagnostic | status/routes/modules | Présent mais dispersé |
| Aide/légal | Markdown | Hors interface |

## Ce qui reste hors scope

- exécution réelle depuis le Web ;
- modification/suppression de l’historique ;
- authentification distante ;
- gestion de comptes ;
- synchronisation cloud ;
- recommandations automatiques non produites par le moteur.

## Modèle de navigation

### Desktop

- barre latérale persistante ;
- contenu principal ;
- panneau de diagnostic contextuel facultatif.

### Mobile

- en-tête compact ;
- bouton menu explicite ;
- navigation en panneau ;
- action primaire unique par écran ;
- tables adaptées en cartes ou défilement annoncé.

## Priorité des informations

1. sécurité et état de confiance ;
2. tâche actuelle ;
3. résultat principal ;
4. détail explicatif ;
5. diagnostic technique.

Les routes API, chemins locaux et JSON bruts doivent être secondaires et repliables.

## Objets d’information

### État local

- disponibilité ;
- dépendances ;
- plateforme ;
- version ;
- fraîcheur ;
- limites.

### Plan

- cible ;
- profil ;
- vérifications ;
- options ;
- privilèges ;
- durée estimée ;
- périmètre autorisé.

### Audit enregistré

- identifiant ;
- date ;
- version ;
- statut ;
- périmètre ;
- durée ;
- vérifications ;
- chemins ;
- intégrité.

### Résultat de vérification

- nom ;
- maturité ;
- statut ;
- code retour ;
- durée ;
- raison ;
- sortie ;
- confiance.

### Constat

- identifiant stable ;
- type : observation, potentiel, confirmé ou information ;
- actif et service ;
- gravité ;
- score optionnel, méthode et justification ;
- confiance ;
- état de validation ;
- observation et impact ;
- preuves et provenance ;
- remédiation, effort et risque du changement ;
- méthode de vérification ;
- références et limites.

### Rapport

- format ;
- date ;
- source ;
- couverture et limites ;
- résumé exécutif ;
- constats priorisés ;
- plan de remédiation ;
- contenu sensible ;
- empreinte ;
- destination.

## URL proposées

```text
/
/plan
/history
/history/:runId
/compare
/reports
/diagnostics
/help
/legal
```

Ce routage est une direction UX, pas une demande de framework.

## Recherche et filtres

À ajouter seulement lorsque les volumes le justifient :

- historique : date, statut, profil ;
- modules : catégorie, maturité, disponibilité ;
- résultats : état, type, confiance ;
- rapports : run, format.

## Critères d’acceptation

- un nouvel utilisateur trouve le diagnostic et le plan en moins de deux actions ;
- l’exécution réelle n’est jamais suggérée comme disponible dans le Web ;
- les informations sensibles sont signalées avant export ;
- le détail technique reste accessible sans dominer ;
- navigation clavier et landmarks cohérents.
