# Interface web locale

`web/index.html` est une première interface locale en lecture seule. Le style
et le comportement sont servis par `web/styles.css` et `web/app.js`, sans
dépendance front-end externe.

## Lancement

```bash
python3 api/server.py --host 127.0.0.1 --port 8765
```

Puis ouvrir :

```text
http://127.0.0.1:8765/
```

## Données affichées

La page lit :

```text
GET /api/snapshot
GET /api/plan
GET /api/routes
```

Elle affiche :

- l'état moteur ;
- le nombre de modules ;
- le nombre de runs historisés ;
- la table des modules disponibles ;
- la liste des routes API locales ;
- le dernier run au format JSON ;
- un aperçu JSON à partir des paramètres saisis.

## Formulaire d'aperçu

Le formulaire propose :

- cibles ;
- profil ;
- mode de sélection : tous les modules ou éléments cochés ;
- liste construite depuis les données du snapshot ;
- run ID ;
- options `no_zeek` et `no_suricata`.

Le bouton affiche uniquement le JSON retourné par `/api/plan`.

## Panneau routes

Le panneau `Routes API locales` lit `/api/routes` et affiche :

- méthode ;
- chemin ;
- type de réponse.

## Garanties

- Aucun bouton d'exécution réelle.
- Lecture seule.
- Aucune dépendance front-end externe.
- Compatible avec le serveur local standard library Python.
- Les valeurs issues de l'API sont insérées avec `textContent` ou des nœuds
  texte, jamais interprétées comme du HTML.
- Le sélecteur ne propose que les modules marqués `selectable`.
- Le serveur applique une CSP sans `unsafe-inline`, interdit les objets et
  l'intégration en frame, et ajoute des en-têtes `nosniff`, `DENY` et
  `no-referrer`.

Le test `tests/test_web_safe_rendering.sh` injecte des caractères HTML et des
balises hostiles dans les helpers de rendu. Il vérifie qu'ils restent du texte
littéral et qu'aucun nœud HTML n'est créé.

## Objectif

Cette page sert de base visuelle pour construire progressivement le tableau de bord local AUDIT-SUITE.
