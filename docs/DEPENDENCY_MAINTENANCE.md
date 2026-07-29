# Maintenance des dépendances CI

## Objectif

Les dépendances exécutées par GitHub Actions doivent rester récentes sans
introduire silencieusement du code tiers dans la chaîne de livraison. Toute
mise à niveau reste revue par une personne et doit conserver une CI verte,
sans scan réseau réel.

## Versions de référence

État vérifié le 29 juillet 2026 auprès des dépôts officiels :

| Action | Version lisible | Révision exécutée |
|---|---|---|
| `actions/checkout` | `v7.0.1` | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `actions/upload-artifact` | `v7.0.1` | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |

Les workflows utilisent la révision Git complète. Le commentaire placé à côté
du SHA conserve la version lisible pour la maintenance.

## Politique d’épinglage

- utiliser uniquement une action provenant de son dépôt officiel ;
- exécuter une révision Git complète de 40 caractères, jamais un tag mobile ;
- conserver le tag de version vérifié dans un commentaire ;
- limiter les permissions du workflow au strict nécessaire ;
- ne jamais activer la fusion automatique des mises à jour de dépendances ;
- documenter toute exception avant son introduction.

## Surveillance automatique

Dependabot vérifie les GitHub Actions chaque lundi à 06:00, heure de Paris. Il
peut ouvrir au maximum cinq pull requests simultanées vers `main`, avec les
labels `ci` et `technical-debt`.

Les alertes de vulnérabilités, les mises à jour de sécurité Dependabot et les
correctifs automatiques de sécurité sont activés dans les paramètres du dépôt.
Ils signalent ou proposent les changements ; ils ne remplacent pas la revue.

## Revue d’une mise à niveau

1. Lire les notes de version et les changements incompatibles depuis le dépôt
   officiel.
2. Vérifier que le tag annoncé pointe vers le SHA proposé, par exemple avec
   l’API GitHub ou `gh api`.
3. Pour une version majeure, relire les permissions et les entrées déclarées
   dans `action.yml`.
4. Inspecter le diff pour confirmer qu’aucune permission, aucun secret et
   aucune étape d’exécution ne sont ajoutés sans justification.
5. Exécuter les tests locaux sans scan réel, puis attendre tous les contrôles
   GitHub obligatoires.
6. Fusionner uniquement lorsque la CI est verte et que le SHA complet demeure
   épinglé.

En cas de régression, rétablir dans une nouvelle pull request le dernier SHA
connu comme sain. Ne pas supprimer la branche ni réécrire l’historique pour
masquer l’incident.
