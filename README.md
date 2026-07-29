# Audit Suite

[![CI](https://github.com/cryptophil92/audit-suite/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/cryptophil92/audit-suite/actions/workflows/shellcheck.yml)
[![Licence: Apache-2.0](https://img.shields.io/badge/licence-Apache--2.0-blue.svg)](LICENSE)
![Statut](https://img.shields.io/badge/statut-exp%C3%A9rimental-orange)
![Plateforme](https://img.shields.io/badge/plateforme-Kali%20Linux-557C94)
![Bash](https://img.shields.io/badge/Bash-5%2B-4EAA25?logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10%2B-3776AB?logo=python&logoColor=white)

Assistant expérimental et local d’audit de sécurité réseau, conçu pour aider à
comprendre les constats, prioriser les corrections et produire des rapports
clairs sur Kali Linux et dans des environnements autorisés.

> [!WARNING]
> Audit Suite peut lancer des outils de découverte, de scan de ports et d’énumération de services. Utilisez-le uniquement sur un réseau personnel, un laboratoire, un CTF/HTB ou un périmètre client explicitement autorisé. Les cibles IPv4 publiques sont bloquées par défaut, mais ce garde-fou ne remplace ni l’autorisation écrite ni le respect du droit applicable.

## Statut du projet

Le projet est en phase expérimentale. Le moteur Bash, les sorties JSON, l’historique local, les rapports, l’API locale en lecture seule et un premier tableau de bord sont présents. Plusieurs modules restent partiels ou servent de base de travail. Aucun support de production ni garantie de résultat exhaustif n’est annoncé.

L’audit de professionnalisation du 28 juillet 2026 est documenté dans [`docs/audit/`](docs/audit/). Les problèmes confirmés et les évolutions proposées sont suivis dans les [issues GitHub](https://github.com/cryptophil92/audit-suite/issues), avec une [roadmap de pilotage dédiée](https://github.com/cryptophil92/audit-suite/issues/58).

### Positionnement produit

Audit Suite vise en priorité les particuliers avancés, techniciens,
administrateurs et utilisateurs accompagnés qui souhaitent réaliser un audit
local autorisé et comprendre comment améliorer leur environnement.

Le projet ne vise pas une plateforme red team, blue team, SOC ou d’exploitation
offensive. La cible est une expérience guidée, prudente et agréable, avec des
preuves traçables et des recommandations actionnables. Voir
[`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md).

## Fonctionnalités présentes

- validation stricte des cibles IPv4 et CIDR ;
- blocage des plages publiques par défaut, avec dérogation explicite `--allow-public` ;
- sélection de profils `fast`, `full` et `stealth` ;
- découverte réseau et scans Nmap ;
- détection/énumération initiale de services SMB et HTTP ;
- orchestration modulaire avec délai maximal par module ;
- dry-run et aperçu JSON sans exécution ;
- manifest JSON `1.2.0`, contrat versionné des constats, historique local et
  comparaison de runs ;
- rapport HTML premium privé ou partageable, relevé technique et archive de
  rapport ;
- API HTTP locale en lecture seule ;
- tableau de bord Web local sans dépendance front-end externe.

### Limites fonctionnelles importantes

- les modules SNMP, Zeek et Suricata sont encore des squelettes ou placeholders ;
- le module SMB ne réalise qu’une détection initiale ;
- l’interface Web prépare et consulte, mais ne lance pas d’audit ;
- les modules réels ne produisent pas encore tous des constats structurés ;
- le rapport partageable masque les identifiants directs et chemins, mais ses
  textes libres doivent être relus avant diffusion ;
- la portabilité hors Kali/Linux n’est pas garantie ;
- certains problèmes de fiabilité et de sécurité identifiés par l’audit restent ouverts.

Consultez [`docs/KNOWN_LIMITATIONS.md`](docs/KNOWN_LIMITATIONS.md) et [`docs/audit/TECHNICAL_AUDIT_2026-07-28.md`](docs/audit/TECHNICAL_AUDIT_2026-07-28.md) avant toute utilisation.

## Architecture

```text
audit.sh                Lanceur et orchestration principale
core/                   Parsing, validation, runner, logs, historique, rapports
modules/                Modules d’audit Bash
bin/                    Commandes JSON, rapports, diagnostic et smoke test
api/server.py           API HTTP locale en lecture seule
api/openapi.json        Spécification OpenAPI actuelle
VERSION                 Source canonique de la version applicative
web/index.html          Tableau de bord local statique
ui/                     Aides d’interface terminal
tests/                  Tests Bash et test fonctionnel de l’API
schemas/                JSON Schema et règles runtime des contrats de données
docs/                   Documentation produit, technique, UX et sécurité
```

Le flux principal est :

```text
Arguments / menus
      ↓
Validation des cibles et des modules
      ↓
Préflight des dépendances et détection de l’environnement
      ↓
Exécution séquentielle des modules
      ↓
Constats structurés → manifest → rapport HTML → archive → historique local
```

L’inventaire détaillé se trouve dans [`docs/audit/REPOSITORY_INVENTORY.md`](docs/audit/REPOSITORY_INVENTORY.md).

## Prérequis

### Plateforme de référence

- Kali Linux ou distribution Linux compatible ;
- Bash 5 ou version compatible ;
- Python 3.10 ou plus récent pour l’API locale ;
- droits suffisants pour les fonctions réseau choisies.

### Dépendances requises par le moteur

- `nmap`
- `jq`
- `tar`
- `gzip`
- GNU `timeout`

Des outils supplémentaires sont requis uniquement par certains modules, notamment `whatweb`, `snmpwalk`, `zeek` ou `suricata`.

Vérification locale :

```bash
bash bin/check_deps.sh
```

Le script n’installe rien par défaut. L’option interactive `--install` utilise `apt-get` et doit être relue avant usage.

## Installation

Le projet ne fournit pas encore de paquet système ni d’installateur.

```bash
git clone https://github.com/cryptophil92/audit-suite.git
cd audit-suite
chmod +x audit.sh bin/*.sh modules/*.sh ui/*.sh
bash bin/check_deps.sh
```

Les versions système des dépendances ne sont pas verrouillées. Pour un environnement reproductible, consignez la distribution et les versions des outils utilisés avec chaque campagne d’audit.

## Démarrage

### Vérification sans scan

```bash
bash bin/smoke_local.sh
```

```bash
bash audit.sh \
  --dry-run \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories all \
  --run-id DRY_RUN_LOCAL \
  --no-zeek \
  --no-suricata
```

### Audit autorisé

```bash
bash audit.sh \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories 10_network_discovery.sh,20_portscan_nmap.sh \
  --run-id AUDIT_LAB_001 \
  --no-zeek \
  --no-suricata
```

Commencez par `--dry-run`. Ne reprenez pas cet exemple avec une cible que vous n’êtes pas autorisé à auditer.

### API et tableau de bord locaux

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Puis ouvrez `http://127.0.0.1:8765/`.

Conservez l’écoute sur `127.0.0.1`. L’exposition sur une autre interface n’est ni sécurisée ni supportée à ce stade.

## Configuration

Les options CLI ont priorité sur les menus interactifs :

```text
--profile <fast|full|stealth>
--targets <ip-ou-cidr[,ip-ou-cidr...]>
--categories <module[,module...]|all>
--run-id <identifiant>
--no-udp
--no-zeek
--no-suricata
--allow-public
--dry-run
--list-modules
```

Les profils de référence sont stockés dans `etc/profiles/`. Le détail des arguments figure dans [`docs/CLI_ARGS.md`](docs/CLI_ARGS.md).

## Résultats et données locales

```text
output/<RUN_ID>/               Résultats et manifest
logs/<RUN_ID>/combined.log     Journal combiné
history/runs.jsonl             Index local
history/latest.json            Dernier run détaillé
```

Générer les rapports :

```bash
# Rapport premium privé
bash bin/report_html.sh output/<RUN_ID>/manifest.json

# Copie avec identifiants directs et chemins masqués
bash bin/report_html.sh --shareable output/<RUN_ID>/manifest.json

# Relevé technique centré sur les modules
bash bin/report_html.sh --technical output/<RUN_ID>/manifest.json
```

Ces données peuvent révéler la topologie, les services et les vulnérabilités d’un réseau. Ne les publiez pas et vérifiez le contenu de toute archive avant partage.

## Tests

La suite contient actuellement 27 scripts `tests/test_*.sh`, deux suites Python
et un smoke test. Le runner unique les découvre automatiquement :

```bash
bash bin/test_all.sh
```

La CI exécute ShellCheck, tous les tests découverts et le smoke sous Ubuntu.
Le runner continue après un échec pour fournir un bilan complet, puis renvoie
un code non nul si un contrôle a échoué. Les tests couvrent notamment le
logging POSIX, les états module, la corruption/concurrence de l’historique,
les permissions et les signaux, uniquement avec des fixtures ou doubles
locaux. Aucun scan réseau réel n’est lancé.

`.gitattributes` impose LF aux scripts, tests Python, workflows et contrats
JSON afin que le même checkout reste analysable sous Linux et Windows Git Bash.

## Captures et démonstration

Les captures publiques ne sont pas encore validées. Le plan de production et les règles de confidentialité se trouvent dans [`docs/assets/screenshots/README.md`](docs/assets/screenshots/README.md). Les premiers wireframes sont documentés dans [`docs/ux/WIREFRAMES.md`](docs/ux/WIREFRAMES.md).

## Plateformes

| Plateforme | État |
|---|---|
| Kali Linux | Cible principale, validation réelle encore nécessaire après l’audit |
| Linux compatible | Faisable sous réserve des outils système et des privilèges |
| Windows natif | Non supporté ; lecture/tests partiels avec Git Bash |
| Windows via WSL | Piste recommandée, non validée dans cet audit |
| macOS | Non supporté, plusieurs dépendances Linux à abstraire |
| Web local | Interface de consultation ; moteur toujours local et dépendant de l’OS |
| Android/mobile | Non recommandé à ce stade |

Voir [`docs/CROSS_PLATFORM_FEASIBILITY.md`](docs/CROSS_PLATFORM_FEASIBILITY.md).

## Feuille de route

Ordre recommandé :

1. sécuriser les données déjà publiées et corriger les blocages du moteur ;
2. terminer la CI reproductible et le préflight guidé ;
3. connecter progressivement les modules au contrat de constats versionné ;
4. relier rapports, historique, onboarding et accessibilité ;
5. valider les parcours avec des utilisateurs autorisés ;
6. étudier la portabilité sans réécriture prématurée.

La roadmap détaillée est disponible dans [`docs/ROADMAP.md`](docs/ROADMAP.md)
et dans l’[issue GitHub #58](https://github.com/cryptophil92/audit-suite/issues/58).
La cible des rapports est définie dans
[`docs/PREMIUM_REPORT_SPEC.md`](docs/PREMIUM_REPORT_SPEC.md) et le contrat de
données dans
[`docs/FINDINGS_CONTRACT.md`](docs/FINDINGS_CONTRACT.md). Le registre
complet des constats est conservé dans
[`docs/audit/ISSUE_REGISTER.md`](docs/audit/ISSUE_REGISTER.md).

## Contribution

Lisez [`CONTRIBUTING.md`](CONTRIBUTING.md) et utilisez une branche dédiée. Les corrections fonctionnelles, les changements de sécurité et les améliorations UX doivent rester séparés lorsqu’ils présentent des risques ou des cycles de validation différents.

## Sécurité

- cadre d’utilisation : [`docs/SECURITY.md`](docs/SECURITY.md) ;
- signalement responsable : [`SECURITY.md`](SECURITY.md) ;
- ne publiez jamais de secret, résultat d’audit, adresse, empreinte de service ou méthode d’exploitation dans une issue publique.

## Licence

Sauf indication contraire, Audit Suite est distribué sous la
[licence Apache 2.0](LICENSE).

Copyright 2026 Cryptophil ([cryptophil92](https://github.com/cryptophil92)).

Les attributions et exceptions applicables, notamment pour le code de conduite
adapté du Contributor Covenant 2.1, sont décrites dans [`NOTICE`](NOTICE).

## Version et releases

La version applicative est définie uniquement dans [`VERSION`](VERSION). Elle
est exposée avec le commit source par `./audit.sh --version`,
`bash bin/version_json.sh`, l'API locale et les manifests de run.

La stratégie SemVer, les contrôles préalables et la procédure de publication
sont documentés dans [`docs/RELEASING.md`](docs/RELEASING.md). Aucun nouveau
tag ne doit être créé tant que les P0/P1 destinés à la première release ne sont
pas validés.

## Auteur et maintenance

Projet maintenu par [cryptophil92](https://github.com/cryptophil92). Les contributions et retours sont les bienvenus via les issues, dans le respect du cadre légal et éthique ci-dessus.
