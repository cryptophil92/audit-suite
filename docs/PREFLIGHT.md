# Préflight guidé

Le préflight explique ce qui est prêt, dégradé, ignoré ou bloquant avant
qu’Audit Suite ne lance un module. Il est strictement local, ne modifie pas le
système et ne produit aucun trafic réseau.

## Utilisation

Diagnostic général :

```bash
bash bin/check_deps.sh
```

Diagnostic du plan réellement demandé :

```bash
bash audit.sh \
  --dry-run \
  --profile full \
  --targets 192.168.1.0/24 \
  --categories 20_portscan_nmap.sh \
  --run-id PREFLIGHT_LOCAL \
  --no-zeek \
  --no-suricata
```

Le `--dry-run` affiche d’abord le préflight, puis le plan. Il ne crée pas de
run et n’exécute pas Nmap.

## Lecture des états

| État | Conséquence | Action |
|---|---|---|
| `OK` | capacité ou module prêt | aucune |
| `INFO` | fonction annexe indisponible | installer l’outil seulement si cette fonction est souhaitée |
| `DÉGRADÉ` | exécution possible avec couverture réduite | lire le repli annoncé avant de continuer |
| `LIMITÉ` | module disponible mais volontairement partiel | lire la limite avant de continuer |
| `IGNORÉ` | module non exécutable | installer ses commandes ; le manifest le marquera `skipped` sinon |
| `INDISPONIBLE` | placeholder ou chemin obsolète | choisir un module sélectionnable |
| `DÉSACTIVÉ` | module exclu par une option explicite | retirer l’option pour l’activer |
| `BLOQUANT` | socle moteur incomplet | corriger avant tout lancement |

Le lancement n’est bloqué que si une commande indispensable au moteur ou au
pack de rapport (`jq`, GNU `timeout`, `tar`, `gzip`) manque. Une dépendance
propre à un module n’est pas transformée en échec global : le module est
annoncé puis consigné comme `skipped`.

## Capacités contrôlées

### Environnement réseau

La commande `ip`, fournie par le paquet `iproute2`, permet de détecter
l’interface et le CIDR locaux. Sans elle, les cibles passées explicitement
restent utilisables ; les champs détectés restent vides et le préflight annonce
ce mode dégradé.

### API locale

Python 3.10 ou supérieur est requis pour l’API et le dashboard locaux. Son
absence n’empêche pas le moteur Bash de fonctionner.

### Privilèges Nmap

Le module `20_portscan_nmap` déclare les besoins suivants :

| Fonction | Besoin | Repli sans sockets brutes |
|---|---|---|
| profil `fast` TCP | privilège standard | Nmap utilise son mode compatible |
| profil `full` | sockets brutes pour SYN et détection OS | TCP connect `-sT`, sans `-O` |
| profil `stealth` | sockets brutes pour SYN | TCP connect `-sT`, moins discret |
| étape UDP, tous profils | sockets brutes | étape ignorée et résultat `partial`, sauf si `--no-udp` a été demandé |

La capacité est reconnue pour l’utilisateur root ou lorsqu’une capacité
`cap_net_raw` est visible sur Nmap. Le préflight ne tente jamais d’élever les
droits et n’affiche ni utilisateur, ni chemin de binaire, ni interface, ni
adresse.

## Sorties machine

```bash
bash bin/status_json.sh | jq '.capabilities'
bash bin/modules_json.sh | jq '.modules[] | {id, maturity, selectable, capabilities, intrusiveness, privileges, requirements, limitations}'
```

`status_json.sh` expose uniquement des booléens et des catégories générales
pour la plateforme, `iproute2`, Python et les sockets brutes.
`modules_json.sh` expose aussi la maturité, les capacités, l’intrusivité, les
privilèges et les limites. Voir [`MODULE_CATALOG.md`](MODULE_CATALOG.md).

## Installation

`bin/check_deps.sh` ne modifie rien par défaut. Son option `--install` reste
interactive et ne propose que l’installation du socle bloquant. Les outils de
modules et les capacités réseau doivent être installés selon la distribution,
après lecture de sa documentation.

## Limite de validation

Les tests utilisent des commandes factices et simulent l’absence d’outils ou
de privilèges. Ils prouvent le diagnostic, le skip et le repli déterministes,
mais ne remplacent pas une validation sur Kali/Linux et un lab autorisé.
