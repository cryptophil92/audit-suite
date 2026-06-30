# Sécurité et périmètre d'utilisation

AUDIT-SUITE est un outil d'audit réseau défensif.

Il doit être utilisé uniquement dans un cadre autorisé :

- réseau personnel ;
- lab local ;
- CTF / HTB ;
- environnement client avec autorisation explicite.

## Règle par défaut

Depuis la version 0.2.0, les cibles publiques sont bloquées par défaut.

Le launcher accepte uniquement les formats suivants :

- IPv4 simple : `192.168.1.10`
- CIDR IPv4 : `192.168.1.0/24`
- plusieurs cibles séparées par virgules ou espaces : `192.168.1.0/24,10.10.10.5`

## Plages autorisées par défaut

Les plages suivantes sont autorisées sans option spéciale :

- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`
- `127.0.0.0/8`
- `169.254.0.0/16`
- `100.64.0.0/10`

Toute autre cible est refusée par défaut.

## Option `--allow-public`

L'option suivante désactive le blocage des IP publiques :

```bash
./audit.sh --allow-public
```

Elle doit être utilisée uniquement avec une autorisation explicite et vérifiable.

AUDIT-SUITE ne doit jamais être lancé contre une IP publique, un domaine, une entreprise ou un tiers sans accord clair.

## Exemples acceptés par défaut

```text
192.168.1.0/24
192.168.1.10
10.10.10.5
172.16.0.0/16
```

## Exemples refusés par défaut

```text
8.8.8.8
1.1.1.1
example.com
https://example.com
203.0.113.0/24
```

## Limites du patch 0.2.0 initial

Ce premier patch ajoute une première barrière de sécurité côté launcher.

Les étapes suivantes du hardening doivent encore traiter :

- correction complète de `MOD_REQUIRES` ;
- isolation renforcée des modules ;
- passage des cibles en tableau sécurisé dans tous les modules ;
- génération du manifest avec `jq` ;
- ajout de ShellCheck en CI ;
- durcissement de `bin/check_deps.sh`.
