# Adaptateurs de constats

## Statut

Audit Suite dispose d’un premier adaptateur déterministe pour les sorties
grepables de `20_portscan_nmap`. Il transforme uniquement les ports dont Nmap
déclare explicitement l’état `open` en observations d’inventaire conformes au
contrat `findings[]` `1.0.0`.

L’adaptateur :

- lit des fichiers locaux déjà produits ;
- ne lance jamais Nmap ni aucune autre commande réseau ;
- conserve le module, l’outil, sa version lorsqu’elle figure dans l’en-tête,
  le fichier source et la date de collecte ;
- référence la preuve sans intégrer la sortie brute au constat ;
- valide chaque tableau intermédiaire et la fusion finale ;
- remplace `findings.json` seulement après validation complète.

## Pipeline

Le chemin automatique est :

```text
modules
  → adaptateurs locaux
  → fusion findings[]
  → validation 1.0.0
  → manifest 1.2.0
  → rapport HTML et pack
  → historique
```

Commande locale équivalente :

```bash
bash bin/findings_from_modules.sh \
  --collected-at 2026-07-30T12:05:00Z \
  output/AUDIT_1 \
  192.0.2.0/24
```

La date est normalement fournie par le résultat du module pendant un audit.
La commande autonome utilise l’heure locale courante si `--collected-at` est
omis.

Options :

```text
--output <path>  destination, par défaut <run-dir>/findings.json
--base <path>    tableau findings[] existant à fusionner sans le modifier
```

`AUDIT_FINDINGS_FILE`, lorsqu’il est défini pour `audit.sh`, devient une entrée
de base en lecture seule. Le résultat fusionné est toujours écrit dans le
`findings.json` canonique du run avant création du manifest.

## Règle de qualification

Le texte d’un outil ne suffit jamais à choisir une catégorie plus grave.

| Preuve explicite disponible | Type | Validation |
|---|---|---|
| état Nmap `open` | `observation` | `observed` |
| suspicion produite par un futur adaptateur documenté | `potential_vulnerability` | `potential` |
| confirmation produite par une méthode documentée et traçable | `confirmed_vulnerability` | `confirmed` |
| donnée ambiguë ou non étayée | aucun constat automatique | aucun statut inventé |

Le premier adaptateur n’émet donc ni vulnérabilité potentielle ni
vulnérabilité confirmée. Une chaîne telle que `VULNERABLE` dans une bannière
reste du texte de preuve et ne change pas le type.

## Valeurs produites

Pour chaque port explicitement ouvert :

- `type: observation` et `validation_status: observed` ;
- `severity: informational` ;
- `scoring.status: unscored` ;
- `confidence: high`, uniquement sur le fait que l’état `open` est présent
  dans le fichier référencé ;
- impact : aucun impact de sécurité établi par l’ouverture seule ;
- remédiation : aucune priorité automatique, examen contextuel requis ;
- limites : absence de confirmation indépendante et absence de conclusion de
  vulnérabilité.

Ces valeurs décrivent la portée de l’observation. Elles ne constituent ni une
note de risque, ni une recommandation de fermeture du port, ni une validation
de sécurité.

## Identifiants et fusion

L’identifiant est stable pour le module, l’actif, le transport et le port :

```text
finding.20_portscan_nmap.open.<asset>.<transport>.<port>
```

La fusion accepte plusieurs tableaux conformes, notamment un fichier fourni
par un autre adaptateur. Elle garantit :

- un seul constat par identifiant ;
- fusion des références de preuve lorsque les contenus portant le même
  identifiant sont identiques ;
- rejet d’une collision lorsque deux contenus différents utilisent le même
  identifiant ;
- tri déterministe ;
- validation du contrat `1.0.0` avant remplacement atomique de la destination.

Une erreur laisse le précédent fichier valide intact.

## Fixtures et couverture

Les fixtures sont entièrement synthétiques et utilisent uniquement
`192.0.2.0/24` et `example.invalid` :

- `nmap-portscan-positive.gnmap` : TCP, UDP, nom d’hôte et identification de
  service ;
- `nmap-portscan-negative.gnmap` : ports fermés ou filtrés, donc aucun
  constat ;
- `nmap-portscan-partial.gnmap` : une entrée valide conservée et une entrée
  ouverte malformée signalée puis ignorée.

`tests/test_findings_adapters.sh` couvre aussi la fusion multi-module,
l’idempotence, les collisions contradictoires, une base non conforme et les
chemins de preuve dangereux. Aucun test ne lance de scan.

## Compatibilité et limites

| Élément | Compatibilité |
|---|---|
| contrat de sortie | `findings[]` `1.0.0` strict |
| manifest produit | `audit-suite.manifest` `1.2.0` |
| manifests `1.0.0` et `1.1.0` | lecture historique normalisée, sans constats |
| dépendances | Bash et `jq`, déjà requis par le moteur |
| sortie Nmap prise en charge | fichiers `.gnmap` de `20_portscan_nmap` |

Les sorties NSE, WhatWeb et les autres modules ne sont pas encore adaptées.
Une liste vide signifie qu’aucune observation structurée prise en charge n’a
été produite ; elle ne prouve jamais l’absence de faille.
