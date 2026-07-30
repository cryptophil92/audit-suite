# Schéma des résultats AUDIT-SUITE

Depuis `v0.2.2-report-schema`, le manifest de run contient un schéma versionné.

## Manifest

Chemin généré :

```text
output/<RUN_ID>/manifest.json
```

Type logique :

```json
{
  "kind": "audit-suite.manifest",
  "schema_version": "1.2.0",
  "findings_schema_version": "1.0.0",
  "version": "X.Y.Z",
  "commit": "0123456789abcdef"
}
```

## Champs racine

| Champ | Type | Description |
|---|---:|---|
| `schema_version` | string | Version du schéma manifest. |
| `findings_schema_version` | string | Version du contrat `findings[]`. |
| `kind` | string | Type logique du document. |
| `version` | string | Version applicative lue depuis `VERSION`. |
| `commit` | string | Commit Git du code exécuté, ou `unknown`. |
| `run_id` | string | Identifiant horodaté du run. |
| `created_at` | string | Date ISO de génération du manifest. |
| `profile` | string | Profil utilisé : `fast`, `full` ou `stealth`. |
| `targets` | array | Cibles validées. |
| `options` | object | Options d'exécution. |
| `paths` | object | Chemins principaux générés. |
| `selected_modules` | array | Modules demandés. |
| `summary` | object | Résumé exploitable par API/export. |
| `modules` | array | Résultat détaillé par module. |
| `findings` | array | Constats de sécurité structurés. |

## `summary`

```json
{
  "module_count": 3,
  "success_count": 1,
  "partial_count": 1,
  "failed_count": 0,
  "skipped_count": 1,
  "total_duration_seconds": 42,
  "status": "partial",
  "findings": {
    "total_count": 0,
    "scored_count": 0,
    "unscored_count": 0,
    "by_severity": {
      "informational": 0,
      "low": 0,
      "medium": 0,
      "high": 0,
      "critical": 0,
      "unknown": 0
    },
    "by_confidence": {
      "low": 0,
      "medium": 0,
      "high": 0
    }
  }
}
```

Valeurs possibles pour `summary.status` :

- `success` : au moins un module réussi, sans module partiel ni échoué ;
- `partial` : au moins un module partiel et aucun module échoué ;
- `failed` : au moins un module échoué ;
- `empty` : aucun module exécuté ou enregistré.

## Résultat module

Chaque entrée de `modules[]` suit cette structure :

```json
{
  "id": "10_network_discovery",
  "name": "Découverte réseau",
  "path": "modules/10_network_discovery.sh",
  "status": "success",
  "rc": 0,
  "started_at": "2026-07-01T00:00:01+00:00",
  "finished_at": "2026-07-01T00:00:02+00:00",
  "duration_seconds": 1,
  "output_path": "output/AUDIT_.../10_network_discovery",
  "reason": ""
}
```

Valeurs possibles pour `modules[].status` :

- `success`
- `partial`
- `failed`
- `skipped`

## Contrat d’état des modules

- `success` : les étapes structurantes et facultatives demandées ont réussi.
- `partial` : les étapes structurantes ont réussi, mais au moins une étape explicitement facultative a échoué. Les fichiers utiles déjà produits sont conservés et `reason` explique la limitation.
- `failed` : une étape structurante, le contrat du module ou son délai a échoué. Un code non nul non déclaré ne peut jamais devenir `success`.
- `skipped` : le module n’a pas été exécuté, par option explicite, dépendance
  manquante ou métadonnée `selectable: false`.

Un module peut appeler `module_mark_partial "raison"` uniquement pour une
étape réellement facultative ou une couverture fonctionnelle annoncée comme
partielle. SMB utilise cet état pour rappeler qu’il détecte seulement les
ports 139/445. Zeek et Suricata sont des placeholders non sélectionnables ;
leurs anciennes options restent acceptées sans activer de capacité.

Le schéma `1.1.0` ajoute `partial` et `summary.partial_count`.

Le schéma `1.2.0` ajoute :

- `findings_schema_version` ;
- `findings[]` ;
- `summary.findings`.

Le contrat détaillé, les vocabulaires et les règles de notation sont décrits
dans [`FINDINGS_CONTRACT.md`](FINDINGS_CONTRACT.md).

Les lecteurs doivent continuer à accepter les manifests `1.0.0` et `1.1.0`.
La commande suivante les normalise en lecture avec une liste vide sans modifier
le fichier source :

```bash
bash bin/manifest_json.sh normalize output/AUDIT_1/manifest.json
```

Validation explicite :

```bash
bash bin/manifest_json.sh validate output/AUDIT_1/manifest.json
```

## Objectif

Ce schéma prépare :

- l'API locale ;
- les exports HTML/PDF ;
- l'interface web ;
- la comparaison entre deux audits ;
- l'exploitation des résultats sans relire les logs bruts.

## Limites actuelles

Le contrat permet désormais de transporter des constats structurés, mais les
modules réels ne disposent pas encore tous d’un adaptateur vers `findings[]`.
`20_portscan_nmap` adapte les ports explicitement ouverts en observations
d’inventaire ; les sorties NSE, WhatWeb et les autres modules ne sont pas
encore couvertes. Une liste vide signifie uniquement qu’aucun constat
structuré pris en charge n’a été produit ; elle ne démontre pas l’absence de
faille.

Le rapport HTML premium affiche `findings[]` avec une synthèse, les preuves
référencées et le plan de remédiation. Sa conception et ses limites sont
décrites dans [`PREMIUM_REPORT_SPEC.md`](PREMIUM_REPORT_SPEC.md).

Aucun lecteur ne doit interpréter un statut de module comme une note de risque.
