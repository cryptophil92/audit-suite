# Changelog

Les changements notables d’Audit Suite sont documentés ici. Le projet adopte
le format [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et
[Semantic Versioning](https://semver.org/lang/fr/).

## Non publié

### Fiabilité

- ajout du statut `partial` et d’un contrat explicite pour les états module ;
- propagation des erreurs des commandes structurantes ;
- skip déterministe de Zeek et Suricata lorsqu’ils sont désactivés ;
- historique, comparaison et rapport HTML adaptés au schéma manifest `1.1.0` ;
- manifest `1.2.0` avec contrat `findings[]` `1.0.0`, comptes de gravité et
  confiance, validation stricte et normalisation des schémas hérités ;
- conservation des constats structurés dans le dernier run et de leurs comptes
  dans l’index d’historique.
- rapport HTML premium par défaut avec synthèse, couverture, constats triés,
  remédiations, plan d’action et annexe technique ;
- mode partageable avec masquage des identifiants directs et chemins, plus
  maintien d’un relevé technique explicite ;
- styles responsive, thème système, navigation clavier et impression A4.

### Corrigé

- suppression du bus FIFO inutilisé afin que le logging ne puisse plus bloquer le moteur sur POSIX sans lecteur.
- lecture tolérante de l’historique JSONL avec compteurs de dégradation ;
- snapshot JSON maintenu disponible si l’index ou `latest.json` est
  partiellement corrompu ;
- sérialisation des écritures d’historique et remplacement atomique de
  `latest.json` ;
- réservation exclusive des dossiers d’un `run_id` contre les lancements
  concurrents.

### Documentation

- professionnalisation du README ;
- ajout des fichiers de contribution, conduite et signalement responsable ;
- ajout de l’inventaire et de l’audit technique du 28 juillet 2026 ;
- création du socle UX, accessibilité et design system ;
- ajout de l’étude de faisabilité multiplateforme ;
- ajout de modèles d’issues et de pull request ;
- ajout d’une configuration Dependabot pour GitHub Actions.
- adoption de la licence Apache 2.0 avec attribution publique à
  Cryptophil (`cryptophil92`) ;
- ajout d’un fichier `NOTICE` pour l’adaptation du Contributor Covenant 2.1.
- ajout d'une source canonique `VERSION`, exposée avec le commit par le CLI,
  l'API et les manifests ;
- formalisation de la procédure de release et de son contrôle P0/P1.
- clarification de la vision produit autour d’un audit guidé, local et orienté
  remédiation, distinct des plateformes red team/blue team ;
- définition du rapport premium et publication du contrat machine des constats,
  de la notation responsable et des fixtures synthétiques.

### Important

- le lot documentaire fusionné par la PR #59 ne contenait aucune correction
  fonctionnelle du moteur ;
- les problèmes découverts sont suivis par des issues dédiées.

### Performance

- délais configurables et limites de sortie pour tous les sous-processus de
  l’API ;
- réponses HTTP structurées `504`/`502` lors des dépassements ;
- agrégation parallèle des quatre sources du snapshot JSON.

### Sécurité

- refus des binds API non loopback et prise en charge explicite du loopback
  IPv6 ;
- suppression des commandes, sorties d'erreur et chemins locaux dans les
  erreurs HTTP publiques.

## 0.2.34 — état de code non publié

- lecture détaillée d’un run dans l’historique JSON ;
- exposition des chemins de l’historique ;
- tests et documentation associés.

Cette version apparaît dans l’API et certains documents, mais ne correspond pas à un tag Git publié.

## 0.2.32 — consolidation non publiée

- consolidation du moteur Bash, des sorties JSON, des rapports, de l’API locale et du tableau de bord ;
- validation locale historique sous Windows Git Bash ;
- fusion de la pile de travail dans `main`.

## 0.1.2

Dernier tag Git présent lors de l’audit du 28 juillet 2026. Le contenu exact de cette version doit être reconstitué et documenté avant une nouvelle release.
