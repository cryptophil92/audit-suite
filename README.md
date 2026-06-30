# Audit Suite (Kali)

Suite d'audit réseau modulaire portable pour Kali Linux.

## Cadre d'utilisation

AUDIT-SUITE est un outil défensif.

Utilisation autorisée uniquement sur :

- réseau personnel ;
- lab local ;
- CTF / HTB ;
- environnement client avec autorisation explicite.

Les IP publiques sont bloquées par défaut depuis la version 0.2.0.

Voir : [`docs/SECURITY.md`](docs/SECURITY.md)

## Utilisation rapide

```bash
chmod +x audit.sh bin/*.sh modules/*.sh ui/*.sh
./audit.sh
```

Pour autoriser volontairement une cible publique, uniquement avec autorisation explicite :

```bash
./audit.sh --allow-public
```

## Cibles acceptées par défaut

Formats acceptés :

```text
192.168.1.10
192.168.1.0/24
192.168.1.0/24,10.10.10.5
```

Plages non publiques autorisées par défaut :

- `10.0.0.0/8`
- `172.16.0.0/12`
- `192.168.0.0/16`
- `127.0.0.0/8`
- `169.254.0.0/16`
- `100.64.0.0/10`

## Résultats

Les résultats sont stockés dans :

```text
output/AUDIT_YYYYMMDDTHHMMSSZ/
```

Les logs sont stockés dans :

```text
logs/AUDIT_YYYYMMDDTHHMMSSZ/combined.log
```

Un manifest JSON est généré dans :

```text
output/AUDIT_YYYYMMDDTHHMMSSZ/manifest.json
```

## Développement

La CI ShellCheck vérifie les scripts Bash sur les branches `main`, `feat/**`, `fix/**` et sur les pull requests vers `main`.
