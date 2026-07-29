# Registre des issues de l’audit du 28 juillet 2026

Ce registre relie les constats de l’audit aux issues GitHub créées. Les détails potentiellement sensibles restent volontairement absents des tickets publics.

## Pilotage

- [#58 — Professionnalisation, fiabilisation et refonte UX d’Audit Suite](https://github.com/cryptophil92/audit-suite/issues/58)

## Constats et actions

| Issue | Priorité | Catégorie | Sujet |
|---|---|---|---|
| [#37](https://github.com/cryptophil92/audit-suite/issues/37) | P0 | Sécurité | Traiter les artefacts d’audit suivis dans le dépôt public |
| [#38](https://github.com/cryptophil92/audit-suite/issues/38) | P0 | Bug | Éliminer le blocage du FIFO de logging sur POSIX |
| [#39](https://github.com/cryptophil92/audit-suite/issues/39) | P1 | Bug | Représenter fidèlement les échecs, résultats partiels et modules désactivés |
| [#40](https://github.com/cryptophil92/audit-suite/issues/40) | P1 | Bug | Rendre l’historique résilient à la corruption et aux écritures concurrentes |
| [#41](https://github.com/cryptophil92/audit-suite/issues/41) | P1 | Sécurité | Empêcher l’exposition accidentelle de l’API hors loopback |
| [#42](https://github.com/cryptophil92/audit-suite/issues/42) | P1 | Performance | Borner les sous-processus et le budget des routes API |
| [#43](https://github.com/cryptophil92/audit-suite/issues/43) | P1 | Tests | Couvrir le moteur, les erreurs et tous les scripts dans une CI reproductible |
| [#44](https://github.com/cryptophil92/audit-suite/issues/44) | P1 | CI | Mettre à niveau les GitHub Actions et activer la maintenance des dépendances |
| [#45](https://github.com/cryptophil92/audit-suite/issues/45) | P1 | Refactoring | Unifier la version et formaliser les releases |
| [#46](https://github.com/cryptophil92/audit-suite/issues/46) | P1 | Documentation | Choisir et publier une licence explicite |
| [#47](https://github.com/cryptophil92/audit-suite/issues/47) | P1 | Bug | Ajouter un préflight des capacités, outils et privilèges |
| [#48](https://github.com/cryptophil92/audit-suite/issues/48) | P2 | Dette technique | Clarifier la maturité des modules et supprimer la redondance de rapport |
| [#49](https://github.com/cryptophil92/audit-suite/issues/49) | P2 | Dette technique | Quarantiner les scripts historiques de patch et de mise à jour |
| [#50](https://github.com/cryptophil92/audit-suite/issues/50) | P2 | Refactoring | Générer routes, OpenAPI et documentation depuis une source cohérente |
| [#51](https://github.com/cryptophil92/audit-suite/issues/51) | P2 | Sécurité | Éviter l’interprétation HTML des données dans le tableau de bord |
| [#52](https://github.com/cryptophil92/audit-suite/issues/52) | P2 | UX | Repenser l’onboarding, l’architecture de l’information et le cadre légal |
| [#53](https://github.com/cryptophil92/audit-suite/issues/53) | P2 | UX | Présenter clairement historique, résultats partiels, erreurs et exports |
| [#54](https://github.com/cryptophil92/audit-suite/issues/54) | P2 | Accessibilité | Mettre en place le design system, le responsive et WCAG 2.2 AA |
| [#55](https://github.com/cryptophil92/audit-suite/issues/55) | P3 | Recherche UX | Valider les personas, parcours et captures avec des utilisateurs |
| [#56](https://github.com/cryptophil92/audit-suite/issues/56) | P2 | Multiplateforme | Valider Kali/Linux et isoler les dépendances OS avant tout port |
| [#57](https://github.com/cryptophil92/audit-suite/issues/57) | P2 | Dette GitHub | Fermer proprement les anciennes PR et archiver les branches consolidées |
| [#70](https://github.com/cryptophil92/audit-suite/issues/70) | P1 | Produit | Structurer les constats, preuves, gravité et notation des risques |
| [#71](https://github.com/cryptophil92/audit-suite/issues/71) | P1 | UX/Rapport | Produire un rapport premium, priorisé et orienté remédiation |

## Ordre recommandé

1. Confinement et correction des P0 : #37 et #38.
2. Fiabilité, sécurité, tests et gouvernance : #39 à #47.
3. Adaptateurs et vues résultats : #48 et #53, sur les lots #70/#71 livrés.
4. Architecture et dette technique : #49 à #51 et #57.
5. Refonte UX et accessibilité : #52 et #54.
6. Validation utilisateur et plateforme : #55 et #56.

Toute opération irréversible sur l’historique, les branches ou les anciennes pull requests exige un accord explicite du propriétaire.
