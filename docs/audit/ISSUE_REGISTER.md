# Registre des issues de l’audit du 28 juillet 2026

Ce registre relie les constats de l’audit aux issues GitHub créées. Les détails potentiellement sensibles restent volontairement absents des tickets publics.

État des issues vérifié sur GitHub le 30 juillet 2026 et préparé pour la
livraison du lot #79. Les descriptions de l’audit restent historiques ; la
colonne `Statut` indique l’état opérationnel après fusion du lot.

## Pilotage

- [#58 — Professionnalisation, fiabilisation et refonte UX d’Audit Suite](https://github.com/cryptophil92/audit-suite/issues/58)

## Constats et actions

| Issue | Priorité | Catégorie | Statut | Sujet |
|---|---|---|---|---|
| [#37](https://github.com/cryptophil92/audit-suite/issues/37) | P0 | Sécurité | Ouverte | Traiter les artefacts d’audit suivis dans le dépôt public |
| [#38](https://github.com/cryptophil92/audit-suite/issues/38) | P0 | Bug | Fermée | Éliminer le blocage du FIFO de logging sur POSIX |
| [#39](https://github.com/cryptophil92/audit-suite/issues/39) | P1 | Bug | Fermée | Représenter fidèlement les échecs, résultats partiels et modules désactivés |
| [#40](https://github.com/cryptophil92/audit-suite/issues/40) | P1 | Bug | Fermée | Rendre l’historique résilient à la corruption et aux écritures concurrentes |
| [#41](https://github.com/cryptophil92/audit-suite/issues/41) | P1 | Sécurité | Fermée | Empêcher l’exposition accidentelle de l’API hors loopback |
| [#42](https://github.com/cryptophil92/audit-suite/issues/42) | P1 | Performance | Fermée | Borner les sous-processus et le budget des routes API |
| [#43](https://github.com/cryptophil92/audit-suite/issues/43) | P1 | Tests | Fermée | Couvrir le moteur, les erreurs et tous les scripts dans une CI reproductible |
| [#44](https://github.com/cryptophil92/audit-suite/issues/44) | P1 | CI | Fermée | Mettre à niveau les GitHub Actions et activer la maintenance des dépendances |
| [#45](https://github.com/cryptophil92/audit-suite/issues/45) | P1 | Refactoring | Fermée | Unifier la version et formaliser les releases |
| [#46](https://github.com/cryptophil92/audit-suite/issues/46) | P1 | Documentation | Fermée | Choisir et publier une licence explicite |
| [#47](https://github.com/cryptophil92/audit-suite/issues/47) | P1 | Bug | Fermée | Ajouter un préflight des capacités, outils et privilèges |
| [#48](https://github.com/cryptophil92/audit-suite/issues/48) | P2 | Dette technique | Fermée | Clarifier la maturité des modules et supprimer la redondance de rapport |
| [#49](https://github.com/cryptophil92/audit-suite/issues/49) | P2 | Dette technique | Ouverte | Quarantiner les scripts historiques de patch et de mise à jour |
| [#50](https://github.com/cryptophil92/audit-suite/issues/50) | P2 | Refactoring | Ouverte | Générer routes, OpenAPI et documentation depuis une source cohérente |
| [#51](https://github.com/cryptophil92/audit-suite/issues/51) | P2 | Sécurité | Fermée | Éviter l’interprétation HTML des données dans le tableau de bord |
| [#52](https://github.com/cryptophil92/audit-suite/issues/52) | P2 | UX | Ouverte | Repenser l’onboarding, l’architecture de l’information et le cadre légal |
| [#53](https://github.com/cryptophil92/audit-suite/issues/53) | P2 | UX | Ouverte | Présenter clairement historique, résultats partiels, erreurs et exports |
| [#54](https://github.com/cryptophil92/audit-suite/issues/54) | P2 | Accessibilité | Ouverte | Mettre en place le design system, le responsive et WCAG 2.2 AA |
| [#55](https://github.com/cryptophil92/audit-suite/issues/55) | P3 | Recherche UX | Ouverte | Valider les personas, parcours et captures avec des utilisateurs |
| [#56](https://github.com/cryptophil92/audit-suite/issues/56) | P2 | Multiplateforme | Ouverte | Valider Kali/Linux et isoler les dépendances OS avant tout port |
| [#57](https://github.com/cryptophil92/audit-suite/issues/57) | P2 | Dette GitHub | Ouverte | Fermer proprement les anciennes PR et archiver les branches consolidées |
| [#70](https://github.com/cryptophil92/audit-suite/issues/70) | P1 | Produit | Fermée | Structurer les constats, preuves, gravité et notation des risques |
| [#71](https://github.com/cryptophil92/audit-suite/issues/71) | P1 | UX/Rapport | Fermée | Produire un rapport premium, priorisé et orienté remédiation |
| [#79](https://github.com/cryptophil92/audit-suite/issues/79) | P2 | Produit | Traitée par ce lot | Relier les sorties réelles des modules au contrat `findings[]` |

## Ordre recommandé

1. Décision privée sur le dernier P0 : #37.
2. Confiance de livraison : maintenir #43, #44 et #47.
3. Maintenir le rendu sûr du dashboard livré par #51.
4. Maintenir le premier adaptateur de constats #79, sur le catalogue #48 et le contrat #70.
5. Prochain lot de valeur : vues résultats et rapport #53, sur les lots #70/#71/#79.
6. Architecture, dette, UX et accessibilité : #49, #50, #52 et #54.
7. Validation utilisateur et plateforme : #55 et #56.
8. Dette GitHub, sans suppression implicite : #57.

Toute opération irréversible sur l’historique, les branches ou les anciennes pull requests exige un accord explicite du propriétaire.
