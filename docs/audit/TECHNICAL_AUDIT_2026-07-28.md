# Audit technique — 28 juillet 2026

## Résumé exécutif

Audit Suite possède un socle cohérent pour un projet expérimental : validation des cibles, séparation en bibliothèques et modules, sorties structurées, historique local, rapports, API en lecture seule et vingt tests. Le rapport HTML échappe explicitement les valeurs dynamiques, les cibles publiques sont bloquées par défaut et le dernier workflow GitHub Actions observé est vert.

Le projet n’est toutefois pas prêt pour un usage professionnel. Deux constats sont bloquants : des sorties d’audit réseau sont suivies dans le dépôt public, et le mécanisme FIFO de logging peut bloquer le moteur sur POSIX faute de lecteur. Plusieurs modules masquent également leurs erreurs et peuvent produire des succès trompeurs. La fiabilité des résultats doit être traitée avant toute extension fonctionnelle.

L’API et le tableau de bord restent utiles comme prototypes locaux, mais ils nécessitent des limites de ressources, un garde-fou contre l’exposition hors loopback, une gestion robuste de l’historique et une présentation UX des états et résultats. L’installation, les versions, la licence et les releases ne sont pas encore reproductibles.

## Méthode

### Faits confirmés

- lecture des 178 fichiers suivis et inventaire de l’arborescence ;
- inspection du lanceur, des bibliothèques, des modules, de l’API, du Web, des tests, des documents et du workflow ;
- inspection des branches, pull requests, issues, tags et derniers runs GitHub Actions ;
- syntaxe Bash sur 65 scripts ;
- ShellCheck 0.11.0 ;
- exécution des 20 scripts de test ;
- tests ciblés de performance, chemin avec espaces/accents et historique corrompu ;
- recherche locale de motifs de secrets ;
- comparaison des versions GitHub Actions avec leurs releases officielles.

### Limites

- aucun scan réseau réel ;
- pas de Linux/Kali disponible localement ;
- pas de WSL ni Docker ;
- pas de test root/admin ;
- pas de test utilisateur ;
- pas d’accès confirmé aux alertes GitHub Secret Scanning.

## Points positifs

- `core/lib_validate.sh` refuse les formats non IPv4 et les plages publiques par défaut ;
- les cibles sont transmises aux outils via des tableaux Bash ;
- le runner charge les modules dans un shell enfant ;
- les dépendances module sont contrôlées avant exécution ;
- le manifest décrit états, codes retour, durées et chemins ;
- le rapport HTML échappe les champs dynamiques et possède un test XSS ;
- les archives excluent les anciens packs et dossiers temporaires de premier niveau ;
- l’API n’expose aucune route d’exécution réelle ;
- l’API écoute sur `127.0.0.1` par défaut ;
- les réponses utilisent `Cache-Control: no-store` ;
- la suite de tests couvre les principaux formats JSON.

## Problèmes P0

### P0-1 — Données d’audit suivies dans le dépôt public

**Type :** sécurité et confidentialité

**Fait confirmé :** 74 fichiers sous `output/`, `logs/` et `tmp/` sont suivis, pour environ 4,09 Mo. Certains contiennent des résultats techniques issus d’audits réseau.

**Preuve :**

```powershell
git ls-files output logs tmp history
```

**Risque :**

- exposition de topologie, services et empreintes d’un réseau ;
- conservation dans l’historique Git même après une suppression future ;
- duplication par les forks, clones et caches ;
- contradiction directe avec les règles documentaires et le `.gitignore`.

**Recommandation :**

1. traiter l’incident de façon privée ;
2. déterminer la sensibilité et l’autorisation de publication ;
3. définir une stratégie de retrait de l’historique avec communication ;
4. ajouter une garde CI qui échoue si un chemin runtime est suivi ;
5. utiliser uniquement des fixtures synthétiques minimales.

Ce document n’énumère volontairement ni adresses ni empreintes.

### P0-2 — FIFO de logging sans lecteur sur POSIX

**Type :** blocage moteur

**Emplacements :**

- `core/lib_logging.sh`, `init_logging` et `emit` ;
- `audit.sh`, initialisation et premier appel à `emit` ;
- `ui/ui_tmux_logger.sh`.

**Fait confirmé par le code :**

- `init_logging` crée `tmp/eventbus.<RUN_ID>` avec `mkfifo` ;
- `emit` ouvre ce FIFO en écriture synchrone ;
- aucune partie du dépôt ne lit `LOG_BUS` ;
- le premier `emit` intervient avant le lancement de l’aide tmux ;
- l’aide tmux suit `LOG_FILE`, pas le FIFO.

Sur un POSIX où `mkfifo` réussit, l’ouverture en écriture peut attendre indéfiniment un lecteur. Git Bash Windows ne permet pas de reproduire ce comportement parce que la création du FIFO y échoue silencieusement.

**Risque :** premier audit Kali/Linux bloqué après initialisation des dossiers.

**Recommandation :** supprimer le bus inutilisé ou introduire un consommateur non bloquant démarré et supervisé avant tout write, puis ajouter un test Linux avec délai strict.

## Problèmes P1

### P1-1 — Succès trompeurs lorsque les outils de scan échouent

Plusieurs modules terminent leurs commandes principales par `|| true`. Le runner voit alors un code retour nul et écrit `status: success`.

Modules concernés :

- découverte réseau ;
- Nmap NSE vuln ;
- énumération de services ;
- détection SMB ;
- pipeline HTTP ;
- archive du module `90_report_pack`.

**Impact :** un rapport peut déclarer une réussite alors que la commande a échoué ou produit un résultat partiel.

**Recommandation :** capturer le code retour, distinguer `success`, `partial`, `skipped` et `failed`, et réserver les erreurs ignorées aux étapes explicitement facultatives.

### P1-2 — Options Zeek et Suricata représentées comme échecs

Les modules 80 et 81 retournent `1` depuis `mod_pre` lorsque l’option `no-*` est active. Le shell enfant utilise `set -e`, donc le module s’arrête et le runner le marque `failed` si la dépendance existe. Si la dépendance manque, il est marqué `skipped`.

Le même choix utilisateur produit donc des états différents selon la machine.

**Recommandation :** formaliser un protocole de skip explicite indépendant de la présence de l’outil.

### P1-3 — Corruption de l’historique bloque le snapshot

**Problème reproduit :** une seule ligne invalide dans `runs.jsonl` fait échouer `history_json.sh list` et `api_snapshot_json.sh` avec le code 5, sans JSON exploitable.

**Impact :** le tableau de bord et plusieurs routes deviennent indisponibles à cause d’une entrée locale corrompue.

**Recommandation :**

- valider chaque ligne ;
- isoler les entrées invalides ;
- renvoyer un payload `degraded` avec compteur d’erreurs ;
- écrire l’index avec verrouillage ;
- protéger `latest.json` par un nom temporaire unique et un rename atomique.

### P1-4 — API sans délai, limite de sortie ni politique d’exposition

`run_json_command` utilise `subprocess.run` sans `timeout`, sans limite de sortie et sans annulation liée à la requête. L’argument `--host` accepte une adresse non loopback sans avertissement ni authentification.

**Risques :**

- thread occupé indéfiniment ;
- mémoire consommée par une sortie volumineuse ;
- fuite de chemins et stderr locaux dans les réponses ;
- exposition involontaire de l’historique et des plans sur le réseau.

**Recommandation :** refuser par défaut les écoutes non loopback, afficher une confirmation forte si cette capacité est conservée, borner temps et taille, journaliser côté serveur et retourner des erreurs publiques minimales.

### P1-5 — Tests CI incomplets et absence de tests moteur

`tests/test_run_detail_json.sh` existe mais n’a pas d’étape directe dans le workflow. Le smoke couvre seulement une assertion minimale de cette commande. Le chemin d’exécution réel du runner, du logging et des modules n’est pas testé avec des doubles.

**Impact :** une CI verte ne détecte pas les blocages et faux succès les plus importants.

**Recommandation :** générer la liste des tests ou utiliser un runner unique, ajouter des tests de moteur sans réseau et une matrice Linux/Windows adaptée.

### P1-6 — Versions et releases incohérentes

Versions observées :

- `audit.sh` : `0.2.12` ;
- `bin/version_json.sh` : `0.2.27` ;
- `api/server.py` : `0.2.34` ;
- `api/openapi.json` : `0.2.34` ;
- dernier tag : `v0.1.2`.

**Impact :** diagnostic, support, documentation et compatibilité API ambigus.

**Recommandation :** source de version unique, tests de cohérence, changelog, tags signés ou vérifiés et procédure de release.

### P1-7 — Installation non reproductible

Les dépendances système ne sont ni versionnées ni verrouillées. Le workflow installe les versions courantes d’Ubuntu. `check_deps.sh --install` utilise `apt-get` interactif. `ip` et Python ne font pas partie du préflight moteur principal.

**Impact :** comportements variables, installation incomplète et diagnostic difficile.

**Recommandation :** documenter une matrice minimale, séparer moteur/API/modules, fournir un script de diagnostic non mutatif et envisager ensuite paquet ou conteneur de développement.

### P1-8 — Actions GitHub obsolètes et alertes Dependabot désactivées

Le workflow utilise `actions/checkout@v4` et `actions/upload-artifact@v4`. Le 28 juillet 2026, les releases officielles interrogées via GitHub indiquaient `v7.0.1` pour les deux actions.

Les alertes Dependabot sont désactivées au niveau du dépôt.

**Recommandation :** tester les migrations dans une PR CI dédiée, épingler selon la politique retenue et activer les alertes/updates après validation.

### P1-9 — Absence de licence publiée

Le dépôt public ne contient aucun fichier `LICENSE`. Aucune licence ne doit être choisie automatiquement.

**Impact :** les droits de réutilisation et contribution sont ambigus.

**Recommandation :** décision explicite du propriétaire, vérification de compatibilité des composants et ajout d’une licence dans une PR dédiée.

## Problèmes P2

### P2-1 — Catalogue mélange fonctions réelles et placeholders

Les modules SNMP, Zeek et Suricata peuvent apparaître disponibles alors qu’ils n’effectuent pas leur fonction annoncée. Le module SMB est partiel. `modules_json.sh` ne publie ni maturité, ni capacités, ni privilèges requis.

### P2-2 — Pipeline d’archive redondant

`modules/90_report_pack.sh` archive le dossier avant la création du manifest. `finalize_reports.sh` crée ensuite un second pack structuré depuis le manifest. Les sorties et garanties diffèrent.

### P2-3 — Scripts historiques de mutation conservés sans statut

Plusieurs `bin/patch_*.sh`, `bin/update_modules.sh` et sauvegardes `.bak-*` restent suivis. `update_modules.sh` accepte un chemin fourni par l’entrée et reconstruit le contenu avec des séquences `\n` littérales.

Ces outils ne sont ni testés ni présentés comme historiques/dangereux.

### P2-4 — Écritures concurrentes non coordonnées

Le contrôle d’unicité du run est séparé de la création des dossiers. L’historique append et le fichier temporaire `latest.json.tmp` ne sont pas verrouillés. Deux processus peuvent se concurrencer.

### P2-5 — Catalogues de routes dupliqués

Les routes sont répétées dans :

- `api/server.py` ;
- `api/openapi.json` ;
- `bin/routes_json.sh` ;
- la documentation ;
- les tests.

Une dérive est déjà visible : la route `history/paths` n’est pas présente partout et OpenAPI omet certains paramètres du plan.

### P2-6 — Injection DOM potentielle dans le tableau de bord

Le tableau de bord utilise `innerHTML` avec des valeurs provenant du catalogue de modules et des routes. Une valeur locale non fiable peut devenir du balisage.

**Recommandation :** créer les cellules avec `textContent`, valider les données et ajouter un test front-end de non-interprétation.

### P2-7 — Ligne de fin non imposée

Sans `.gitattributes`, un checkout Windows configuré avec `core.autocrlf` convertit les scripts en CRLF. ShellCheck Windows signale alors des erreurs de parsing, alors que la CI sur blob LF passe.

### P2-8 — Dette GitHub publique

Trente anciennes pull requests brouillon restent ouvertes alors que leurs changements sont consolidés dans `main`. De nombreuses branches historiques sont déjà fusionnées.

**Impact :** page Pull Requests difficile à comprendre et risque de reprendre une base obsolète.

### P2-9 — Privilèges et environnement non explicités

Les profils `full` et `stealth` utilisent des options Nmap qui peuvent nécessiter des privilèges élevés. `detect_env` suppose la commande Linux `ip`. Il n’existe pas de diagnostic préalable par module indiquant droits, interface ou capacité manquante.

## Sécurité

### Secrets

Une recherche par motifs usuels n’a trouvé aucun jeton, mot de passe, clé privée ou secret évident dans le checkout. Cette vérification ne remplace pas un scanner d’historique ni GitHub Secret Scanning.

L’API Secret Scanning n’a pas pu être vérifiée avec la portée du jeton disponible. Ne pas conclure à l’absence de secret historique.

### Entrées

La validation IPv4/CIDR et du run ID est globalement stricte. Les noms de modules sélectionnés sont limités aux fichiers directs du dossier `modules/`.

Points à renforcer :

- chemins de scripts de maintenance ;
- tailles des fichiers et sorties ;
- historique corrompu ;
- écoute API ;
- données rendues dans le DOM.

### Cadre éthique

Le blocage public par défaut et les avertissements sont de bons garde-fous. Ils doivent être complétés par :

- confirmation du périmètre dans les rapports ;
- suppression/anonymisation des données avant partage ;
- documentation des privilèges ;
- politique de divulgation responsable ;
- distinction visible entre découverte, énumération et tests plus intrusifs.

## Performance et fiabilité

- le runner applique un timeout par module ;
- l’API n’applique aucun timeout à ses sous-processus ;
- le snapshot lance quatre commandes en série ;
- chaque commande JSON crée plusieurs processus `jq` et fichiers temporaires ;
- aucune pagination ne limite l’historique ;
- aucune annulation côté Web ;
- aucune barre de progression pour les opérations réelles ;
- les résultats partiels sont mal représentés.

Sous Windows Git Bash, le snapshot a dépassé le délai de 5 secondes du test. Ce résultat ne prouve pas une lenteur identique sous Kali, mais confirme l’absence de budget multiplateforme.

## Maintenabilité

Forces :

- découpage par responsabilité ;
- scripts courts dans l’ensemble ;
- documentation technique abondante ;
- formats JSON nommés et versionnés.

Faiblesses :

- versions dispersées ;
- duplications de catalogues ;
- nombreuses versions historiques et scripts de patch ;
- absence de convention de fixture ;
- absence de test intégral du runner ;
- métadonnées modules non exposées complètement ;
- workflow test écrit étape par étape, propice aux oublis.

## Recommandations ordonnées

1. Traiter les données d’audit exposées et le FIFO.
2. Rendre les résultats fiables : erreurs, partial, skip, interruptions.
3. Rendre l’historique et l’API robustes.
4. Ajouter les tests moteur et corriger la couverture CI.
5. Stabiliser installation, versions, licence et releases.
6. Clarifier le catalogue des modules.
7. Mettre en œuvre la roadmap UX sans activer d’exécution Web.
8. Valider sur Kali réel et avec utilisateurs autorisés.
9. Étudier la portabilité à partir d’une interface moteur documentée.

## Conclusion

Audit Suite est une base expérimentale prometteuse, mais la CI verte ne reflète pas encore la fiabilité d’un audit réel. La priorité n’est pas d’ajouter des scanners ou une exécution Web : elle est de sécuriser les données, supprimer les blocages, rendre chaque état fidèle et établir un contrat d’installation et de test reproductible.
