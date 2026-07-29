# Journal des décisions UX

## Format

Chaque décision contient :

- date ;
- statut ;
- contexte ;
- décision ;
- conséquences ;
- éléments à valider.

## UX-001 — Le Web reste en lecture/préparation

**Date :** 28 juillet 2026

**Statut :** proposé, aligné avec l’existant

**Contexte :** l’API n’expose pas d’exécution réelle et le moteur présente encore des risques P0/P1.

**Décision :** concevoir le chantier UX autour de la consultation, du diagnostic, de l’historique, des rapports et de la préparation de plan.

**Conséquence :** aucun wireframe ne propose de lancement réel.

**À valider :** valeur d’un futur contrôleur après fiabilisation et revue sécurité.

## UX-002 — Fiabilité avant visualisation

**Date :** 28 juillet 2026

**Statut :** proposé

**Décision :** ne pas construire de dashboard « professionnel » sur des états moteur susceptibles d’être trompeurs.

**Conséquence :** les issues de statut, corruption et logging précèdent le polish.

## UX-003 — Résumé puis détail technique

**Date :** 28 juillet 2026

**Statut :** proposé

**Décision :** remplacer le JSON brut comme vue primaire par des résumés, en conservant le JSON accessible.

**Conséquence :** meilleure accessibilité cognitive sans cacher la preuve technique.

## UX-004 — Terminologie orientée tâche

**Date :** 28 juillet 2026

**Statut :** hypothèse

**Décision :** employer « audit enregistré », « identifiant de l’audit » et « vérifications » dans l’interface, avec le terme technique en aide.

**À valider :** entretiens avec administrateurs et professionnels cybersécurité.

## UX-005 — État partiel de premier rang

**Date :** 28 juillet 2026

**Statut :** proposé

**Décision :** `partial` est un état visible distinct, jamais assimilé à succès ou échec total.

**Conséquence :** modèle de données et composants doivent le supporter.

## UX-006 — Données locales rendues visibles

**Date :** 28 juillet 2026

**Statut :** proposé

**Décision :** afficher que les données sont locales, leur emplacement logique, leur fraîcheur et leur sensibilité.

**Conséquence :** chaque export inclut une étape de revue/anonymisation.

## UX-007 — Thème système par défaut

**Date :** 28 juillet 2026

**Statut :** conservé

**Décision :** garder clair/sombre selon le système avant d’ajouter une préférence.

**À valider :** contraste réel des deux palettes.

## UX-008 — Pas d’identité visuelle complexe

**Date :** 28 juillet 2026

**Statut :** proposé

**Décision :** privilégier typographie, espace, états et composants sobres.

**Conséquence :** pas de logo ou illustration coûteuse avant validation des parcours.

## UX-009 — Captures uniquement synthétiques

**Date :** 28 juillet 2026

**Statut :** requis

**Décision :** toute capture publique utilise une fixture synthétique et passe une revue confidentialité.

## UX-010 — Accessibilité AA comme cible

**Date :** 28 juillet 2026

**Statut :** proposé

**Décision :** viser WCAG 2.2 AA pour Web et rapports, sans revendiquer de conformité avant audit.

## UX-011 — Assistant d’audit, pas plateforme red/blue team

**Date :** 29 juillet 2026

**Statut :** validé par le propriétaire

**Décision :** concevoir le produit pour des audits locaux guidés, la
compréhension des constats et la remédiation. Ne pas organiser l’interface
autour de tactiques offensives, de files d’incidents SOC ou de rôles red
team/blue team.

**Conséquence :** la navigation privilégie préparer, comprendre, corriger,
vérifier et rapporter.

## UX-012 — Notation traçable et facultative

**Date :** 29 juillet 2026

**Statut :** validé

**Décision :** un score est affiché uniquement avec une méthode, une échelle et
une justification. Un constat peut rester non noté.

**Conséquence :** aucune note globale par moyenne simple et aucune conversion
automatique d’une sortie d’outil en vulnérabilité confirmée.

## UX-013 — Rapport en deux niveaux

**Date :** 29 juillet 2026

**Statut :** validé

**Décision :** le rapport premium commence par une synthèse décisionnelle et un
plan d’action, puis conserve les preuves et annexes techniques en second niveau.

**Conséquence :** le maximum d’information reste disponible sans imposer un
dump technique comme vue principale.

## UX-014 — Trois sorties de rapport explicites

**Date :** 29 juillet 2026

**Statut :** validé et implémenté

**Décision :** le rapport privé premium est la sortie par défaut. Une version
partageable masque les identifiants structurés directs et exige une revue des
textes libres. Le relevé technique historique reste disponible sur demande.

**Conséquence :** aucune version partageable ou technique n’est ajoutée
silencieusement au pack privé. L’impression/PDF s’appuie sur le navigateur
jusqu’à validation d’un pipeline dédié.

## Décisions ouvertes

- framework ou maintien du Web natif ;
- modèle d’appareil et d’alerte ;
- besoin de comparaison visuelle ;
- politique de conservation/suppression ;
- niveau de garantie et sélection de contenu de la version partageable ;
- position du diagnostic API ;
- support WSL officiel ;
- canal de recherche utilisateur.
- formule éventuelle d’une note globale de posture ;
- validation PDF et accessibilité de l’impression.
