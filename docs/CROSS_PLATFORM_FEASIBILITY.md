# Faisabilité multiplateforme

État technique actualisé le 25 août 2026. Les mesures de l’audit initial du
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

## Validation Kali sous WSL2 du 25 août 2026

Une installation neuve a été validée sur Kali GNU/Linux Rolling sous WSL2,
avec systemd actif et les versions suivantes : Bash 5.3.9, Git 2.53.0,
Python 3.13.12, jq 1.8.1 et Nmap 7.99.

Preuves obtenues sans lancer de scan réseau réel :

- le diagnostic de dépendances déclare le socle prêt ;
- `ip`, GNU `timeout`, Nmap, jq, tar, gzip, mktemp, tmux, whiptail et WhatWeb
  sont disponibles ;
- les outils facultatifs absents sont signalés en mode dégradé explicite ;
- le smoke test local passe ;
- la suite complète passe avec 34 contrôles sur 34 ;
- les commandes JSON et l’API locale sont validées ;
- les chemins Linux situés dans le système de fichiers WSL fonctionnent ;
- Git et GitHub sont utilisables depuis WSL pour le workflow de contribution.

Cette preuve valide l’environnement de développement et les chemins non
destructifs. Elle ne valide pas encore les scans réels, les raw sockets, la
détection de toutes les interfaces Windows ni les modules nécessitant des
privilèges. `sudo` exige un mot de passe et ne doit pas être supposé disponible
pour une automatisation non interactive.

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
| Compatibilité actuelle | Cible principale ; développement et tests validés sur Kali Rolling sous WSL2 |
| Blocages | scans réels privilégiés non validés, adaptateurs réels de constats encore incomplets |
| Permissions | Root/capabilities possibles selon profil ; aucun `sudo` sans mot de passe dans la validation |
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
| Compatibilité actuelle | Validée pour développement, tests, API locale et builds sur Kali WSL2 |
| Faits observés | Diagnostic prêt, smoke local et 34/34 contrôles réussis ; systemd et interop Windows actifs |
| Blocages | scans réseau réels, raw sockets, correspondance des interfaces et modules privilégiés non validés |
| Permissions | Élévation Linux fonctionnelle mais interactive ; pas de `sudo` sans mot de passe |
| Packaging | Installation WSL et script de préparation à formaliser dans le dépôt |
| Effort | M |
| Valeur | Élevée pour utilisateurs Windows |
| Priorité | P2 |

WSL est préférable à un port Windows natif tant que le moteur dépend fortement d’outils Linux.

## Windows natif

| Dimension | Évaluation |
|---|---|
| Compatibilité actuelle | Partielle avec Git Bash |
| Faits observés | 31 tests Bash, 17 tests Python et smoke local, soit 34/34 contrôles ; `.gitattributes` impose LF aux scripts, tests et workflows |
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

Concentrer les prochains lots sur Kali/Linux et l’UX Web locale. WSL2 est
désormais une voie Windows validée pour développer, tester et utiliser les
fonctions locales non privilégiées. Son support de scan doit rester
conditionnel tant qu’une validation réseau autorisée n’a pas confirmé les
interfaces, raw sockets et privilèges nécessaires. Windows natif, macOS et
mobile restent des études P2/P3 sans engagement de port.
