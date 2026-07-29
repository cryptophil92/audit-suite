# Faisabilité multiplateforme

État technique actualisé le 29 juillet 2026. Les mesures de l’audit initial du
28 juillet sont conservées dans
[`audit/TEST_RESULTS_2026-07-28.md`](audit/TEST_RESULTS_2026-07-28.md).

## Synthèse

Audit Suite est aujourd’hui un moteur Bash/Linux entouré d’une API Python et d’une interface Web portable. La bonne stratégie n’est pas une réécriture immédiate : il faut d’abord stabiliser le contrat du moteur, isoler les dépendances système et conserver Kali/Linux comme référence.

Ordre recommandé :

1. Kali Linux ;
2. Linux générique ;
3. Windows via WSL ;
4. interface Web locale ;
5. macOS ;
6. Windows natif ;
7. mobile uniquement après preuve de valeur.

## Dépendances OS actuelles

| Zone | Dépendance |
|---|---|
| Détection réseau | `ip route`, `ip link`, `ip addr` |
| Timeouts | GNU `timeout` |
| Scans | Nmap et scripts NSE |
| Installation | `apt-get`, éventuellement `sudo` |
| UI terminal | tmux, whiptail, zenity, fzf |
| Fichiers temporaires | `/tmp`, `mktemp` ; l’ancien FIFO de logging est désactivé |
| Permissions | raw sockets, SYN scan, OS detection |
| Rapport | `tar`, `gzip`, `jq` |
| Shell | tableaux Bash, `mapfile`, substitution de processus |

## Kali Linux

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Cible principale |
| Blocages | préflight incomplet, privilèges non diagnostiqués, adaptateurs réels de constats incomplets |
| Permissions | Root/capabilities possibles selon profil |
| Packaging | Aucun |
| Mise à jour | Git manuel |
| Effort | M pour stabiliser, L pour packager |
| Valeur | Très élevée |
| Priorité | P0/P1 |

Recommandation : seule plateforme de validation réelle initiale. Construire une matrice propre avec version Kali, Bash, Nmap, jq et outils optionnels.

## Linux générique

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Probable sur Debian/Ubuntu |
| Blocages | disponibilité des paquets, noms d’outils, privilèges |
| Permissions | variables selon distribution |
| Packaging | paquet Debian possible, autres formats plus tard |
| Effort | M |
| Valeur | Élevée |
| Priorité | P1/P2 |

Introduire un diagnostic de capacités et documenter les versions minimales avant d’annoncer le support.

## Windows via WSL

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Non testée dans cet audit |
| Blocages | accès interface réseau, raw sockets, intégration fichiers Windows |
| Permissions | WSL et élévation Linux |
| Packaging | script de préparation ou distribution WSL |
| Effort | M |
| Valeur | Élevée pour utilisateurs Windows |
| Priorité | P2 |

WSL est préférable à un port Windows natif tant que le moteur dépend fortement d’outils Linux.

## Windows natif

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Partielle avec Git Bash |
| Faits observés | 28 tests Bash, 17 tests Python et smoke local ; `.gitattributes` impose LF aux scripts, tests et workflows |
| Blocages | `ip`, GNU `timeout`, privilèges Nmap, outils optionnels, aucune validation de scan réel |
| Packaging | bundle d’outils ou réécriture d’adaptateurs |
| Effort | XL |
| Valeur | Moyenne à élevée |
| Priorité | P3 |

Un port natif impliquerait plus qu’un packaging. Il nécessite une couche d’abstraction des commandes et de la détection réseau. Ne pas démarrer avant stabilisation Linux/WSL.

## macOS

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Non supportée |
| Blocages | absence de `ip`, différences BSD/GNU, `timeout`, paquets Homebrew |
| Permissions | Nmap et captures réseau |
| Packaging | Homebrew ou bundle |
| Effort | L |
| Valeur | Moyenne |
| Priorité | P3 |

Le Bash système macOS et les utilitaires BSD ne doivent pas être supposés compatibles. Une installation explicite de Bash récent et GNU coreutils serait nécessaire.

## Interface Web locale

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Front-end portable, backend dépendant du moteur |
| Blocages | Bash/jq derrière l’API, sécurité d’écoute, performances |
| Réseau | loopback uniquement recommandé |
| Packaging | application locale ou service |
| Effort | M pour lecture seule |
| Valeur | Élevée |
| Priorité | P1/P2 |

L’interface Web est une surface, pas une plateforme moteur. Elle peut rester portable si l’API expose un contrat stable et si chaque adaptateur OS reste côté backend.

## Android et mobile

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Nulle |
| Blocages | raw sockets, outils externes, permissions, contraintes stores |
| Packaging | réécriture majeure |
| Effort | XL+ |
| Valeur | Non démontrée |
| Priorité | P3 / ne pas engager |

Un produit mobile d’inventaire réseau aurait un périmètre et des garde-fous différents. Il ne doit pas être présenté comme un simple port.

## Architecture d’évolution proposée

```text
Interface CLI / API / Web
          ↓
Contrat de plan et de résultat stable
          ↓
Service d’orchestration
          ↓
Adaptateur plateforme
  ├── Linux/Kali
  ├── WSL
  └── futurs adaptateurs
          ↓
Outils externes et capacités système
```

Étapes minimales :

1. documenter le contrat des commandes ;
2. centraliser la détection des capacités ;
3. décrire les privilèges par module ;
4. rendre chemins, temporaires et timeouts configurables ;
5. tester sans réseau avec doubles ;
6. ajouter une matrice CI ;
7. valider chaque plateforme par preuve, pas par supposition.

## Décision recommandée

Concentrer les prochains lots sur Kali/Linux et l’UX Web locale. Ouvrir uniquement des issues d’étude P2/P3 pour Windows natif, macOS et mobile. WSL peut devenir la voie Windows officielle si une validation réseau autorisée confirme les capacités nécessaires.
