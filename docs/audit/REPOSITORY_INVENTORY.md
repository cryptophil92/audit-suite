# Inventaire du dépôt — 28 juillet 2026

## Référence auditée

| Élément | Valeur |
|---|---|
| Dépôt | `cryptophil92/audit-suite` |
| Branche de départ | `main` |
| Commit | `df2974533c44a18a1ca78d5afaa1575d03cd5315` |
| Branche d’audit | `audit/professionalization-ux-review` |
| Visibilité | Publique |
| Branche par défaut | `main` |
| Dernier tag | `v0.1.2` |
| Dernier run CI observé | Succès, 4 juillet 2026 |

## Volumétrie

| Catégorie | Nombre |
|---|---:|
| Fichiers suivis | 178 |
| Scripts shell | 65 |
| Scripts de test | 20 |
| Modules actifs découverts | 10 |
| Documents Markdown initiaux | 27 |
| Fichiers runtime suivis | 74 |
| Taille des fichiers runtime suivis | 4 087 533 octets |
| Pull requests brouillon encore ouvertes | 30 |
| Issues ouvertes avant l’audit | 0 |
| Issues fermées avant l’audit | 0 |

Les fichiers runtime suivis se trouvent dans `output/`, `logs/` et `tmp/`. Ils sont ignorés par le `.gitignore` actuel mais restent versionnés parce qu’ils ont été ajoutés antérieurement.

## Technologies

| Zone | Technologie | Dépendances |
|---|---|---|
| Moteur | Bash | `nmap`, `jq`, `tar`, `gzip`, GNU `timeout`, outils optionnels |
| API | Python standard library | Python 3, Bash et commandes JSON du dépôt |
| Web | HTML, CSS, JavaScript natifs | API locale |
| Rapports | Bash, `jq`, HTML, `tar` | fichiers du run |
| CI | GitHub Actions | Ubuntu, ShellCheck, `jq` |
| Stockage | Fichiers locaux JSON/JSONL | système de fichiers |

Aucun gestionnaire de paquets applicatif, fichier de verrouillage, conteneur ou définition d’environnement reproductible n’est présent.

## Arborescence et responsabilités

```text
.
├── .github/
│   └── workflows/shellcheck.yml
├── api/
│   ├── openapi.json
│   └── server.py
├── bin/
│   ├── check_deps.sh
│   ├── *_json.sh
│   ├── report_*.sh
│   ├── smoke_local.sh
│   └── scripts historiques de patch/mise à jour
├── core/
│   ├── lib_args.sh
│   ├── lib_validate.sh
│   ├── lib_modules.sh
│   ├── lib_runner.sh
│   ├── lib_logging.sh
│   ├── lib_history.sh
│   └── bibliothèques de rapport et comparaison
├── docs/
├── etc/
│   ├── defaults.env
│   └── profiles/
├── modules/
├── tests/
├── ui/
├── web/
├── audit.sh
└── README.md
```

## Points d’entrée

| Commande | Rôle | Effet réseau |
|---|---|---|
| `bash audit.sh` | Lanceur interactif principal | Oui selon modules |
| `bash audit.sh --dry-run ...` | Validation et plan texte | Non |
| `bash bin/plan_json.sh ...` | Plan JSON | Non |
| `bash bin/modules_json.sh` | Catalogue des modules | Non |
| `bash bin/status_json.sh` | État local et dépendances | Non |
| `bash bin/history.sh` | Historique texte | Non |
| `bash bin/history_json.sh` | Historique JSON | Non |
| `bash bin/compare_runs.sh` | Compare deux manifests | Non |
| `bash bin/finalize_reports.sh` | Génère rapport et archive | Non |
| `bash bin/smoke_local.sh` | Smoke test local | Non |
| `python3 api/server.py` | API et tableau de bord locaux | Écoute HTTP locale |

## Composants majeurs

### Lanceur

`audit.sh` :

1. parse les arguments ;
2. charge les bibliothèques ;
3. collecte profil, cibles, catégories et options ;
4. valide les cibles et les modules ;
5. vérifie les chemins et dépendances ;
6. détecte l’environnement ;
7. initialise les logs ;
8. exécute les modules ;
9. écrit le manifest ;
10. génère rapport et archive ;
11. met à jour l’historique.

### Runner

`core/lib_runner.sh` :

- normalise les chemins de modules ;
- lit les métadonnées dans un shell enfant ;
- vérifie les dépendances déclarées ;
- applique un délai maximal par module ;
- collecte code retour, durée, état et chemin de sortie ;
- écrit le manifest JSON.

### Historique et rapports

- `core/lib_history.sh` écrit `runs.jsonl` et `latest.json` ;
- `core/lib_report_html.sh` échappe les valeurs via `jq @html` ;
- `core/lib_report_pack.sh` produit une archive structurée ;
- `core/lib_compare.sh` compare deux manifests.

### API

`api/server.py` utilise exclusivement la bibliothèque standard Python. Les routes JSON appellent les scripts Bash via `subprocess.run`. Le serveur est en lecture seule au sens fonctionnel : il n’expose aucune route qui lance un audit réel.

### Tableau de bord

`web/index.html` :

- charge le snapshot et le catalogue des routes ;
- affiche l’état, les modules et le dernier run ;
- construit un aperçu de plan ;
- ne lance pas d’audit réel.

## Catalogue des modules

| Module | Fonction observée | État |
|---|---|---|
| `10_network_discovery.sh` | Découverte Nmap `-sn` | Implémenté, erreurs masquées |
| `20_portscan_nmap.sh` | Scans TCP/UDP selon profil | Implémenté |
| `30_vuln_nmap_nse.sh` | Scripts NSE `vuln` | Implémenté, erreurs masquées |
| `40_service_enum.sh` | Détection de versions | Implémenté, erreurs masquées |
| `50_snmp_enum.sh` | Écrit un fichier TODO | Placeholder |
| `60_smb_enum.sh` | Détecte les ports SMB ouverts | Partiel |
| `70_http_enum.sh` | Nmap puis WhatWeb | Implémenté, erreurs masquées |
| `80_zeek.sh` | Écrit un placeholder | Placeholder |
| `81_suricata.sh` | Écrit un placeholder | Placeholder |
| `90_report_pack.sh` | Archive le dossier de run | Redondant avec la finalisation |

## Dépendances externes

### Requises par `check_deps.sh`

- `nmap`
- `jq`
- `tar`
- `gzip`
- `timeout`

### Optionnelles déclarées

- `tmux`
- `whiptail`
- `zenity`
- `fzf`
- `whatweb`
- `arp-scan`
- `fping`
- `sslscan`
- `nuclei`
- `zeek`
- `suricata`

### Implicites ou non couvertes par le préflight principal

- `ip`/iproute2 pour `core/lib_detect.sh` ;
- Python 3 pour l’API et son test ;
- `sha256sum` pour les scripts de mise à jour/intégrité ;
- `snmpwalk` pour le module SNMP ;
- privilèges élevés pour certains modes Nmap.

## Tests existants

Les 20 scripts couvrent :

- parsing et validation des arguments ;
- validation IPv4/CIDR et blocage public ;
- sélection et catalogue des modules ;
- dry-run et chemins de run ;
- plans, routes, version, statut et snapshot JSON ;
- historique texte/JSON et détail d’un run ;
- schéma du manifest ;
- comparaison de runs ;
- rapport HTML et échappement ;
- archive et pipeline de rapport ;
- serveur API HTTP.

Zones importantes non couvertes de bout en bout :

- exécution réelle du runner avec doubles de commandes ;
- FIFO de logging sur POSIX ;
- propagation des erreurs des modules ;
- options Zeek/Suricata lorsque les outils sont installés ;
- corruption et écritures concurrentes de l’historique ;
- interruption, annulation et signaux ;
- droits insuffisants ;
- comportement sur Kali réel ;
- accessibilité et responsive Web.

## Installation et packaging

Méthode actuelle :

1. cloner le dépôt ;
2. ajouter les droits d’exécution ;
3. installer manuellement les outils système ;
4. lancer les scripts depuis la racine.

Il n’existe pas :

- de paquet Debian ;
- de conteneur ;
- d’installeur ;
- de procédure de mise à jour automatisée sûre ;
- de désinstalleur ;
- de fichier de versions de dépendances ;
- de release correspondant à l’état `0.2.34`.

## Plateformes observées

- Kali/Linux : cible déclarée ;
- Ubuntu GitHub Actions : analyse statique et tests ;
- Windows Git Bash : tests locaux partiels ;
- autres plateformes : non supportées.

Voir `docs/CROSS_PLATFORM_FEASIBILITY.md` pour l’analyse détaillée.

## Cohérence README, code, tests et CI

Constats principaux :

- le README initial omettait l’API, le Web, les rapports, les prérequis détaillés et les limites des modules ;
- la documentation demande de confirmer qu’aucune sortie runtime n’est suivie, alors que 74 fichiers le sont ;
- le code expose plusieurs versions divergentes ;
- la CI ne lance pas directement `tests/test_run_detail_json.sh` ;
- le catalogue de routes Bash, le catalogue Python et OpenAPI ne sont pas générés depuis une source unique ;
- les documents de pile PR restent présents alors que la consolidation est terminée ;
- 30 anciennes pull requests brouillon restent ouvertes.
