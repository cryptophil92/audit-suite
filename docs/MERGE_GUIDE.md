# Guide de fusion progressive

Ce guide décrit la méthode recommandée pour fusionner les PR empilées après validation locale.

## Précondition

Avant toute fusion :

```bash
bash bin/smoke_local.sh
```

Puis suivre `docs/LOCAL_TEST_CHECKLIST.md`.

## Règle principale

Fusionner dans l'ordre croissant :

```text
#1, #2, #3, ... #33
```

Ne jamais fusionner une PR si la précédente n'est pas déjà fusionnée ou explicitement abandonnée.

## Méthode recommandée

Pour chaque PR :

1. vérifier que la PR est toujours verte ;
2. vérifier qu'elle est bien basée sur la branche précédente ;
3. relire rapidement les fichiers modifiés ;
4. passer la PR en ready for review si le test local est OK ;
5. fusionner ;
6. passer à la PR suivante.

## Points d'arrêt recommandés

### Après PR #7

Le socle rapports est en place.

Vérifier :

```bash
bash tests/test_manifest_schema.sh
bash tests/test_report_html.sh
bash tests/test_report_pack.sh
bash tests/test_report_pipeline.sh
```

### Après PR #13

Les garde-fous CLI sont en place.

Vérifier :

```bash
bash tests/test_args.sh
bash tests/test_dry_run.sh
bash tests/test_modules.sh
bash tests/test_run_paths.sh
```

### Après PR #19

Le smoke local est disponible.

Vérifier :

```bash
bash bin/smoke_local.sh
```

### Après PR #24

L'API locale, le dashboard et OpenAPI sont en place.

Vérifier :

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Puis ouvrir :

```text
http://127.0.0.1:8765/
```

### Après PR #33

La documentation de test et de fusion est complète.

Vérifier :

```text
docs/LOCAL_QUICKSTART.md
docs/LOCAL_TEST_CHECKLIST.md
docs/PR_STACK_MAP.md
docs/MERGE_GUIDE.md
```

## Rollback simple

Si un problème est détecté avant fusion :

- laisser la PR en brouillon ;
- ne pas fusionner ;
- corriger sur la branche concernée ;
- relancer la CI ;
- reprendre la checklist.

Si un problème est détecté après fusion :

- arrêter la fusion des PR suivantes ;
- identifier la PR fautive ;
- créer une PR de correction depuis l'état courant ;
- ne pas forcer la suite tant que la correction n'est pas validée.

## Interdictions temporaires

Tant qu'aucun test local réel n'a été réalisé :

- ne pas exposer l'API hors `127.0.0.1` ;
- ne pas ajouter de lancement réel depuis le dashboard ;
- ne pas fusionner la pile ;
- ne pas activer d'automerge.
