# Vision produit Audit Suite

## Statut

Direction validée par le propriétaire le 29 juillet 2026. Les fonctionnalités
décrites comme cibles ne doivent pas être présentées comme déjà disponibles.

## Promesse

Audit Suite est un assistant local d’audit de sécurité réseau. Il aide à
préparer un périmètre autorisé, exécuter des vérifications compréhensibles,
interpréter les constats, décider quoi corriger et produire un rapport de haute
qualité.

Le produit privilégie la clarté, la preuve et la remédiation. Il ne cherche pas
à multiplier les outils techniques visibles ni à reproduire une console
d’opérations de cybersécurité.

## Utilisateurs prioritaires

1. Particulier avancé qui veut comprendre et améliorer son réseau local.
2. Technicien informatique qui réalise un audit autorisé et doit remettre un
   rapport clair.
3. Administrateur système ou réseau qui vérifie un environnement et suit les
   corrections dans le temps.
4. Utilisateur moins expert, accompagné par des explications prudentes et des
   actions réversibles.

Un professionnel de la sécurité peut utiliser les sorties techniques, mais
l’expérience n’est pas conçue autour des rôles, procédures ou écrans d’une red
team, d’une blue team ou d’un SOC.

## Non-objectifs

Audit Suite n’est pas destiné à devenir :

- un framework d’exploitation offensive ;
- une plateforme red team ou blue team ;
- une console SOC, SIEM ou de réponse à incident ;
- un orchestrateur distant multi-client ;
- un moteur de remédiation automatique ;
- un service cloud collectant les résultats ;
- une application mobile avant validation d’un besoin réel.

L’exécution Web réelle reste hors périmètre tant qu’un contrôleur dédié n’a pas
été conçu et revu sur le plan de la sécurité.

## Tâches essentielles

### Avant l’audit

- vérifier que l’environnement est prêt ;
- comprendre les outils, privilèges et limites ;
- confirmer un périmètre autorisé ;
- choisir un profil expliqué en langage clair ;
- prévisualiser les vérifications et leur intrusivité ;
- connaître les données qui seront produites.

### Pendant l’audit

- voir l’étape en cours et le temps écoulé ;
- distinguer terminé, partiel, ignoré, bloqué et échoué ;
- comprendre une dépendance manquante ;
- conserver les résultats déjà valides ;
- interrompre proprement sans perdre la traçabilité.

### Après l’audit

- connaître la couverture et les limites ;
- comprendre les constats prioritaires ;
- distinguer observation, vulnérabilité potentielle et vulnérabilité confirmée ;
- voir la gravité, la confiance, la preuve et la source ;
- appliquer une remédiation prudente ;
- vérifier la correction lors d’un nouvel audit ;
- exporter un rapport après revue des données sensibles.

## Définition d’une expérience agréable

Un audit agréable n’est pas seulement un écran esthétique. Le parcours doit :

1. échouer tôt avec une explication et une action possible ;
2. employer des termes orientés tâche plutôt que l’implémentation ;
3. montrer l’avancement sans cacher l’incertitude ;
4. conserver la saisie et les résultats partiels après une erreur ;
5. présenter un résumé avant les commandes, chemins et JSON ;
6. limiter chaque écran à une action principale claire ;
7. expliquer les risques sans dramatisation ;
8. fournir une aide contextuelle sans exiger de lire toute la documentation ;
9. rester utilisable au clavier, au zoom et sur petit écran ;
10. rendre visible le caractère local et sensible des données.

## Standard de confiance

Chaque information importante doit permettre de répondre à cinq questions :

1. Qu’est-ce qui a été observé ?
2. Sur quel actif ou service ?
3. Quelle est la source ou la preuve ?
4. Quel est le niveau de confiance ?
5. Que peut faire l’utilisateur ensuite ?

L’interface ne transforme jamais :

- un échec de module en absence de faille ;
- un script de détection en preuve définitive ;
- une sortie absente en résultat sain ;
- une estimation en score officiel ;
- une recommandation générique en correction garantie.

## Standard du rapport premium

Le rapport doit servir deux lectures complémentaires.

### Lecture décisionnelle

- périmètre et date ;
- état de complétude ;
- constats prioritaires ;
- gravité et confiance ;
- actions immédiates et planifiées ;
- limites importantes.

### Lecture technique

- actifs et services concernés ;
- preuves référencées ;
- outils, versions et horodatages ;
- méthode de notation ;
- impact et scénarios prudents ;
- remédiation détaillée ;
- méthode de vérification ;
- annexes, logs et fichiers utiles.

Le niveau d’information doit être maximal par divulgation progressive : les
décisions d’abord, les preuves et détails ensuite.

## Principes de notation

- séparer gravité, confiance et état de validation ;
- afficher un score uniquement avec une méthode et une justification ;
- utiliser CVSS uniquement avec un vecteur valide et des données suffisantes ;
- identifier clairement toute méthode propre à Audit Suite ;
- autoriser un constat non noté plutôt que d’inventer une précision ;
- ne pas calculer de note globale par simple moyenne des constats ;
- expliquer toute future note globale et la valider avec des cas réels.

## Indicateurs produit

Les mesures cibles seront validées par recherche utilisateur :

- réussite du préflight sans documentation externe ;
- temps nécessaire pour préparer un premier audit ;
- compréhension correcte d’un état partiel ;
- identification des trois actions prioritaires ;
- capacité à expliquer la différence entre gravité et confiance ;
- réussite de l’export sans donnée sensible involontaire ;
- navigation clavier et reflow conformes aux critères définis ;
- confiance déclarée sans surestimation de la couverture.

## Séquence de réalisation

1. maintenir la découverte automatique des tests livrée par
   [#43](https://github.com/cryptophil92/audit-suite/issues/43) et
   l’épinglage des Actions avec la surveillance Dependabot livrés par
   [#44](https://github.com/cryptophil92/audit-suite/issues/44), ainsi que le
   préflight guidé livré par
   [#47](https://github.com/cryptophil92/audit-suite/issues/47) ;
2. maintenir le catalogue de maturité et le pack canonique livrés par
   [#48](https://github.com/cryptophil92/audit-suite/issues/48) ;
3. maintenir le rendu sûr du dashboard livré par l'issue
   [#51](https://github.com/cryptophil92/audit-suite/issues/51) ;
4. maintenir et étendre prudemment la connexion des sorties au contrat — issue
   [#79](https://github.com/cryptophil92/audit-suite/issues/79) ;
5. relier historique, constats et rapports dans l’interface — issue
   [#53](https://github.com/cryptophil92/audit-suite/issues/53) ;
6. déployer l’onboarding, le design system et l’accessibilité — issues
   [#52](https://github.com/cryptophil92/audit-suite/issues/52) et
   [#54](https://github.com/cryptophil92/audit-suite/issues/54) ;
7. valider les rapports et parcours avec des utilisateurs et sur Kali/Linux.

Le contrat de constats, le premier adaptateur Nmap et le premier rapport
premium constituent désormais le socle à étendre aux autres modules et à
relier aux vues de résultats, pas une cible encore à construire.

Voir [`ROADMAP.md`](ROADMAP.md) pour le pilotage complet.
