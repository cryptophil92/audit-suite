# Arguments CLI

Depuis `v0.2.8-dry-run`, `audit.sh` peut être lancé avec des arguments pour éviter les menus interactifs et vérifier un plan sans exécution.

## Exemple complet

```bash
./audit.sh \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories 10_network_discovery.sh,20_portscan_nmap.sh \
  --no-zeek \
  --no-suricata
```

## Vérifier sans exécuter

```bash
./audit.sh \
  --dry-run \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories 10_network_discovery.sh \
  --no-zeek \
  --no-suricata
```

Le mode `--dry-run` valide les paramètres et affiche le plan prévu. Il ne lance pas les modules et ne crée pas de dossier de run.

## Lister les modules

```bash
./audit.sh --list-modules
```

Cette commande affiche les modules disponibles puis quitte.

## Options disponibles

```text
--profile <fast|full|stealth>
--targets <cidr[,cidr...]>
--categories <module[,module...]>
--no-udp
--no-zeek
--no-suricata
--allow-public
--dry-run
--list-modules
-h, --help
```

Les formats suivants sont acceptés :

```bash
--profile fast
--profile=fast
--targets 192.168.1.0/24
--targets=192.168.1.0/24
--categories 10_network_discovery.sh,20_portscan_nmap.sh
--categories=10_network_discovery.sh,20_portscan_nmap.sh
```

## Priorité CLI / menu

Les arguments CLI sont prioritaires.

Si une valeur n'est pas fournie, `audit.sh` utilise le menu existant pour demander :

- profil ;
- cibles ;
- catégories ;
- options.

## Objectif

Ce lot prépare :

- les tests locaux plus simples ;
- l'automatisation locale ;
- le futur backend API ;
- le lancement depuis une interface web sans menus interactifs.
