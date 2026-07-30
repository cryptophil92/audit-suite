# Catalogue et maturité des modules

Le catalogue machine est produit sans exécuter de scan :

```bash
bash bin/modules_json.sh
```

Le schéma `audit-suite.modules` `1.2.0` conserve les champs historiques
`count` et `modules[]`, puis ajoute les informations nécessaires pour annoncer
la couverture réelle avant un audit.

## Champs publics

Chaque entrée de `modules[]` expose :

| Champ | Signification |
|---|---|
| `display_name` | nom compréhensible affichable dans une interface |
| `maturity` | niveau de maturité réel |
| `selectable` | possibilité de choisir le module dans un plan |
| `capabilities[]` | fonctions effectivement implémentées |
| `intrusiveness` | niveau indicatif `none`, `low`, `moderate` ou `high` |
| `privileges[]` | privilèges standard ou optionnels |
| `limitations` | couverture absente ou réduite à annoncer |
| `requirements` | commandes, sockets brutes et repli connu |

Les niveaux de maturité sont :

- `experimental` : fonction implémentée et testée avec des doubles, sans
  validation Kali/lab représentative ;
- `partial` : fonction utile mais couverture volontairement incomplète ;
- `placeholder` : aucune capacité d’audit implémentée, non sélectionnable ;
- `deprecated` : ancien chemin conservé pour compatibilité, non
  sélectionnable ;
- `unknown` : métadonnée invalide ou absente dans une extension tierce.

La maturité n’est ni un score de risque ni une garantie d’exhaustivité.

## Matrice courante

| Module | Maturité | Sélection | Capacité principale | Intrusivité |
|---|---|---:|---|---|
| `10_network_discovery` | `experimental` | oui | découverte d’hôtes | `low` |
| `20_portscan_nmap` | `experimental` | oui | ports, services, UDP/OS selon privilèges | `high` |
| `30_vuln_nmap_nse` | `experimental` | oui | contrôles NSE vuln | `high` |
| `40_service_enum` | `experimental` | oui | détection de versions | `moderate` |
| `50_snmp_enum` | `placeholder` | non | aucune | `none` |
| `60_smb_enum` | `partial` | oui | détection des ports 139/445 | `low` |
| `70_http_enum` | `experimental` | oui | détection HTTP et empreinte Web | `moderate` |
| `80_zeek` | `placeholder` | non | aucune | `none` |
| `81_suricata` | `placeholder` | non | aucune | `none` |
| `90_report_pack` | `deprecated` | non | aucune | `none` |

SMB ne réalise aucune énumération de partages, comptes ou configuration. Une
exécution réussie de Nmap est donc enregistrée avec l’état de run `partial` et
une raison explicite.

## Sélection sûre

`--list-modules`, le menu interactif et `--categories all` ne proposent que
les six modules sélectionnables. Une ancienne configuration qui demande
directement SNMP, Zeek, Suricata ou le module 90 est refusée avec la maturité et
la limite concernées.

Les quatre fichiers restent présents afin de préserver les chemins historiques
et de rendre leur état visible dans le catalogue complet.

## Pipeline de rapport canonique

Il existe un seul ordre de finalisation :

```text
modules → findings/manifest → bin/finalize_reports.sh → rapport HTML + pack
```

Commande manuelle :

```bash
bash bin/finalize_reports.sh output/<RUN_ID>/manifest.json
```

Le module `90_report_pack.sh` ne crée plus d’archive avant le manifest. S’il
est appelé en contournant la sélection normale, il écrit seulement une note de
migration et se marque partiel. Le pack canonique reste :

```text
output/<RUN_ID>/<RUN_ID>_report_pack.tar.gz
```

## Compatibilité `1.1.0` vers `1.2.0`

- les lecteurs utilisant seulement `count`, `modules[].id`, `name`, `path` et
  `requirements` continuent de fonctionner ;
- les nouveaux lecteurs doivent filtrer sur `selectable` pour construire un
  plan ;
- `all` n’inclut plus les placeholders ni le module de pack obsolète ;
- `--no-zeek` et `--no-suricata` restent acceptés pour les scripts historiques,
  mais n’activent ni ne désactivent aucune capacité tant que ces modules sont
  des placeholders ;
- l’ancienne archive pré-manifest `output/<RUN_ID>.tar.gz` n’est plus créée ;
- `bin/report_pack.sh` reste une commande bas niveau compatible, tandis que
  `bin/finalize_reports.sh` est le pipeline recommandé.

Le premier adaptateur transforme uniquement les états `open` des fichiers
`.gnmap` de `20_portscan_nmap` en observations d’inventaire non notées. Il
conserve la provenance et ne déduit aucune vulnérabilité d’un port, d’un nom de
service ou d’une bannière. Les autres modules restent sans adaptateur.

Les règles et limites figurent dans
[`FINDINGS_ADAPTERS.md`](FINDINGS_ADAPTERS.md). Le catalogue décrit la
couverture ; il ne fabrique lui-même aucun constat ni score.

## Validation

Les tests de catalogue, sélection, préflight, états module et pipeline de
rapport utilisent uniquement des fixtures et des doubles. Aucun scan réseau
réel n’est lancé. La maturité `experimental` restera en place jusqu’à une
validation sur Kali/Linux et un lab explicitement autorisé.
