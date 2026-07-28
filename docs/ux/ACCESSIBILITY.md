# Accessibilité

## Cible

Viser WCAG 2.2 niveau AA pour le tableau de bord et les rapports HTML, avec validation automatisée et manuelle.

Ce document définit une direction. Aucune conformité n’est revendiquée au 28 juillet 2026.

## Audit initial

### Présent

- langue française déclarée ;
- landmarks `header` et `main` ;
- titres structurés ;
- labels enveloppant les contrôles ;
- éléments natifs ;
- thème système.

### Écarts

- pas de lien d’évitement ;
- focus non spécifiquement stylé ;
- mises à jour asynchrones non annoncées ;
- tables sans caption/scope ;
- cases non regroupées dans un fieldset ;
- erreurs de formulaire non reliées aux champs ;
- absence de statut `aria-busy` ;
- zones scrollables non décrites ;
- contraste non mesuré ;
- responsive/zoom non testé ;
- JSON brut difficile cognitivement.

## Clavier

Critères :

- toutes les actions accessibles avec Tab/Shift+Tab ;
- ordre identique à l’ordre visuel ;
- focus visible à tout moment ;
- pas de piège clavier ;
- Échap ferme un dialogue sans perte ;
- Entrée et Espace respectent les comportements natifs ;
- focus replacé après navigation ou erreur.

## Lecteurs d’écran

- un `h1` unique ;
- landmarks nommés ;
- états dynamiques dans une région `aria-live="polite"` ;
- erreurs critiques avec `role="alert"` ;
- chargement via `aria-busy` ;
- libellés d’action explicites ;
- détails techniques repliables avec état annoncé ;
- tableaux avec caption et en-têtes.

## Formulaires

- label toujours visible ;
- aide liée par `aria-describedby` ;
- exemple distinct de la valeur ;
- erreur textuelle proche et liée ;
- résumé d’erreurs en tête ;
- pas de validation uniquement par couleur ;
- saisie conservée ;
- autocomplete désactivé seulement avec justification.

## Couleur et contraste

À vérifier pour chaque thème :

- texte normal 4.5:1 ;
- grand texte 3:1 ;
- contrôles et focus 3:1 ;
- bordures essentielles 3:1 ;
- états différenciés par texte/icône ;
- graphiques avec motifs ou labels.

## Zoom et reflow

Tester :

- 200 % sans perte de fonction ;
- 400 % avec reflow ;
- largeur 320 CSS px ;
- texte agrandi ;
- orientation portrait/paysage ;
- JSON et chemins longs.

## Mouvement

Toute animation future :

- respecte `prefers-reduced-motion` ;
- ne clignote pas ;
- n’est pas nécessaire à la compréhension ;
- peut être interrompue si longue.

## Cognition et langage

- résumer avant le détail ;
- phrases courtes ;
- terme technique expliqué ;
- ne pas dramatiser ;
- distinguer « aucun résultat », « non exécuté » et « erreur » ;
- étapes numérotées ;
- action suivante explicite.

## Cibles tactiles

- au moins 44 × 44 px pour les actions principales ;
- espace entre cibles ;
- aucune action destructive proche d’une action fréquente ;
- feedback immédiat.

## Rapports

- titre de document ;
- ordre de lecture ;
- tableaux sémantiques ;
- statut non color-only ;
- impression lisible ;
- liens nommés ;
- alt text pour toute future visualisation.

## Protocole de validation

### Automatique

- validateur HTML ;
- axe-core ou équivalent ;
- contraste ;
- lint des rôles/labels.

### Manuel

- clavier seul ;
- NVDA sur Windows ;
- VoiceOver sur macOS/iOS si support visé ;
- zoom navigateur ;
- thème sombre ;
- mode contraste élevé ;
- lecture du rapport exporté.

### Utilisateur

Inclure au moins :

- une personne utilisant le clavier ;
- une personne avec basse vision ou fort zoom ;
- un utilisateur non expert pour la charge cognitive.

## Definition of Done

- aucun blocage clavier ;
- focus visible ;
- erreurs annoncées ;
- contraste AA vérifié ;
- reflow 320 px ;
- mises à jour dynamiques annoncées ;
- rapport navigable ;
- résultats documentés dans la PR.
