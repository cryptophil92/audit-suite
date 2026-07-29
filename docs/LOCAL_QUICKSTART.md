# Démarrage local rapide

Cette procédure permet de vérifier AUDIT-SUITE localement sans lancer d'audit réel.

## 1. Vérifier l’environnement

```bash
bash bin/check_deps.sh
```

Cette commande ne modifie rien. Elle distingue le socle bloquant, les
fonctions annexes indisponibles et les modules qui seraient ignorés. Voir
[`PREFLIGHT.md`](PREFLIGHT.md).

## 2. Vérifier les commandes JSON

```bash
bash bin/smoke_local.sh
```

Le smoke test contrôle les sorties JSON principales et le dry-run.

## 3. Lancer l'API locale

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

L'écoute est locale par défaut.

## 4. Ouvrir le dashboard

```text
http://127.0.0.1:8765/
```

Le dashboard affiche :

- état moteur ;
- modules ;
- historique ;
- aperçu de plan ;
- routes locales ;
- dernier run.

## 5. Tester un aperçu de plan

Exemple direct :

```bash
bash bin/plan_json.sh --profile fast --targets 192.168.1.0/24 --categories all --run-id TEST_LOCAL --no-zeek --no-suricata
```

Cette commande produit un plan JSON sans lancer de module réel.
Le lanceur `audit.sh --dry-run` ajoute un préflight humain avant ce plan.

## 6. Consulter les routes

```bash
bash bin/routes_json.sh
```

Ou via l'API locale :

```text
http://127.0.0.1:8765/api/routes
```

## 7. Consulter la version

```bash
bash bin/version_json.sh
```

## Garde-fous

- Ne pas fusionner les PR empilées avant test local réel.
- Conserver l'écoute API sur `127.0.0.1` tant que l'accès distant n'est pas explicitement validé.
- Ne pas lancer de scan hors réseau personnel, lab ou environnement autorisé.
- Utiliser d'abord `--dry-run` et les commandes JSON avant toute exécution réelle.
