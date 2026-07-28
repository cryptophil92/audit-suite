# Roadmap de professionnalisation

Cette roadmap traduit l’audit du 28 juillet 2026. Les priorités et estimations restent à valider par le propriétaire. L’[issue GitHub #58](https://github.com/cryptophil92/audit-suite/issues/58) constitue la source opérationnelle de pilotage ; le [registre des issues](audit/ISSUE_REGISTER.md) conserve la correspondance entre constats et actions.

## Principes

- aucune correction silencieuse ;
- une branche et une pull request par lot cohérent ;
- sécurité et fiabilité avant nouvelles fonctions ;
- pas d’exécution réelle depuis le Web avant revue de sécurité dédiée ;
- tests sans scan réseau dans la CI ;
- validation réelle uniquement sur un lab autorisé ;
- pas de réécriture multiplateforme prématurée.

## Phase 0 — Contenir les risques

Objectif : rendre le dépôt et le chemin de démarrage sûrs.

- traiter les sorties d’audit suivies dans Git ;
- corriger le blocage FIFO ;
- ajouter des gardes CI contre les artefacts runtime ;
- vérifier les canaux de signalement privé.

Critère de sortie : aucun risque P0 ouvert sans mesure temporaire documentée.

## Phase 1 — Fiabiliser le moteur

- propager les erreurs des outils ;
- distinguer succès, résultat partiel, échec et skip ;
- stabiliser Zeek/Suricata et les placeholders ;
- tester le runner avec des doubles ;
- gérer interruption, timeout et privilèges ;
- coordonner les exécutions concurrentes.

Critère de sortie : un manifest ne peut pas déclarer un succès lorsque la commande structurante a échoué.

## Phase 2 — Stabiliser données et API

- tolérer un historique partiellement corrompu ;
- verrouiller et écrire atomiquement ;
- borner les sous-processus API ;
- restreindre l’écoute réseau ;
- unifier routes et OpenAPI ;
- ajouter pagination et diagnostic dégradé.

Critère de sortie : une entrée locale invalide ne rend pas tout le tableau de bord indisponible.

## Phase 3 — Installation, CI et releases

- matrice de dépendances et privilèges ;
- CI générée à partir de la liste des tests ;
- fins de lignes reproductibles ;
- mise à jour contrôlée des actions ;
- source de version unique ;
- licence Apache 2.0 et attributions tierces publiées ;
- première release documentée.

Critère de sortie : un nouveau contributeur peut installer, tester et identifier précisément la version.

## Phase 4 — UX en lecture seule

- onboarding et périmètre légal ;
- architecture de l’information ;
- états de chargement, vide, erreur et dégradation ;
- historique et rapports lisibles ;
- design system sobre ;
- responsive et accessibilité ;
- captures anonymisées et démonstration.

Critère de sortie : les tâches de consultation principales passent un test utilisateur et un audit clavier/contraste.

## Phase 5 — Validation réelle

- protocole Kali/lab ;
- jeu de données synthétique ;
- tests de performances ;
- revue sécurité ;
- validation de rapports ;
- documentation de support.

Critère de sortie : résultats reproductibles sur au moins un environnement Kali propre et un lab autorisé.

## Phase 6 — Multiplateforme

- isoler la détection OS et les adaptateurs d’outils ;
- valider Linux générique ;
- recommander WSL pour Windows avant un port natif ;
- étudier macOS ;
- conserver le Web comme interface locale ;
- écarter le mobile tant que la valeur et la faisabilité ne sont pas démontrées.

Critère de sortie : décision documentée par plateforme, sans dégrader Kali/Linux.

## Stratégie de versions proposée

- `0.2.x` : fiabilité et documentation de l’état actuel ;
- `0.3.0` : contrat moteur/API stabilisé, toujours expérimental ;
- `0.4.0` : UX lecture seule validée ;
- `0.5.0` : installation et packaging reproductibles ;
- `1.0.0` : uniquement après validation sécurité, installation, support et comportement réel.

Cette proposition ne remplace pas la décision du propriétaire.

## Suivi

- Roadmap GitHub : [#58 — Professionnalisation, fiabilisation et refonte UX](https://github.com/cryptophil92/audit-suite/issues/58)
- Registre complet : [`audit/ISSUE_REGISTER.md`](audit/ISSUE_REGISTER.md)
- Audit technique : [`audit/TECHNICAL_AUDIT_2026-07-28.md`](audit/TECHNICAL_AUDIT_2026-07-28.md)
- Audit UX : [`ux/UX_AUDIT.md`](ux/UX_AUDIT.md)
- Étude multiplateforme : [`CROSS_PLATFORM_FEASIBILITY.md`](CROSS_PLATFORM_FEASIBILITY.md)
