# Checklist de test local avant fusion

Cette checklist doit être utilisée avant de passer les PR de brouillon à prêtes pour revue ou avant toute fusion.

## 1. Préparation

```bash
git status
git branch --show-current
```

Vérifier :

- dépôt propre ;
- bonne branche ;
- aucune sortie runtime inattendue suivie par Git.

## 2. Contrôle JSON et dry-run

```bash
bash bin/smoke_local.sh
```

Attendu :

```text
[OK] local smoke test passed
```

## 3. Aperçu de plan CLI

```bash
bash bin/plan_json.sh \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories all \
  --run-id LOCAL_TEST_PLAN \
  --no-zeek \
  --no-suricata
```

Vérifier :

- `kind` vaut `audit-suite.plan` ;
- les cibles sont correctes ;
- les chemins prévus sont cohérents ;
- aucun dossier `output/LOCAL_TEST_PLAN` n'est créé.

## 4. Dry-run moteur

```bash
bash audit.sh \
  --dry-run \
  --profile fast \
  --targets 192.168.1.0/24 \
  --categories all \
  --run-id LOCAL_TEST_DRY_RUN \
  --no-zeek \
  --no-suricata
```

Vérifier :

- aucun module réel lancé ;
- aucun dossier de run créé ;
- le plan affiché est cohérent.

## 5. API locale

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Vérifier dans le navigateur :

```text
http://127.0.0.1:8765/
```

Puis vérifier aussi :

```text
http://127.0.0.1:8765/api/health
http://127.0.0.1:8765/api/routes
http://127.0.0.1:8765/api/snapshot
```

## 6. Interface web

Dans le dashboard :

- vérifier l'état moteur ;
- vérifier la liste des modules ;
- vérifier la liste des routes ;
- produire un aperçu de plan ;
- confirmer qu'aucun bouton d'exécution réelle n'est présent.

## 7. Test de sécurité basique

Vérifier qu'une cible publique est refusée sans option explicite :

```bash
bash bin/plan_json.sh --profile fast --targets 8.8.8.8/32 --categories all
```

Attendu : refus de validation.

## 8. Après test

```bash
git status
```

Vérifier :

- aucun fichier runtime ajouté ;
- pas de dossier `output/` suivi ;
- pas de dossier `logs/` suivi ;
- pas de dossier `history/` suivi.

## Validation finale

Les PR peuvent être passées en revue seulement si :

- smoke local OK ;
- dry-run OK ;
- API locale OK ;
- dashboard OK ;
- garde-fous publics OK ;
- aucun fichier runtime suivi par Git.
