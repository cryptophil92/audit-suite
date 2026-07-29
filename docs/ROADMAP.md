# Roadmap de professionnalisation

Cette roadmap traduit l’audit du 28 juillet 2026 et la direction produit validée
le 29 juillet 2026. L’[issue GitHub #58](https://github.com/cryptophil92/audit-suite/issues/58)
constitue la source opérationnelle de pilotage ; le
[registre des issues](audit/ISSUE_REGISTER.md) conserve la correspondance entre
constats et actions.

## Sources de vérité

En cas d’écart entre documents, utiliser cet ordre :

1. l’état du code fusionné dans `main` et les issues GitHub ouvertes ou fermées ;
2. cette roadmap pour la séquence active et les gates ;
3. [`PRODUCT_VISION.md`](PRODUCT_VISION.md) pour la direction produit ;
4. [`ux/UX_ROADMAP.md`](ux/UX_ROADMAP.md) pour le découpage UX ;
5. les audits datés du 28 juillet 2026 comme preuves historiques, et non comme
   description de l’état courant.

L’issue #58 doit refléter cette roadmap après chaque fusion qui change un jalon.

## Cap produit

Audit Suite vise un assistant local d’audit de sécurité réseau, guidé et
agréable à utiliser. Le produit doit aider un particulier avancé, un technicien,
un administrateur ou un utilisateur accompagné à comprendre les constats,
prioriser les corrections et produire un rapport de haute qualité.

Il ne vise pas une plateforme red team, blue team, SOC ou d’exploitation
offensive. La direction complète est documentée dans
[`PRODUCT_VISION.md`](PRODUCT_VISION.md).

## Principes

- aucune correction silencieuse ;
- une branche et une pull request par lot cohérent ;
- sécurité et fiabilité avant nouvelles fonctions ;
- pas d’exécution réelle depuis le Web avant revue de sécurité dédiée ;
- tests sans scan réseau dans la CI ;
- validation réelle uniquement sur un lab autorisé ;
- pas de réécriture multiplateforme prématurée ;
- aucune note sans méthode, preuve et justification ;
- résumé utilisateur avant détail technique ;
- aucune alerte ou recommandation inventée par l’interface.

## État vérifié au 29 juillet 2026

Dernier point de référence avant ce lot : `main` après la fusion de la PR #75,
commit `e9518c9787c26f8cdfb87cff95036e7c307791cc`.

| Domaine | État | Suite |
|---|---|---|
| P0 historique public | #37 ouvert, décision privée requise | Blocage de release, aucune réécriture sans accord dédié |
| Logging, états modules, historique, API | #38 à #42 fusionnés | Maintenir les tests |
| Licence, version et procédure de release | Documentées et fusionnées | Pas de tag avant les gates P0/P1 |
| Artefacts historiques publics | Décision privée encore requise | Issue #37 |
| CI exhaustive et maintenance des actions | 27 tests Bash, 17 tests Python et smoke découverts par un runner unique ; LF imposé | Maintenance #44 |
| Préflight agréable et actionnable | Incomplet | Issue #47 |
| Modèle de constats et notation | #70 fermé, contrat `1.0.0` implémenté | Brancher les adaptateurs de modules avec #48 |
| Rapport premium | #71 fermé, HTML privé/partageable/technique implémenté | Valider sur cas réels et relier à #53/#54 |
| Onboarding, vues résultats et accessibilité | Documentés, non implémentés | Issues #52 à #54 |

## Séquence active

Deux volets avancent sans mélanger leurs changements dans une même PR.

### Confiance et qualité de livraison

1. décider du traitement privé de #37 ;
2. maintenir la découverte complète des tests et la politique LF livrées par
   #43 ;
3. mettre à niveau la maintenance CI avec #44 ;
4. construire le préflight guidé de #47.

### Valeur utilisateur

1. connecter les modules au contrat de constats et clarifier leur maturité avec
   #48 ;
2. sécuriser le rendu des données du dashboard avec #51 avant de l’étendre ;
3. relier historique, constats et rapports avec #53 ;
4. déployer onboarding, navigation et accessibilité avec #52 et #54 ;
5. valider les parcours avec #55.

### Prochain lot non bloqué

#44 est le prochain lot de confiance entièrement testable sans scan réel ni
décision destructive. #47 vient ensuite pour améliorer directement le
démarrage d’un audit. Le volet valeur peut préparer #48/#53 en parallèle, mais
ne doit pas étendre le dashboard avant le rendu sûr de #51.

## Phase 0 — Contenir les risques

Objectif : rendre le dépôt et le chemin de démarrage sûrs.

- traiter les sorties d’audit suivies dans Git ;
- conserver un logging fichier non bloquant et tester toute future réintroduction d’un bus d’événements ;
- ajouter des gardes CI contre les artefacts runtime ;
- vérifier les canaux de signalement privé.

Critère de sortie : aucun risque P0 ouvert sans mesure temporaire documentée.

État : garde contre les nouveaux artefacts et logging non bloquant fusionnés.
L’évaluation privée et la décision sur l’historique public restent ouvertes dans
#37.

## Phase 1 — Fiabiliser le moteur

- propager les erreurs des outils ;
- distinguer succès, résultat partiel, échec et skip ;
- stabiliser Zeek/Suricata et les placeholders ;
- tester le runner avec des doubles ;
- gérer interruption, timeout et privilèges ;
- coordonner les exécutions concurrentes.

Critère de sortie : un manifest ne peut pas déclarer un succès lorsque la commande structurante a échoué.

État : contrat `success/partial/failed/skipped`, chemins concurrents et tests
du runner fusionnés. La suite couvre aussi les retours de permission et
d’interruption sans trafic réseau. Le préflight des outils, capacités et
privilèges reste à traiter dans #47.

## Phase 2 — Stabiliser données et API

- tolérer un historique partiellement corrompu ;
- verrouiller et écrire atomiquement ;
- borner les sous-processus API ;
- restreindre l’écoute réseau ;
- unifier routes et OpenAPI ;
- ajouter pagination et diagnostic dégradé.

Critère de sortie : une entrée locale invalide ne rend pas tout le tableau de bord indisponible.

État : historique résilient, écriture atomique, écoute loopback et budgets API
fusionnés. La cohérence générée des routes et d’OpenAPI reste suivie par #50.

## Phase 3 — Installation, CI et releases

- matrice de dépendances et privilèges ;
- CI générée à partir de la liste des tests ;
- fins de lignes reproductibles ;
- mise à jour contrôlée des actions ;
- source de version unique ;
- licence Apache 2.0 et attributions tierces publiées ;
- première release documentée.

Critère de sortie : un nouveau contributeur peut installer, tester et identifier précisément la version.

État : licence, version et procédure de release fusionnées. Un runner unique
découvre 27 tests Bash, deux suites Python totalisant 17 cas et le smoke local.
Un test prouve qu’un nouveau fichier conforme est inclus automatiquement, et
`.gitattributes` impose LF. La maintenance des actions reste suivie par #44.
Aucune release ne doit contourner #37 ni les P1 retenues pour la release.

## Phase 4 — Cœur produit et rapport premium

- définir un objet `findings[]` versionné ;
- distinguer observation, vulnérabilité potentielle et vulnérabilité confirmée ;
- séparer gravité, confiance et état de validation ;
- conserver preuve, source et limites ;
- noter uniquement avec une méthode traçable ;
- structurer impact, remédiation et vérification ;
- produire un résumé exécutif puis un détail technique ;
- préparer impression/PDF et anonymisation.

Critère de sortie : un constat peut être expliqué, justifié, corrigé et vérifié
sans relire les logs bruts, sans score inventé.

Spécification : [`PREMIUM_REPORT_SPEC.md`](PREMIUM_REPORT_SPEC.md).

État : contrat `findings[]` `1.0.0`, manifest `1.2.0`, validation stricte,
compatibilité `1.0.0/1.1.0` et fixtures synthétiques implémentés. Les
adaptateurs des modules restent à réaliser. Le rapport HTML premium privé et
partageable, le tri, le plan d’action, l’annexe et les styles d’impression sont
implémentés sur données synthétiques ; la validation utilisateur et sur
rapports réels autorisés reste requise.

## Phase 5 — Expérience guidée en lecture seule

- onboarding et périmètre légal ;
- architecture de l’information ;
- états de chargement, vide, erreur et dégradation ;
- historique et rapports lisibles ;
- design system sobre ;
- responsive et accessibilité ;
- captures anonymisées et démonstration.

Critère de sortie : les tâches de consultation principales passent un test utilisateur et un audit clavier/contraste.

État : la documentation UX et le rapport premium fournissent les premiers
composants et contenus. Le dashboard reste un prototype technique sans vues
historique/constats/rapports intégrées ; #51 à #55 portent cette phase.

## Phase 6 — Validation réelle

- protocole Kali/lab ;
- jeu de données synthétique ;
- tests de performances ;
- revue sécurité ;
- validation de rapports ;
- documentation de support.

Critère de sortie : résultats reproductibles sur au moins un environnement Kali propre et un lab autorisé.

## Phase 7 — Multiplateforme

- isoler la détection OS et les adaptateurs d’outils ;
- valider Linux générique ;
- recommander WSL pour Windows avant un port natif ;
- étudier macOS ;
- conserver le Web comme interface locale ;
- écarter le mobile tant que la valeur et la faisabilité ne sont pas démontrées.

Critère de sortie : décision documentée par plateforme, sans dégrader Kali/Linux.

## Stratégie de versions proposée

- `0.2.x` : fiabilité et documentation de l’état actuel ;
- `0.3.0` : contrat moteur/API et modèle de constats stabilisés, toujours expérimental ;
- `0.4.0` : rapport premium et UX guidée en lecture seule validés ;
- `0.5.0` : installation et packaging reproductibles ;
- `1.0.0` : uniquement après validation sécurité, installation, support et comportement réel.

Cette proposition ne remplace pas la décision du propriétaire.

## Suivi

- Roadmap GitHub : [#58 — Professionnalisation, fiabilisation et refonte UX](https://github.com/cryptophil92/audit-suite/issues/58)
- Registre complet : [`audit/ISSUE_REGISTER.md`](audit/ISSUE_REGISTER.md)
- Audit technique : [`audit/TECHNICAL_AUDIT_2026-07-28.md`](audit/TECHNICAL_AUDIT_2026-07-28.md)
- Audit UX : [`ux/UX_AUDIT.md`](ux/UX_AUDIT.md)
- Vision produit : [`PRODUCT_VISION.md`](PRODUCT_VISION.md)
- Rapport premium : [`PREMIUM_REPORT_SPEC.md`](PREMIUM_REPORT_SPEC.md)
- Étude multiplateforme : [`CROSS_PLATFORM_FEASIBILITY.md`](CROSS_PLATFORM_FEASIBILITY.md)
