# Roadmap UX

## État des lots au 29 juillet 2026

| Lot | État | Reste principal |
|---|---|---|
| UX-0 — Fiabilité | Runner CI automatique et socle principal fusionnés | Maintenance et préflight (#44, #47) |
| UX-1 — Constats | Contrat `1.0.0` fusionné | Adaptateurs des modules réels (#48) |
| UX-2 — Rapport premium | Première version fusionnée | Audit transversal et validation utilisateur (#54, #55) |
| UX-3 à UX-9 | Documentés, non implémentés dans le dashboard | #51 à #54 |
| UX-10 à UX-11 | Non réalisés | Recherche et captures synthétiques (#55) |

Séquence d’interface recommandée : clarifier les modules avec #48, sécuriser
le rendu avec #51, puis construire les vues résultats de #53. L’onboarding et
l’accessibilité de #52/#54 s’intègrent à chaque écran sans réintroduire
l’exécution Web.

## Lot UX-0 — Fiabilité avant habillage

Priorité P1.

- états moteur fiables ;
- différence succès/partiel/échec ;
- historique robuste ;
- erreurs API bornées ;
- données sensibles maîtrisées.

Le design ne doit pas masquer un résultat incertain.

## Lot UX-1 — Modèle de constats et notation

Priorité P1.

- objet `findings[]` versionné ;
- observation, potentiel, confirmé et information ;
- gravité, confiance et validation séparées ;
- preuve et provenance ;
- score facultatif et justifié ;
- impact, remédiation et vérification ;
- compatibilité des manifests hérités.

Livrable : contrat de l’issue
[#70](https://github.com/cryptophil92/audit-suite/issues/70).

État : contrat `1.0.0`, manifest `1.2.0`, validation, compatibilité héritée et
fixtures synthétiques implémentés. Les adaptateurs des modules réels restent à
compléter avec #48.

## Lot UX-2 — Rapport premium

Priorité P1.

- résumé exécutif ;
- couverture et limites ;
- constats priorisés ;
- plan d’action ;
- détail technique ;
- impression/PDF ;
- confidentialité et anonymisation.

Livrable : cible de l’issue
[#71](https://github.com/cryptophil92/audit-suite/issues/71) et
[`../PREMIUM_REPORT_SPEC.md`](../PREMIUM_REPORT_SPEC.md).

État : rendu privé et partageable, synthèse, tri, remédiation, annexe,
responsive et styles A4 implémentés sur fixtures synthétiques. Audit clavier,
lecteur d’écran, contraste et validation utilisateur restent à consolider dans
#54/#55.

## Lot UX-3 — Architecture et contenu

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

## Lot UX-4 — Onboarding

- état de l’environnement ;
- périmètre autorisé ;
- plan sans exécution ;
- explication des profils ;
- limites des modules.

Mesure : un utilisateur cible prépare un plan privé sans aide externe.

## Lot UX-5 — Historique et résultats

- liste d’audits ;
- détail synthétique ;
- provenance ;
- états partiels ;
- comparaison ;
- accès rapports ;
- constats et plan de remédiation.

Mesure : l’utilisateur identifie ce qui a réussi, échoué et changé.

## Lot UX-6 — Design system

- tokens ;
- composants ;
- thèmes ;
- rédaction ;
- exemples ;
- gouvernance.

Commencer par les composants nécessaires aux lots précédents.

## Lot UX-7 — Accessibilité et responsive

- clavier ;
- lecteurs d’écran ;
- contraste ;
- zoom ;
- 320/390 px ;
- tables et JSON ;
- rapports.

L’accessibilité est intégrée à chaque lot, puis auditée transversalement.

## Lot UX-8 — Erreurs et diagnostic

- erreurs actionnables ;
- retry ;
- détail technique ;
- export diagnostic ;
- état dégradé ;
- fraîcheur.

Mesure : l’utilisateur sait quoi faire après les cinq erreurs les plus fréquentes.

## Lot UX-9 — Export et partage

- prévisualisation ;
- anonymisation ;
- sélection de contenu ;
- formats ;
- empreinte ;
- avertissement de confidentialité.

## Lot UX-10 — Recherche utilisateur

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

## Lot UX-11 — Captures et démonstration

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
Modèle de constats
   ↓
Rapport premium
   ↓
Architecture → Onboarding
   ↓             ↓
Historique/Résultats
   ↓
Design system + Accessibilité
   ↓
Export + Démonstration
```

## No-Go

- exécution Web avant revue sécurité ;
- données réelles dans les prototypes ;
- alerte non sourcée ;
- couleur seule ;
- design system complet avant validation des parcours ;
- support plateforme annoncé sans preuve.
