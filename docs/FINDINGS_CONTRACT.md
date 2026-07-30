# Contrat des constats

## Statut

Le manifest `audit-suite.manifest` au schéma `1.2.0` prend en charge le contrat
`findings[]` version `1.0.0`.

Ce contrat structure les informations disponibles sans convertir
automatiquement une sortie d’outil en vulnérabilité confirmée. Les modules
réels ne disposent pas encore tous d’un adaptateur de constats. Le premier
adaptateur couvre les ports explicitement ouverts de `20_portscan_nmap` et
produit uniquement des observations d’inventaire.

## Sources canoniques

- JSON Schema :
  [`../schemas/findings-1.0.0.schema.json`](../schemas/findings-1.0.0.schema.json) ;
- règles runtime et contraintes croisées :
  [`../schemas/findings-1.0.0.validator.jq`](../schemas/findings-1.0.0.validator.jq) ;
- validation et normalisation :
  [`../core/lib_findings.sh`](../core/lib_findings.sh) ;
- adaptation et fusion :
  [`../core/lib_findings_adapters.sh`](../core/lib_findings_adapters.sh) et
  [`../bin/findings_from_modules.sh`](../bin/findings_from_modules.sh) ;
- fixture publique synthétique :
  [`../tests/fixtures/findings/manifest-1.2.0.json`](../tests/fixtures/findings/manifest-1.2.0.json).

Le validateur runtime complète JSON Schema pour les contraintes croisées :
unicité des identifiants, score inférieur ou égal à l’échelle, cohérence CVSS
et compteurs du résumé.

## Intégration au manifest

```json
{
  "kind": "audit-suite.manifest",
  "schema_version": "1.2.0",
  "findings_schema_version": "1.0.0",
  "summary": {
    "findings": {
      "total_count": 2,
      "scored_count": 1,
      "unscored_count": 1,
      "by_severity": {
        "informational": 1,
        "low": 0,
        "medium": 1,
        "high": 0,
        "critical": 0,
        "unknown": 0
      },
      "by_confidence": {
        "low": 0,
        "medium": 1,
        "high": 1
      }
    }
  },
  "findings": []
}
```

Le résumé contient des comptes, jamais une moyenne ou une note globale.

## Compatibilité

| Schéma manifest | Lecture | Résultat normalisé |
|---|---|---|
| `1.0.0` | acceptée | `findings_schema_version: 1.0.0`, `findings: []` |
| `1.1.0` | acceptée | `findings_schema_version: 1.0.0`, `findings: []` |
| `1.2.0` | validation stricte | constats et compteurs conservés |

La normalisation ne modifie ni le fichier source ni son `schema_version`.

```bash
bash bin/manifest_json.sh validate output/AUDIT_1/manifest.json
bash bin/manifest_json.sh normalize output/AUDIT_1/manifest.json
```

## Entrée du générateur

Le générateur cherche par défaut :

```text
<RUN_DIR>/findings.json
```

Ce fichier est optionnel et doit contenir un tableau conforme au contrat
`1.0.0`.

- fichier absent : le manifest contient `findings: []` ;
- fichier valide : les constats et compteurs sont intégrés ;
- fichier présent mais invalide : la génération du manifest échoue sans publier
  un manifest partiel.

Après les modules, `audit.sh` exécute les adaptateurs locaux puis valide leur
fusion avant de créer le manifest. `AUDIT_FINDINGS_FILE` permet de fournir un
tableau de base : il est lu sans être modifié, fusionné dans le
`<RUN_DIR>/findings.json` canonique puis revalidé.

La commande autonome et les règles détaillées sont documentées dans
[`FINDINGS_ADAPTERS.md`](FINDINGS_ADAPTERS.md). Tout futur adaptateur doit
produire des constats uniquement à partir de données disponibles et traçables.

## Champs d’un constat

| Champ | Rôle |
|---|---|
| `id` | identifiant stable et unique, préfixé par `finding.` |
| `type` | nature du constat |
| `title`, `category` | lecture courte et regroupement |
| `asset`, `scope`, `service` | emplacement concerné |
| `severity` | impact et urgence potentiels |
| `scoring` | notation justifiée ou état `unscored` |
| `confidence` | solidité du lien entre preuve et constat |
| `validation_status` | état de confirmation ou de traitement |
| `observation`, `impact` | fait observé et conséquence possible |
| `evidence[]` | références de preuves, sans contenu brut intégré |
| `source` | module, outil, date et provenance |
| `remediation` | action, justification, effort, risque et vérification |
| `references`, `limitations` | sources utiles et incertitudes |

## Vocabulaires

### Type

```text
observation
potential_vulnerability
confirmed_vulnerability
informational
```

### Gravité

```text
informational
low
medium
high
critical
unknown
```

### Confiance

```text
low
medium
high
```

### Validation

```text
observed
potential
confirmed
false_positive
accepted_risk
resolved
unknown
```

## Notation

Un constat utilise exactement l’un des deux états.

### Non noté

```json
{
  "status": "unscored",
  "rationale": "Les données sources sont insuffisantes pour une note fiable."
}
```

### Noté

```json
{
  "status": "scored",
  "score": 5.3,
  "scale": 10,
  "method": "cvss-v3.1",
  "method_version": "3.1",
  "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N",
  "rationale": "Vecteur complet dérivé de données synthétiques.",
  "source": "fixture_synthetic"
}
```

Règles :

- le score ne dépasse pas son échelle ;
- méthode, version, source et justification sont obligatoires ;
- les méthodes `cvss-v3.1`, `cvss-v4.0`, `source` et `manual` sont admises ;
- un score CVSS exige un vecteur de la version annoncée ;
- `unscored` est préférable à une précision inventée ;
- aucune note globale n’est dérivée par moyenne.

## Preuves

Une preuve est une référence structurée, pas un bloc HTML ou une sortie brute.

```json
{
  "id": "evidence.synthetic.tls-legacy.001",
  "kind": "file_reference",
  "source": "30_vuln_nmap_nse",
  "path": "30_vuln_nmap_nse/synthetic-tls-check.json",
  "captured_at": "2026-07-29T10:10:00Z"
}
```

Le chemin :

- est relatif au dossier du run ;
- utilise des séparateurs `/` ;
- n’accepte ni chemin absolu ni segment `..` ;
- ne doit jamais être concaténé directement dans du HTML.

Les lecteurs et rapports doivent toujours échapper les chaînes avant
affichage.

## Données synthétiques

Les fixtures utilisent les plages et domaines réservés à la documentation :

- `192.0.2.0/24` ;
- `example.invalid`.

Elles ne contiennent aucun résultat de scan réel.
