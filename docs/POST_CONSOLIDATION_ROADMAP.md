# Roadmap post-consolidation v0.2.32

Ce document fixe l'état de référence après consolidation de la pile v0.2.32 dans `main`.

## État de référence

- `main` contient la pile v0.2.32 consolidée.
- La PR #34 a remplacé la fusion progressive des anciennes PR empilées.
- Le smoke local a été validé sur Windows avec Git Bash.
- Le dépôt local était propre après validation.

## Anciennes PR empilées

Les PR historiques #2 à #33 ne doivent plus servir de base de travail.

Elles peuvent être fermées ou ignorées, car leur contenu utile a été consolidé dans `main` via la PR #34.

## Base de travail obligatoire

Tout nouveau lot doit partir de `main`.

```bash
git checkout main
git pull origin main
```

## Prochains lots recommandés

### v0.2.33 - Nettoyage post-consolidation

Objectif : stabiliser l'organisation après la consolidation.

À faire :

- fermer ou ignorer les anciennes PR empilées ;
- conserver la PR #34 comme point de référence ;
- garder les branches historiques uniquement comme archive temporaire ;
- ne plus créer de PR basée sur les branches `feat/v0.2.*` historiques.

### v0.2.34 - Lecture détaillée des runs

Objectif : enrichir l'API locale en lecture seule.

À prévoir :

- endpoint de liste détaillée des runs ;
- endpoint de lecture du manifest d'un run ;
- endpoint de lecture des chemins de rapports ;
- tests associés.

### v0.2.35 - Ergonomie dashboard lecture seule

Objectif : améliorer l'interface sans ajouter d'exécution réelle.

À prévoir :

- états d'erreur plus lisibles ;
- affichage détaillé du dernier run ;
- liens locaux vers les rapports si disponibles ;
- panneau de diagnostic API.

### v0.3.0 - Contrôleur d'exécution sécurisé préparatoire

Objectif : préparer une future exécution contrôlée sans l'activer par défaut.

Garde-fous obligatoires :

- aucune exécution réelle depuis le dashboard sans validation explicite ;
- confirmation visible du périmètre autorisé ;
- blocage public par défaut ;
- dry-run prioritaire ;
- journalisation systématique ;
- écoute locale par défaut.

## Règles permanentes

- Usage strictement défensif et autorisé.
- API locale sur `127.0.0.1` par défaut.
- Dashboard en lecture seule tant que le contrôleur d'exécution n'est pas validé.
- Aucun scan sur cible publique sans autorisation explicite.
- Tester localement avant fusion.
