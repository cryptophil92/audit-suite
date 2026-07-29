# Rapport HTML local

Audit Suite génère un rapport premium local et autonome à partir d’un
`manifest.json`. Le rendu privé complet est le mode par défaut.

## Commande

Générer le rapport à côté du manifest :

```bash
bash bin/report_html.sh output/AUDIT_1/manifest.json
```

Cela crée :

```text
output/AUDIT_1/report.html
```

Générer vers un chemin explicite :

```bash
bash bin/report_html.sh output/AUDIT_1/manifest.json output/AUDIT_1/rapport.html
```

Générer une copie partageable :

```bash
bash bin/report_html.sh --shareable output/AUDIT_1/manifest.json
```

Cela crée `report-shareable.html` avec les cibles, actifs et chemins directs
masqués. Les textes libres restent à relire manuellement.

Conserver l’ancien relevé centré sur les modules :

```bash
bash bin/report_html.sh --technical output/AUDIT_1/manifest.json
```

Cela crée `report-technical.html`.

## Entrée

Le script lit les manifests AUDIT-SUITE `1.0.0`, `1.1.0` et `1.2.0` décrits
dans :

```text
docs/REPORT_SCHEMA.md
```

Champs utilisés :

- `run_id`
- `created_at`
- `profile`
- `targets`
- `options`
- `paths`
- `summary`
- `modules`
- `findings_schema_version`
- `findings`

## Contenu du rapport

Le rapport contient deux niveaux de lecture.

### Synthèse décisionnelle

- complétude de l’audit ;
- répartition des constats ;
- priorités principales ;
- conclusion prudente ;
- vérifications indisponibles ou partielles ;
- avertissement de confidentialité ;
- absence explicite de note globale artificielle.

### Détail technique

- constats triés par priorité, gravité et confiance ;
- actif, service et périmètre ;
- observation et impact ;
- score, méthode, vecteur et justification, ou état `Non noté` ;
- provenance et preuves référencées ;
- remédiation, effort, risque du changement et vérification ;
- références et limites ;
- plan d’action ;
- modules, options, chemins et index des preuves.

Les manifests `1.0.0` et `1.1.0` restent lisibles. Ils produisent un rapport
sans constat et une explication indiquant que cette absence ne prouve pas que
le périmètre est sécurisé.

## Version partageable

Le mode `--shareable` masque :

- l’identifiant du run ;
- les cibles ;
- les identifiants, adresses et noms d’hôtes des actifs ;
- les chemins du manifest, des logs, des modules et des preuves ;
- la provenance détaillée.

Il ne tente pas de réécrire automatiquement les titres, observations, impacts,
remédiations ou autres textes libres. Cette copie réduit l’exposition directe,
mais ne remplace pas une revue humaine avant partage.

Le pack privé n’intègre pas automatiquement `report-shareable.html`.

## Accessibilité et impression

- lien d’évitement ;
- navigation interne ;
- titres hiérarchiques ;
- tableaux avec `caption` et en-têtes `scope` ;
- libellés textuels en plus des couleurs ;
- composants natifs `details/summary` utilisables au clavier ;
- focus visible ;
- reflow mobile sans dépendance JavaScript ;
- thème clair/sombre selon le système ;
- feuille d’impression A4 avec contrôle des sauts de page ;
- contenu autonome utilisable pour l’impression ou l’enregistrement PDF du
  navigateur.

## Sécurité d'affichage

Les valeurs issues du JSON sont échappées avant insertion dans le HTML via
`jq @html`. Seules les références `http://` ou `https://` deviennent des liens.
Les chemins de preuve restent du texte.

Le rapport est un fichier statique local sans JavaScript ni feuille de style
externe. Il ne lance aucun scan, ne contacte aucun service et ne dépend d’aucun
backend.

## Objectif

Le rapport sert à décider, corriger et vérifier sans devoir ouvrir le JSON brut,
tout en conservant la traçabilité technique.
