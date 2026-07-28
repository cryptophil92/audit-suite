# Résultats de vérification — 28 juillet 2026

## Environnement

| Élément | Valeur |
|---|---|
| Hôte | Windows 11, Europe/Paris |
| Shell projet | Git Bash 5.3.15 |
| Python | 3.12.13, runtime isolé Codex |
| `jq` | 1.8.2, binaire officiel, SHA-256 vérifié |
| ShellCheck | 0.11.0, archive officielle, SHA-256 vérifié |
| Nmap | Présent sur l’hôte |
| WSL | Non installé |
| Docker | Non disponible |
| Scan réseau réel | Non exécuté |

Les outils `jq` et ShellCheck ont été téléchargés dans un dossier temporaire. Les empreintes correspondaient aux digests publiés dans les releases GitHub officielles.

## Synthèse

| Vérification | Résultat | Statut |
|---|---|---|
| Syntaxe Bash des 65 scripts | Aucun échec | Réussi |
| ShellCheck avec exclusions CI, fichiers LF | Aucun diagnostic | Réussi |
| ShellCheck niveau warning hors exclusions de variables sourcées | Diagnostics SC2034 liés au modèle de sourcing | À interpréter |
| 20 scripts `tests/test_*.sh` | 19 réussis, 1 échec | Partiel |
| API snapshot avec délai 20 s | Réponse valide en ~6,7 s | Réussi |
| 19 tests hors API dans un chemin avec espaces et accents | 19 réussis | Réussi |
| Historique corrompu | Échec non structuré, code 5 | Problème reproduit |
| Recherche simple de secrets | Aucun motif évident | Réussi avec limites |
| Alertes Dependabot | Fonction désactivée sur le dépôt | Non disponible |
| Alertes secret scanning | Accès API insuffisant | Non vérifié |

## Commandes exécutées

### État Git et inventaire

```powershell
git status --short --branch
git log -5 --oneline --decorate
git remote -v
rg --files
git ls-files
git ls-files output logs tmp history
```

### Syntaxe Bash

```bash
for file in $(git ls-files "*.sh"); do
  bash -n "$file"
done
```

Résultat : `BASH_SYNTAX_OK`.

### ShellCheck

Équivalent de la CI :

```text
shellcheck
  -e SC1090
  -e SC1091
  -e SC2016
  -e SC2034
  -e SC2154
  <65 scripts>
```

Résultat : code 0 sur une copie LF du commit.

Une exécution plus stricte, en conservant uniquement l’exclusion des sources dynamiques, remonte des `SC2034` sur des variables consommées après sourcing. Ces diagnostics ne prouvent pas à eux seuls du code mort.

### Suite complète

```bash
for test_file in tests/test_*.sh; do
  bash "$test_file"
done
```

Résultat :

- 19 tests réussis ;
- `tests/test_api_server.sh` échoue sur `GET /api/snapshot` avec `TimeoutError` après 5 secondes.

Mesures isolées sous Windows Git Bash :

| Commande | Durée observée |
|---|---:|
| `bin/status_json.sh` | ~3 174 ms |
| `bin/modules_json.sh` | ~2 474 ms |
| `bin/history_json.sh list` | ~298 ms |
| `bin/api_snapshot_json.sh` | ~6 440 ms |
| `bin/plan_json.sh` | ~1 620 ms |

Le même endpoint `/api/snapshot`, appelé avec un délai de 20 secondes, a répondu avec `kind: audit-suite.api_snapshot` en ~6 703 ms.

Conclusion : le comportement est fonctionnel dans cet environnement, mais le budget du test de 5 secondes est incompatible avec Windows Git Bash.

### Chemin avec espaces et accents

Une copie LF a été placée dans un chemin temporaire contenant des espaces et des caractères accentués. Les 19 tests hors `test_api_server.sh` ont réussi.

Le test API complet n’a pas été relancé dans ce chemin car son échec de performance était déjà reproduit indépendamment.

### Historique corrompu

Préparation d’un `runs.jsonl` invalide puis exécution :

```bash
AUDIT_HISTORY_DIR=<temp>/history bash bin/history_json.sh list
AUDIT_HISTORY_DIR=<temp>/history bash bin/api_snapshot_json.sh
```

Résultat confirmé pour les deux commandes :

- code retour `5` ;
- sortie standard vide ;
- erreur `jq` non structurée ;
- indisponibilité du snapshot.

### Fin de lignes Windows

Le checkout principal, affecté par `core.autocrlf`, contenait des CRLF. ShellCheck Windows a alors signalé `SC1017` sur les scripts. Une copie effectuée avec `core.autocrlf=false` a passé la même vérification.

Le dépôt ne contient pas de `.gitattributes` imposant LF aux scripts. Ce point est un risque de reproductibilité Windows, pas un échec du blob Git audité ni de la CI Ubuntu.

### GitHub Actions

Le dernier run observé sur `main` :

- workflow : `ShellCheck` ;
- run : `28713781280` ;
- date : 4 juillet 2026 ;
- conclusion : succès.

Les étapes ShellCheck et tests déclarées dans le workflow ont toutes réussi. Le workflow n’exécute toutefois pas directement `tests/test_run_detail_json.sh`.

## Vérifications non exécutées

- audit réseau réel ;
- test sur Kali Linux ;
- test avec privilèges administrateur/root ;
- droits de fichiers insuffisants ;
- interruption d’un scan long ;
- perte réseau ;
- charge importante ou historique volumineux ;
- exécution concurrente de deux audits ;
- macOS, WSL, Linux ARM ou Android ;
- audit manuel avec lecteur d’écran ;
- mesure de contraste par outil spécialisé ;
- secret scanning GitHub, faute de portée API.

## Interprétation

Les tests valident une partie importante des commandes structurées et des rapports. Ils ne valident pas le chemin critique d’un audit réel. Les problèmes du FIFO, de propagation des erreurs et de modules placeholders restent donc prioritaires malgré une CI verte.
