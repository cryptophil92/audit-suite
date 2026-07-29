# Spécification du rapport premium

## Statut

Spécification produit initiale du 29 juillet 2026. Le contrat de données de
l’issue [#70](https://github.com/cryptophil92/audit-suite/issues/70) est
implémenté dans le manifest `1.2.0`. Le rendu HTML premium de
[#71](https://github.com/cryptophil92/audit-suite/issues/71) est disponible en
mode privé ou partageable. La validation sur des audits réels et le suivi
avant/après restent hors de ce lot.

## État actuel confirmé

Le manifest `1.2.0` prend en charge le contrat `findings[]` version `1.0.0`,
sa validation stricte et la normalisation des manifests `1.0.0/1.1.0`. Les
modules réels ne disposent pas encore tous d’un adaptateur de constats.

Le rapport HTML premium affiche :

- un résumé exécutif prudent ;
- la couverture et les vérifications incomplètes ;
- les constats priorisés ;
- les notes justifiées et les états `Non noté` ;
- les preuves, impacts, remédiations et vérifications ;
- un plan d’action ;
- une annexe technique ;
- une checklist de confidentialité.

Le mode partageable masque les identifiants directs et chemins. Il impose
toujours une revue des textes libres avant diffusion.

## Objectifs

Le rapport doit :

- être compréhensible sans lire les logs ;
- permettre de décider quoi traiter en premier ;
- conserver la preuve et le détail technique ;
- montrer la couverture et l’incertitude ;
- éviter les scores décoratifs ;
- rester local, autonome, imprimable et accessible ;
- signaler les données sensibles avant partage.

## Architecture du rapport

### 1. Couverture

- nom Audit Suite ;
- identifiant du rapport et de l’audit ;
- date de génération ;
- version et commit ;
- périmètre ;
- profil ;
- statut de confidentialité ;
- mention « données synthétiques » lorsque pertinent.

### 2. Résumé exécutif

- objectif et périmètre ;
- état de complétude ;
- nombre de constats par gravité et confiance ;
- trois priorités maximum ;
- vérifications indisponibles ou partielles ;
- conclusion prudente ;
- liens internes vers les détails.

Le résumé ne doit pas affirmer que le réseau est « sécurisé ». Une absence de
constat signifie seulement qu’aucun constat n’a été produit dans le périmètre et
avec les vérifications exécutées.

### 3. Couverture et limites

- actifs et plages évalués ;
- vérifications demandées, exécutées, partielles, ignorées et échouées ;
- outils et versions ;
- privilèges disponibles ;
- durée ;
- limites de détection ;
- zones non couvertes ;
- fraîcheur des preuves.

### 4. Liste priorisée des constats

Chaque ligne ou carte présente :

- titre ;
- actif/service ;
- type ;
- gravité ;
- score éventuel ;
- confiance ;
- statut de validation ;
- priorité de remédiation ;
- résumé de l’action.

Filtres prévus :

- gravité ;
- confiance ;
- statut ;
- actif ;
- catégorie ;
- état de remédiation.

### 5. Détail d’un constat

- description factuelle ;
- actif et service concernés ;
- observation ;
- impact possible ;
- preuve et source ;
- méthode de notation ;
- confiance et limites ;
- remédiation ;
- effort et risque du changement ;
- méthode de vérification ;
- références ;
- historique avant/après lorsque disponible.

### 6. Plan d’action

- actions immédiates ;
- actions à court terme ;
- améliorations de fond ;
- dépendances entre actions ;
- effort estimé ;
- responsable et échéance uniquement si renseignés explicitement ;
- statut de traitement.

### 7. Annexe technique

- manifest ;
- modules et codes retour ;
- commandes exécutées, uniquement dans la version privée ;
- chemins et fichiers de preuve ;
- logs sélectionnés ;
- versions ;
- options ;
- méthodologie ;
- empreinte des artefacts.

## Contrat conceptuel d’un constat

Le format exact est versionné dans
[`FINDINGS_CONTRACT.md`](FINDINGS_CONTRACT.md). Exemple synthétique minimal :

```json
{
  "id": "finding.synthetic.tls-legacy.001",
  "type": "potential_vulnerability",
  "title": "Protocole TLS ancien potentiellement accepté",
  "category": "transport_security",
  "asset": {
    "id": "asset.synthetic.web-01",
    "address": "192.0.2.10",
    "hostname": "web-01.example.invalid"
  },
  "scope": {
    "target": "192.0.2.0/24",
    "relation": "direct"
  },
  "service": {
    "transport": "tcp",
    "port": 443,
    "name": "https"
  },
  "severity": "medium",
  "scoring": {
    "status": "scored",
    "score": 5.3,
    "scale": 10,
    "method": "cvss-v3.1",
    "method_version": "3.1",
    "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N",
    "rationale": "Vecteur complet fourni par la fixture synthétique.",
    "source": "fixture_synthetic"
  },
  "confidence": "medium",
  "validation_status": "potential",
  "observation": "La vérification synthétique indique une configuration à confirmer.",
  "impact": "Un protocole ancien peut réduire la robustesse du transport.",
  "evidence": [
    {
      "id": "evidence.synthetic.tls-legacy.001",
      "kind": "file_reference",
      "source": "30_vuln_nmap_nse",
      "path": "30_vuln_nmap_nse/synthetic-tls-check.json",
      "captured_at": "2026-07-29T10:00:00Z"
    }
  ],
  "source": {
    "module": "30_vuln_nmap_nse",
    "tool": "synthetic-fixture",
    "tool_version": "1.0.0",
    "collected_at": "2026-07-29T10:00:00Z",
    "provenance": "Donnée entièrement synthétique réservée aux tests."
  },
  "remediation": {
    "priority": "short_term",
    "effort": "medium",
    "action": "Vérifier la configuration TLS puis désactiver les protocoles obsolètes.",
    "rationale": "Réduire l’exposition aux protocoles de transport anciens.",
    "prerequisites": [
      "Vérifier la compatibilité des clients autorisés."
    ],
    "change_risk": "Valider la compatibilité des clients avant modification.",
    "verification": "Relancer uniquement la vérification TLS après changement."
  },
  "references": [],
  "limitations": [
    "Le résultat doit être confirmé sur le service cible autorisé."
  ]
}
```

Les adresses et noms ci-dessus sont réservés à la documentation synthétique.

## Vocabulaires

### Type

| Valeur | Sens |
|---|---|
| `observation` | fait utile sans vulnérabilité affirmée |
| `potential_vulnerability` | risque à confirmer |
| `confirmed_vulnerability` | vulnérabilité confirmée par une preuve suffisante |
| `informational` | contexte ou recommandation d’hygiène |

### Gravité

```text
informational
low
medium
high
critical
unknown
```

La gravité décrit l’impact et l’urgence potentiels. Elle ne décrit ni la qualité
de la preuve ni le succès technique du module.

### Confiance

```text
low
medium
high
```

La confiance indique la solidité du lien entre la preuve et le constat.

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

## Règles de notation

### Score par constat

Un score est optionnel. Lorsque présent, il comprend :

- valeur ;
- échelle ;
- méthode ;
- vecteur si applicable ;
- justification ;
- source ;
- version de la méthode.

### Méthodes admises

- `cvss-v3.1` ou autre version explicitement nommée ;
- score fourni par une source reconnue et conservé avec sa provenance ;
- future méthode `audit-suite-v1`, uniquement après documentation et tests ;
- `manual`, avec auteur et justification ;
- `unscored`.

### Règles de prudence

- ne pas inventer un vecteur CVSS ;
- ne pas convertir automatiquement une sortie NSE en vulnérabilité confirmée ;
- ne pas déduire la gravité du seul code retour ;
- ne pas augmenter la note à cause d’une faible confiance ;
- ne pas masquer l’absence d’information avec une valeur zéro ;
- ne pas moyenner les scores pour produire une note globale.

### Note globale

Aucune note globale n’est prévue dans le premier contrat. Une future note de
posture nécessitera :

- une formule publiée ;
- une prise en compte de la couverture ;
- une gestion des actifs critiques ;
- un traitement explicite des constats non notés ;
- une calibration sur des cas représentatifs ;
- une validation utilisateur.

En attendant, le résumé utilise des comptes, des niveaux de gravité, la
confiance et des priorités expliquées.

## Remédiation

Une recommandation exploitable contient :

- action ;
- raison ;
- prérequis ;
- effort ;
- risque du changement ;
- priorité temporelle ;
- solution compensatoire éventuelle ;
- méthode de vérification ;
- référence.

Les formulations génériques telles que « sécuriser le service » sont
insuffisantes.

## Informations sensibles

Avant export, le produit doit signaler :

- adresses et noms d’hôtes ;
- topologie ;
- bannières et versions ;
- vulnérabilités ;
- commandes ;
- chemins locaux ;
- noms d’utilisateur ;
- extraits de logs ;
- métadonnées de client ou d’organisation.

La version partageable doit pouvoir :

- anonymiser les identifiants ;
- exclure les preuves brutes ;
- retirer les commandes et chemins ;
- afficher la liste des transformations ;
- conserver une empreinte du rapport source privé.

## Présentation et accessibilité

- sommaire avec liens internes ;
- titres hiérarchiques ;
- tableaux avec `caption` et `scope` ;
- gravité exprimée par texte, pas seulement couleur ;
- contraste visant WCAG 2.2 AA ;
- focus visible ;
- reflow à 320 px ;
- zoom à 400 % ;
- styles d’impression A4 ;
- sauts de page contrôlés ;
- URL et preuves longues repliables ;
- aucune dépendance réseau pour afficher le rapport.

## Stratégie de tests

### Automatisés

- validation du schéma ;
- compatibilité des manifests hérités ;
- tri des constats ;
- cas `unscored` ;
- données partielles ;
- échappement HTML ;
- absence de données inventées ;
- impression sans perte de sections ;
- garde contre les artefacts réels.

### Visuels et manuels

- desktop clair et sombre ;
- 320/390 px ;
- impression et PDF ;
- clavier ;
- lecteur d’écran ;
- contraste ;
- rapport vide ;
- rapport partiel ;
- volume important de constats ;
- chaînes longues et caractères accentués.

Toutes les fixtures publiques doivent être synthétiques.

## Découpage recommandé

1. contrat `findings[]` et fixture synthétique ;
2. validation et compatibilité du manifest ;
3. adaptateur d’un premier module sur données synthétiques ;
4. résumé et liste des constats ;
5. détail, remédiation et annexe ;
6. impression/PDF et accessibilité ;
7. anonymisation et export ;
8. comparaison avant/après.

État :

- étapes 1, 2, 4 et 5 implémentées ;
- styles écran, mobile et impression de l’étape 6 implémentés, validation
  utilisateur encore requise ;
- anonymisation directe de l’étape 7 implémentée pour les identifiants et
  chemins, avec revue manuelle obligatoire des textes libres ;
- adaptateurs des sorties réelles (#79) et comparaison avant/après encore à
  réaliser.
