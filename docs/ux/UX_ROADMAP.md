# Roadmap UX

## Lot UX-0 — Fiabilité avant habillage

Priorité P1.

- états moteur fiables ;
- différence succès/partiel/échec ;
- historique robuste ;
- erreurs API bornées ;
- données sensibles maîtrisées.

Le design ne doit pas masquer un résultat incertain.

## Lot UX-1 — Architecture et contenu

Priorité P2.

- navigation ;
- vocabulaire ;
- hiérarchie des tâches ;
- aide et cadre légal ;
- contenu des états vides et erreurs.

Livrables :

- sitemap validé ;
- inventaire contenu ;
- prototype basse fidélité ;
- test de compréhension.

## Lot UX-2 — Onboarding

- état de l’environnement ;
- périmètre autorisé ;
- plan sans exécution ;
- explication des profils ;
- limites des modules.

Mesure : un utilisateur cible prépare un plan privé sans aide externe.

## Lot UX-3 — Historique et résultats

- liste d’audits ;
- détail synthétique ;
- provenance ;
- états partiels ;
- comparaison ;
- accès rapports.

Mesure : l’utilisateur identifie ce qui a réussi, échoué et changé.

## Lot UX-4 — Design system

- tokens ;
- composants ;
- thèmes ;
- rédaction ;
- exemples ;
- gouvernance.

Commencer par les composants nécessaires aux lots précédents.

## Lot UX-5 — Accessibilité et responsive

- clavier ;
- lecteurs d’écran ;
- contraste ;
- zoom ;
- 320/390 px ;
- tables et JSON ;
- rapports.

L’accessibilité est intégrée à chaque lot, puis auditée transversalement.

## Lot UX-6 — Erreurs et diagnostic

- erreurs actionnables ;
- retry ;
- détail technique ;
- export diagnostic ;
- état dégradé ;
- fraîcheur.

Mesure : l’utilisateur sait quoi faire après les cinq erreurs les plus fréquentes.

## Lot UX-7 — Rapports et partage

- prévisualisation ;
- anonymisation ;
- sélection de contenu ;
- formats ;
- empreinte ;
- avertissement de confidentialité.

## Lot UX-8 — Recherche utilisateur

### Entretiens

- 5 à 8 participants sur 3 profils ;
- tâches et contexte ;
- partage et conservation ;
- compréhension du risque.

### Tests

- 5 participants par itération ;
- plan ;
- diagnostic ;
- historique ;
- erreur ;
- export.

### Mesures

- succès de tâche ;
- temps ;
- erreurs ;
- compréhension ;
- confiance ;
- charge perçue.

## Lot UX-9 — Captures et démonstration

- fixtures synthétiques ;
- captures clair/sombre ;
- desktop/mobile ;
- texte alternatif ;
- GIF/vidéo seulement si utile ;
- revue confidentialité.

## Dépendances

```text
Fiabilité
   ↓
Architecture → Onboarding
   ↓             ↓
Historique/Résultats
   ↓
Design system + Accessibilité
   ↓
Rapports + Démonstration
```

## No-Go

- exécution Web avant revue sécurité ;
- données réelles dans les prototypes ;
- alerte non sourcée ;
- couleur seule ;
- design system complet avant validation des parcours ;
- support plateforme annoncé sans preuve.
