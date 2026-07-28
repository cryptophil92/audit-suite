# Paramètres GitHub recommandés

## État appliqué le 28 juillet 2026

Les changements publics, réversibles et sans effet sur le code suivants ont été appliqués puis vérifiés :

- description de la section **About** ;
- dix topics listés ci-dessous ;
- labels d’audit, de priorité, d’UX, de sécurité, de tests et de roadmap.

Le site Web reste vide, faute d’URL publique vérifiée. Les protections de branche, fonctions de sécurité, options de merge, anciennes pull requests et branches n’ont pas été modifiées.

## Section About

### Description

```text
Suite expérimentale et locale d’audit réseau défensif pour Kali Linux, avec rapports JSON/HTML et tableau de bord en lecture seule.
```

### Site Web

Aucun site public n’est actuellement vérifié. Laisser vide plutôt que d’indiquer une URL non maintenue.

### Topics

```text
network-audit
cybersecurity
defensive-security
kali-linux
bash
nmap
network-security
security-tools
python
local-first
```

État vérifié : ces dix topics sont actifs.

## Fonctionnalités du dépôt

Recommandé :

- Issues : activées ;
- Discussions : désactivées tant qu’aucune modération n’est organisée ;
- Projects : facultatif, à activer si utilisé pour la roadmap ;
- Wiki : désactivé, la documentation est versionnée ;
- Sponsorships : selon décision du propriétaire.

## Sécurité

À activer si disponible :

- Private vulnerability reporting ;
- Dependabot alerts ;
- Dependabot security updates ;
- secret scanning ;
- push protection ;
- code scanning après choix d’une configuration adaptée à Bash/Python.

Ne pas considérer une fonction activée tant qu’elle n’est pas vérifiée dans les paramètres.

## Protection de `main`

Proposition à appliquer après validation du workflow :

- pull request obligatoire ;
- au moins une approbation si plusieurs mainteneurs ;
- conversation résolue ;
- check CI requis ;
- branche à jour avant merge ;
- force push interdit ;
- suppression de branche automatique seulement pour les nouvelles branches, après décision ;
- règles identiques pour les administrateurs si le projet devient collaboratif.

Le check actuel doit d’abord être complété afin de ne pas rendre obligatoire une couverture incomplète.

## Stratégie de merge

Proposition :

- squash merge pour les lots documentaires et corrections ciblées ;
- rebase merge si l’historique de commits est volontairement structuré ;
- désactiver les merge commits si la stratégie choisie est squash-only ;
- aucun automerge sur les changements sécurité/moteur avant validation réelle.

## Releases

1. source de version unique ;
2. changelog mis à jour ;
3. tag annoté ;
4. notes de release avec limitations ;
5. artefacts construits par CI ;
6. sommes de contrôle ;
7. aucune sortie d’audit incluse ;
8. rollback documenté.

Première release recommandée uniquement après correction des P0/P1 de fiabilité. Ne pas publier `0.2.34` comme release stable.

## Jalons proposés

| Jalon | Contenu |
|---|---|
| `P0 — Containment` | données publiques et blocages |
| `0.2.x — Reliability` | statuts, historique, API, tests |
| `0.3.0 — Engine contract` | contrats et installation |
| `0.4.0 — Read-only UX` | navigation, résultats, accessibilité |
| `Cross-platform discovery` | études WSL/macOS/Windows |

## Dette GitHub

Trente anciennes pull requests brouillon et de nombreuses branches fusionnées restent visibles. Préparer une liste vérifiée, fermer les PR obsolètes avec un commentaire pointant vers la consolidation, puis décider séparément de la suppression des branches.

Ne pas supprimer de branche ni fermer de PR sans validation explicite du propriétaire.
