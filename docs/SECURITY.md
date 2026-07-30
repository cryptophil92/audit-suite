# Sécurité et périmètre d'utilisation

Pour signaler une vulnérabilité, suivre la politique privée décrite dans
[`../SECURITY.md`](../SECURITY.md). Ne pas publier de preuve d’exploitation,
de secret ou de résultat d’audit dans une issue.

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

AUDIT-SUITE ne doit pas être lancé sur un périmètre qui ne t'appartient pas ou qui n'a pas été clairement autorisé.

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

## État du hardening 0.2.0

Déjà traité dans la branche `feat/v0.2-hardening-bash` :

- validation stricte IPv4/CIDR côté launcher ;
- blocage des cibles publiques par défaut ;
- option explicite `--allow-public` ;
- correction de `MOD_REQUIRES` ;
- lecture des métadonnées module dans un shell enfant ;
- exécution des modules dans un shell enfant ;
- passage des cibles aux modules via tableaux Bash ;
- génération du manifest avec `jq` ;
- résultats modules ajoutés au manifest : statut, code retour, durée et dossier de sortie ;
- ajout de ShellCheck en CI ;
- ajout de tests Bash pour `core/lib_validate.sh` ;
- suppression de l'installation automatique des dépendances par défaut.

## Prochains contrôles

- traiter les sorties d’audit suivies dans Git ;
- maintenir le test de non-blocage du logging sur POSIX ;
- rendre les statuts modules fidèles aux codes retour ;
- limiter l’API à loopback et borner ses sous-processus ;
- tester un run réel sur lab local après correction ;
- vérifier les archives avant partage.

## Données d’audit

Les fichiers de `output/`, `logs/` et `history/` peuvent révéler :

- topologie et adressage ;
- noms d’hôtes et fabricants ;
- ports et versions de services ;
- vulnérabilités potentielles ;
- chemins et informations sur la machine d’analyse.

Ils doivent rester locaux, être anonymisés avant partage et ne jamais être
committés. Le `.gitignore` ne retire pas un fichier déjà suivi de l’historique.

## Dashboard local

Le serveur refuse toute écoute hors loopback. Son interface sépare HTML, CSS
et JavaScript afin d'appliquer une politique CSP stricte sans
`unsafe-inline`. Les données issues des routes JSON sont rendues avec
`textContent` et des nœuds texte ; elles ne sont jamais interpolées dans une
chaîne HTML.

Les réponses ajoutent également `X-Content-Type-Options: nosniff`,
`X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` et
`Cross-Origin-Resource-Policy: same-origin`. Ces protections complètent le
caractère local et en lecture seule de l'API ; elles ne remplacent pas la
validation des données ni l'autorisation explicite d'un audit.
