# Audit UX actuel

## Périmètre

Audit documentaire et statique du 28 juillet 2026 portant sur :

- installation et premier lancement ;
- CLI et menus ;
- API locale ;
- tableau de bord `web/index.html` ;
- rapports HTML ;
- messages, états et confiance ;
- responsive et accessibilité.

Aucun test utilisateur ni audit sur appareil Kali réel n’a été réalisé. Les observations sont donc des constats experts à valider.

## Résumé

Le produit possède deux qualités UX fortes : il est local par défaut et sépare la consultation Web de l’exécution réelle. Le tableau de bord est léger, sans dépendance externe, et utilise des contrôles HTML natifs.

L’expérience reste néanmoins celle d’un prototype technique. L’utilisateur doit comprendre Bash, les noms de modules, les run IDs et les structures JSON. La page ne guide pas clairement le premier audit, n’explique pas les limites des modules et ne transforme pas les résultats en informations hiérarchisées. Les erreurs, chargements et états dégradés sont trop peu visibles pour inspirer confiance.

## Installation

### Faits

- installation par clonage Git ;
- dépendances système manuelles ;
- aucun installateur ni paquet ;
- `chmod` nécessaire ;
- API et moteur ont des prérequis différents ;
- le script `check_deps.sh` liste outils requis et optionnels.

### Problèmes

- pas de chemin « installation minimale en lecture seule » distinct de « moteur complet » ;
- versions minimales non précisées ;
- privilèges et capacités réseau non expliqués avant le lancement ;
- pas de diagnostic consolidé avec action corrective ;
- procédure de mise à jour et désinstallation absente.

### Recommandations

- trois parcours : consulter, préparer, exécuter ;
- diagnostic préalable lisible ;
- erreurs avec commande de résolution ;
- installation Kali vérifiée et versionnée ;
- ne pas promettre d’autres plateformes avant validation.

## Premier lancement

### Faits

- `audit.sh` tombe sur des menus ou valeurs par défaut ;
- l’API affiche directement le tableau de bord ;
- l’avertissement légal est surtout documentaire ;
- aucun onboarding dans la page Web.

### Risques

- l’utilisateur non expert ne sait pas si l’application est prête ;
- la différence entre plan et exécution peut être mal comprise ;
- le périmètre autorisé n’est pas confirmé au moment critique ;
- les placeholders peuvent être pris pour des fonctions complètes.

### Recommandation

Afficher un écran d’accueil local en trois étapes :

1. vérifier l’environnement ;
2. confirmer le périmètre autorisé ;
3. préparer un plan sans exécution.

## Navigation et architecture

### État actuel

Une page longue contient :

- trois cartes de synthèse ;
- formulaire de plan ;
- table des modules ;
- table des routes ;
- JSON du dernier run.

### Problèmes

- absence de navigation ou sommaire ;
- architecture orientée composants techniques plutôt que tâches ;
- historique et résultats confondus avec diagnostic ;
- routes API trop visibles pour l’utilisateur principal ;
- aucun chemin vers aide, sécurité ou rapports ;
- pas de contexte sur le run sélectionné.

### Direction

Navigation proposée :

- Vue d’ensemble ;
- Préparer un audit ;
- Historique ;
- Rapports ;
- Diagnostic ;
- Aide et cadre légal.

L’exécution réelle reste hors du Web.

## Hiérarchie visuelle

### Faits

- grille responsive pour les cartes ;
- cartes homogènes ;
- tables simples ;
- thèmes clair/sombre hérités du système ;
- nombreux styles en ligne et CSS monolithique.

### Problèmes

- toutes les sections ont un poids proche ;
- pas de navigation principale ;
- le JSON brut domine visuellement ;
- pas de hiérarchie de sévérité ;
- pas de design token ;
- tables susceptibles de dépasser sur petit écran ;
- état actif et focus peu différenciés.

## Terminologie

Termes actuellement visibles :

- moteur ;
- modules ;
- run ;
- Run ID ;
- routes API ;
- plan JSON ;
- `fast`, `full`, `stealth`.

Proposition rédactionnelle :

| Technique | Libellé utilisateur |
|---|---|
| run | audit enregistré |
| Run ID | identifiant de l’audit |
| modules | vérifications |
| plan JSON | aperçu technique du plan |
| snapshot | état local |
| routes API | diagnostic API |
| fast | rapide |
| full | approfondi |
| stealth | discret |

Conserver le terme technique en aide contextuelle lorsque nécessaire.

## Chargement, progression et erreurs

### Faits

- le chargement initial affiche « Chargement... » ;
- l’échec snapshot remplace plusieurs zones par du texte générique ;
- `loadPlan` n’affiche pas de busy state et n’a pas de gestion d’exception explicite ;
- l’API renvoie parfois stderr et commande ;
- aucune progression pour une opération réelle, qui n’est pas exposée au Web.

### Problèmes

- pas d’horodatage ni fraîcheur des données ;
- pas d’état partiellement disponible ;
- pas de bouton réessayer ;
- erreurs techniques sans explication ni action ;
- pas de rôle ARIA live ;
- plan non désactivé pendant l’appel ;
- absence d’annulation ou délai côté UI.

### Modèle recommandé

Chaque bloc doit gérer :

- chargement ;
- succès ;
- vide ;
- données partielles ;
- erreur récupérable ;
- erreur bloquante.

Chaque erreur doit dire :

1. ce qui n’a pas fonctionné ;
2. ce qui reste disponible ;
3. l’action suivante ;
4. où obtenir le détail technique.

## Résultats et rapports

### État

- dernier run affiché en JSON brut ;
- rapport HTML séparé généré localement ;
- comparaison disponible uniquement en CLI ;
- aucun lien direct depuis l’interface ;
- aucune hiérarchie d’alertes.

### Besoin

- résumé de confiance : complet, partiel, échoué ;
- date, durée, périmètre et profil ;
- vérifications réussies, ignorées et échouées ;
- appareils/services en vues adaptées ;
- recommandations expliquées ;
- accès au rapport et à l’export ;
- provenance de chaque résultat ;
- anonymisation avant partage.

Ne pas inventer d’alerte ou de recommandation que le moteur ne produit pas encore.

## Confiance et sécurité perçue

Points positifs :

- local-first ;
- lecture seule Web ;
- blocage public par défaut ;
- pas de dépendance front-end externe.

Points faibles :

- données sensibles suivies historiquement dans Git ;
- limites des modules peu visibles ;
- succès potentiellement trompeurs ;
- absence de statut de fraîcheur ;
- possibilité technique d’écouter hors loopback ;
- aucune explication de conservation/suppression des données dans l’UI.

## Responsive

### Risques observés

- tables sans conteneur de défilement ;
- padding fixe de 24 px ;
- formulaire long ;
- colonnes techniques ;
- JSON brut large ;
- absence de tests à 320/390 px et zoom 200 %.

### Cibles

- 320 px minimum sans perte d’action ;
- cartes empilées ;
- tables transformées ou défilables avec indication ;
- barre de navigation compacte ;
- zones tactiles d’au moins 44 × 44 px ;
- texte et JSON qui reviennent à la ligne sans masquer l’information.

## Accessibilité

### Points positifs

- `lang="fr"` ;
- labels associés par enveloppement ;
- contrôles natifs ;
- texte réel plutôt que canvas ;
- thème système clair/sombre.

### Écarts à vérifier/corriger

- focus visible ;
- contraste de `muted`, bordures et badges ;
- tables sans `caption` ni `scope` ;
- mises à jour dynamiques sans `aria-live` ;
- groupe de cases sans `fieldset`/`legend` ;
- messages d’erreur non associés aux champs ;
- absence de lien d’évitement ;
- ordre des titres et landmarks ;
- zoom 200/400 % ;
- mouvement futur avec `prefers-reduced-motion`.

Voir `ACCESSIBILITY.md`.

## Priorités UX

### P1

- rendre l’état du moteur et des données fiable ;
- expliquer plan versus exécution ;
- présenter les erreurs et états partiels ;
- protéger la confiance autour des résultats.

### P2

- architecture de l’information ;
- historique et rapports lisibles ;
- onboarding ;
- design system ;
- accessibilité et responsive.

### P3

- thèmes avancés ;
- préférences mémorisées ;
- personnalisation ;
- visualisations complexes.

## Points à valider

- vocabulaire préféré par les utilisateurs ;
- fréquence réelle des tâches ;
- besoin de comparaison entre audits ;
- valeur des vues appareils/alertes ;
- niveau technique des utilisateurs ;
- contraintes de handicap et équipements ;
- pertinence d’un contrôleur d’exécution Web futur.
