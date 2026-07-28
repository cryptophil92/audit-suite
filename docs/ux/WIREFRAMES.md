# Wireframes basse fidélité

Ces wireframes décrivent une direction. Ils ne représentent pas une interface implémentée.

## Vue d’ensemble desktop

```text
┌──────────────────────────────────────────────────────────────────┐
│ Audit Suite                 Données locales • API 127.0.0.1      │
├────────────────┬─────────────────────────────────────────────────┤
│ Vue d’ensemble │ État local                         [Actualiser] │
│ Préparer       │ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ Historique     │ │ Prêt ?   │ │ Version  │ │ Historique│          │
│ Rapports       │ │ Action   │ │ Écart    │ │ 12 audits │          │
│ Diagnostic     │ └──────────┘ └──────────┘ └──────────┘          │
│ Aide & légal   │                                                 │
│                │ Dernier audit                                   │
│                │ Statut partiel • 12 min • profil rapide         │
│                │ 6 terminées • 1 ignorée • 1 échouée             │
│                │ [Voir le détail] [Voir le rapport]              │
│                │                                                 │
│                │ Actions recommandées                            │
│                │ 1. Corriger la dépendance manquante             │
│                │ 2. Vérifier le résultat partiel                 │
└────────────────┴─────────────────────────────────────────────────┘
```

## Préparer un audit

```text
┌──────────────────────────────────────────────────────────────────┐
│ Préparer un audit                                                │
│ Aucun scan ne sera lancé depuis cette page.                      │
├──────────────────────────────────────────────────────────────────┤
│ 1. Périmètre autorisé                                            │
│ [ ] Je confirme disposer de l’autorisation nécessaire            │
│                                                                  │
│ 2. Cibles                                                        │
│ [ 192.168.1.0/24                                      ]          │
│ Réseau privé ou lab uniquement.                                  │
│                                                                  │
│ 3. Profil                                                        │
│ (•) Rapide   ( ) Approfondi   ( ) Discret                        │
│                                                                  │
│ 4. Vérifications                                                 │
│ [x] Découverte réseau       Stable • ~2 min                      │
│ [x] Ports principaux        Stable • privilèges standard         │
│ [ ] SNMP                    Placeholder • indisponible            │
│                                                                  │
│                                      [Afficher l’aperçu du plan] │
├──────────────────────────────────────────────────────────────────┤
│ Résumé du plan                                                   │
│ Cible privée • 2 vérifications • aucune exécution                │
│ [Copier le plan] [Voir le JSON technique]                        │
└──────────────────────────────────────────────────────────────────┘
```

## Historique

```text
┌──────────────────────────────────────────────────────────────────┐
│ Historique                                                       │
│ [Recherche________] [Statut ▾] [Profil ▾]                        │
├──────────────────────────────────────────────────────────────────┤
│ 28 juil.  14:32  AUDIT_LAB_012  Partiel  Rapide     [Ouvrir]     │
│ 27 juil.  09:10  AUDIT_LAB_011  Terminé  Rapide     [Ouvrir]     │
│ 20 juil.  16:44  AUDIT_LAB_010  Échec    Approfondi [Ouvrir]     │
├──────────────────────────────────────────────────────────────────┤
│ [Comparer deux audits]                                           │
└──────────────────────────────────────────────────────────────────┘
```

## Détail d’un audit

```text
┌──────────────────────────────────────────────────────────────────┐
│ Historique / AUDIT_LAB_012                                       │
│ Résultat partiel                                                 │
│ Certaines vérifications n’ont pas produit de résultat complet.   │
├──────────────────────────────────────────────────────────────────┤
│ Résumé     Périmètre     Version     Durée                        │
│ Partiel    Privé         0.x.y       12 min                       │
├──────────────────────────────────────────────────────────────────┤
│ Vérifications                                                    │
│ ✓ Découverte réseau          Terminée                            │
│ ! Ports principaux           Résultat partiel [Pourquoi ?]       │
│ – SNMP                       Ignorée : dépendance absente          │
├──────────────────────────────────────────────────────────────────┤
│ [Voir le rapport] [Préparer un audit similaire] [Détail JSON]    │
└──────────────────────────────────────────────────────────────────┘
```

## Erreur récupérable

```text
┌──────────────────────────────────────────────────────────┐
│ Historique partiellement indisponible                    │
│ Une entrée locale n’a pas pu être lue.                   │
│ Les modules et la préparation de plan restent disponibles.│
│                                                          │
│ [Réessayer] [Ouvrir le diagnostic]                       │
└──────────────────────────────────────────────────────────┘
```

## Mobile

```text
┌──────────────────────────┐
│ ☰ Audit Suite   Local ✓  │
├──────────────────────────┤
│ État local               │
│ ┌──────────────────────┐ │
│ │ Action requise       │ │
│ │ 1 dépendance manque  │ │
│ │ [Voir]               │ │
│ └──────────────────────┘ │
│                          │
│ Dernier audit            │
│ ┌──────────────────────┐ │
│ │ Résultat partiel     │ │
│ │ 28 juil. • 12 min    │ │
│ │ [Ouvrir]             │ │
│ └──────────────────────┘ │
│                          │
│ [Préparer un audit]      │
└──────────────────────────┘
```

## États vides

### Aucun historique

```text
Aucun audit enregistré
Préparez d’abord un plan, puis lancez-le depuis la CLI autorisée.
[Préparer un plan] [Voir le guide CLI]
```

### Aucun rapport

```text
Aucun rapport disponible
Les rapports sont générés après un audit terminé ou partiel.
[Voir l’historique]
```

## Règles de prototypage

- données exclusivement synthétiques ;
- pas de bouton « Lancer » tant que le contrôleur sécurisé n’existe pas ;
- états partiels présents dans tous les tests ;
- scénario historique corrompu ;
- navigation clavier testée dès la basse fidélité ;
- mobile testé avant le polish visuel.
