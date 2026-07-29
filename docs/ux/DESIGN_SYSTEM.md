# Design system initial

## Positionnement

Interface sobre, technique et rassurante. L’objectif est la lisibilité et la confiance, pas une identité visuelle spectaculaire.

## Principes

1. **Fiabilité visible** — chaque résultat indique sa source, son état et sa fraîcheur.
2. **Progressive disclosure** — résumé clair, détail technique à la demande.
3. **Prudence** — aucune alerte dramatique sans preuve.
4. **Local** — rappeler où les données sont stockées.
5. **Accessible** — clavier, contraste, zoom et langage clair dès le départ.
6. **Cohérent** — mêmes états, mots et actions partout.

## Tokens sémantiques

Les valeurs finales doivent être testées. Ne pas coder les couleurs directement dans les composants.

```text
color.surface.canvas
color.surface.panel
color.surface.raised
color.text.primary
color.text.secondary
color.text.inverse
color.border.default
color.action.primary
color.action.primaryHover
color.action.focus
color.status.info
color.status.success
color.status.warning
color.status.danger
color.status.neutral
```

### Règles couleur

- la couleur ne porte jamais seule une information ;
- contraste texte normal au moins 4.5:1 ;
- grand texte au moins 3:1 ;
- composants et focus au moins 3:1 ;
- thèmes clair et sombre testés séparément ;
- gravité combinée à icône et libellé.

## Typographie

### Familles

- interface : pile système sans-serif ;
- code et identifiants : pile monospace système.

### Échelle proposée

| Rôle | Taille | Interligne |
|---|---:|---:|
| Titre page | 32 px | 40 px |
| Titre section | 24 px | 32 px |
| Titre carte | 18 px | 26 px |
| Corps | 16 px | 24 px |
| Petit | 14 px | 20 px |
| Code | 14 px | 20 px |

Éviter le texte utile sous 14 px.

## Espacement

Base 4 px :

```text
space.1 = 4
space.2 = 8
space.3 = 12
space.4 = 16
space.6 = 24
space.8 = 32
space.12 = 48
space.16 = 64
```

## Rayons et ombres

```text
radius.small = 4
radius.medium = 8
radius.large = 12
```

Ombres légères uniquement pour la hiérarchie. Préférer bordures et espace.

## Boutons

### Variantes

- primaire : action principale unique ;
- secondaire : action complémentaire ;
- discrète : navigation/contextuelle ;
- danger : action destructive, confirmation nécessaire.

### États

- repos ;
- hover ;
- focus visible ;
- active ;
- disabled avec raison ;
- loading avec libellé stable.

Ne pas utiliser « OK » seul. Préférer « Afficher le plan », « Réessayer » ou « Télécharger le rapport ».

## Champs

Chaque champ possède :

- libellé visible ;
- aide ;
- exemple si nécessaire ;
- état requis explicite ;
- erreur associée ;
- conservation de la saisie après erreur.

Les cibles doivent afficher un exemple privé et rappeler le périmètre autorisé.

## Cartes

Types :

- résumé ;
- état ;
- action recommandée ;
- résultat ;
- avertissement.

Une carte ne doit pas être cliquable sans affordance explicite.

## Tables

- `caption` visible ou accessible ;
- en-têtes avec `scope` ;
- alignement stable ;
- statut textuel ;
- tri annoncé ;
- alternative mobile ;
- défilement horizontal annoncé si inévitable.

## Niveaux d’état

| État | Usage | Libellé |
|---|---|---|
| Information | contexte neutre | Information |
| Succès | opération complète | Terminé |
| Partiel | résultat incomplet | Résultat partiel |
| Avertissement | attention requise | À vérifier |
| Erreur | opération échouée | Échec |
| Bloqué | précondition absente | Action requise |
| Inconnu | donnée non déterminée | État inconnu |

Ne pas confondre gravité d’une observation réseau et état technique d’un module.

## Notation des constats

Une note ne doit jamais apparaître seule. Le composant associe :

- score ou libellé « non noté » ;
- échelle ;
- méthode ;
- gravité textuelle ;
- confiance ;
- état de validation ;
- accès à la justification.

La gravité, la confiance et le statut de validation utilisent des libellés et
repères distincts. Une faible confiance ne transforme pas automatiquement une
gravité élevée en faible gravité ; elle indique que le constat doit être
confirmé.

Une future note globale ne doit pas être représentée comme une jauge avant que
sa formule, sa couverture et ses limites soient validées.

## Messages

Structure :

```text
Titre court
Ce qui s’est passé.
Ce qui reste disponible.
Action recommandée.
[Voir le détail technique]
```

## Icônes

- bibliothèque unique ;
- taille et trait cohérents ;
- libellé accessible ;
- pas d’icône seule pour une action ambiguë ;
- pas de cadenas pour promettre une sécurité non démontrée.

## Navigation

- lien d’évitement ;
- état actif textuel et visuel ;
- titre de page unique ;
- fil d’Ariane pour le détail d’un run ;
- position stable des actions.

## Thèmes

Le thème système reste le défaut. Les deux thèmes doivent avoir :

- palette sémantique propre ;
- contraste vérifié ;
- graphiques lisibles ;
- impression de rapport indépendante du thème ;
- aucun flash de thème.

## Rédaction

- phrases courtes ;
- verbes d’action ;
- éviter le jargon non expliqué ;
- employer « audit enregistré » avant « run » ;
- dire « non disponible » plutôt que « N/A » ;
- préciser « aucune donnée » versus « erreur de lecture » ;
- ne jamais annoncer « sécurisé » sans contexte.

## Composants prioritaires

1. bannière de statut ;
2. carte de synthèse ;
3. message d’erreur ;
4. sélecteur de vérifications ;
5. résumé de plan ;
6. liste d’historique ;
7. badge d’état ;
8. panneau de détail technique ;
9. dialogue d’export ;
10. navigation.
11. carte de constat ;
12. résumé exécutif ;
13. plan de remédiation.

## Gouvernance

Chaque nouveau composant doit documenter :

- rôle ;
- anatomie ;
- états ;
- contenu ;
- clavier ;
- accessibilité ;
- responsive ;
- exemple ;
- anti-pattern.
